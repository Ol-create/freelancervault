package com.bmoniembeddedsdk.crypto

import org.bouncycastle.asn1.sec.SECNamedCurves
import org.bouncycastle.asn1.x9.X9ECParameters
import org.bouncycastle.asn1.x9.X9IntegerConverter
import org.bouncycastle.crypto.digests.KeccakDigest
import org.bouncycastle.crypto.digests.SHA256Digest
import org.bouncycastle.crypto.generators.ECKeyPairGenerator
import org.bouncycastle.crypto.params.ECDomainParameters
import org.bouncycastle.crypto.params.ECKeyGenerationParameters
import org.bouncycastle.crypto.params.ECPrivateKeyParameters
import org.bouncycastle.crypto.params.ECPublicKeyParameters
import org.bouncycastle.crypto.signers.ECDSASigner
import org.bouncycastle.crypto.signers.HMacDSAKCalculator
import org.bouncycastle.math.ec.ECPoint
import java.math.BigInteger
import java.security.SecureRandom

/**
 * secp256k1 key generation, Keccak-256 hashing, and recoverable ECDSA
 * signing (EIP-2 low-s, v in {27,28}) — the crypto primitives underneath
 * signMessage/signTransactionHash.
 *
 * Deliberately bypasses java.security/AndroidKeyStore for the EC math:
 * AndroidOpenSSL's JCE provider does not expose the secp256k1 named curve
 * (only NIST curves), so Ethereum-compatible keys can't be generated or
 * signed with the standard KeyPairGenerator("EC") + Keystore combination.
 * Bouncy Castle's low-level API works directly with secp256k1's domain
 * parameters instead. The private key is still only ever persisted through
 * SecureStore's Keystore-wrapped encryption — this object only ever touches
 * key material transiently in memory.
 */
object EthSigner {
  private val CURVE: X9ECParameters = SECNamedCurves.getByName("secp256k1")
  private val DOMAIN = ECDomainParameters(CURVE.curve, CURVE.g, CURVE.n, CURVE.h)
  private val HALF_CURVE_ORDER: BigInteger = CURVE.n.shiftRight(1)

  class KeyPair(val privateKey: ByteArray, val address: String)

  fun generateKeyPair(): KeyPair {
    val generator = ECKeyPairGenerator()
    generator.init(ECKeyGenerationParameters(DOMAIN, SecureRandom()))
    val keyPair = generator.generateKeyPair()
    val priv = keyPair.private as ECPrivateKeyParameters
    val pub = keyPair.public as ECPublicKeyParameters

    val privBytes = bigIntegerTo32Bytes(priv.d)
    val address = addressFromPublicPoint(pub.q)
    return KeyPair(privBytes, address)
  }

  fun addressFromPrivateKey(privateKey: ByteArray): String {
    val d = BigInteger(1, privateKey)
    val point = DOMAIN.g.multiply(d).normalize()
    return addressFromPublicPoint(point)
  }

  private fun addressFromPublicPoint(point: ECPoint): String {
    val uncompressed = point.getEncoded(false) // 0x04 || X(32) || Y(32)
    val pubNoPrefix = uncompressed.copyOfRange(1, uncompressed.size)
    val hash = keccak256(pubNoPrefix)
    val addressBytes = hash.copyOfRange(12, 32) // last 20 bytes
    return "0x" + addressBytes.joinToString("") { "%02x".format(it) }
  }

  fun keccak256(input: ByteArray): ByteArray {
    val digest = KeccakDigest(256)
    digest.update(input, 0, input.size)
    val out = ByteArray(32)
    digest.doFinal(out, 0)
    return out
  }

  /** EIP-191 personal_sign digest: keccak256("\x19Ethereum Signed Message:\n" + len + message). */
  fun eip191Digest(message: ByteArray): ByteArray {
    val prefix = "Ethereum Signed Message:\n${message.size}".toByteArray(Charsets.US_ASCII)
    return keccak256(prefix + message)
  }

  /**
   * Recoverable ECDSA signature over a 32-byte digest: 0x-prefixed
   * r(32) || s(32) || v(1) hex, low-s normalized, v in {27,28}.
   */
  fun signRecoverable(digest32: ByteArray, privateKey: ByteArray): String {
    require(digest32.size == 32) { "digest must be 32 bytes" }

    val d = BigInteger(1, privateKey)
    val signer = ECDSASigner(HMacDSAKCalculator(SHA256Digest()))
    signer.init(true, ECPrivateKeyParameters(d, DOMAIN))
    val rawSig = signer.generateSignature(digest32)
    val r = rawSig[0]
    var s = rawSig[1]

    // EIP-2: canonical (low-s) signatures only.
    if (s > HALF_CURVE_ORDER) {
      s = CURVE.n.subtract(s)
    }

    val publicPoint = DOMAIN.g.multiply(d).normalize()
    val recId = findRecoveryId(digest32, r, s, publicPoint)
      ?: throw IllegalStateException("Unable to derive a valid recovery id for this signature")

    val sig = ByteArray(65)
    System.arraycopy(bigIntegerTo32Bytes(r), 0, sig, 0, 32)
    System.arraycopy(bigIntegerTo32Bytes(s), 0, sig, 32, 32)
    sig[64] = (recId + 27).toByte()

    return "0x" + sig.joinToString("") { "%02x".format(it) }
  }

  private fun findRecoveryId(digest: ByteArray, r: BigInteger, s: BigInteger, expectedPoint: ECPoint): Int? {
    for (recId in 0..1) {
      val recovered = recoverPublicKeyPoint(digest, r, s, recId) ?: continue
      if (recovered == expectedPoint) return recId
    }
    return null
  }

  /** Standard ECDSA public-key recovery (SEC 1 §4.1.6), restricted to recId in {0,1}. */
  private fun recoverPublicKeyPoint(digest: ByteArray, r: BigInteger, s: BigInteger, recId: Int): ECPoint? {
    val n = CURVE.n
    val i = BigInteger.valueOf(recId.toLong() / 2)
    val x = r.add(i.multiply(n))
    if (x >= CURVE.curve.field.characteristic) return null

    val rPoint = decompressKey(x, (recId and 1) == 1) ?: return null
    if (!rPoint.multiply(n).isInfinity) return null

    val e = BigInteger(1, digest)
    val eInv = BigInteger.ZERO.subtract(e).mod(n)
    val rInv = r.modInverse(n)
    val srInv = rInv.multiply(s).mod(n)
    val eInvrInv = rInv.multiply(eInv).mod(n)

    return CURVE.g.multiply(eInvrInv).add(rPoint.multiply(srInv)).normalize()
  }

  private fun decompressKey(xBN: BigInteger, yBit: Boolean): ECPoint? {
    val x9 = X9IntegerConverter()
    val compEnc = x9.integerToBytes(xBN, 1 + x9.getByteLength(CURVE.curve))
    compEnc[0] = if (yBit) 0x03 else 0x02
    return try {
      CURVE.curve.decodePoint(compEnc)
    } catch (e: Exception) {
      null
    }
  }

  private fun bigIntegerTo32Bytes(value: BigInteger): ByteArray {
    val bytes = value.toByteArray()
    val out = ByteArray(32)
    return when {
      bytes.size == 32 -> bytes
      bytes.size > 32 -> {
        System.arraycopy(bytes, bytes.size - 32, out, 0, 32)
        out
      }
      else -> {
        System.arraycopy(bytes, 0, out, 32 - bytes.size, bytes.size)
        out
      }
    }
  }
}
