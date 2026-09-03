import Foundation
import CryptoSwift
import secp256k1

/// secp256k1 key generation, Keccak-256 hashing, and recoverable ECDSA
/// signing (v in {27,28}) — the crypto primitives underneath
/// signMessage/signTransactionHash. Mirrors android/.../crypto/EthSigner.kt
/// so both platforms produce byte-identical signatures for the same key/digest.
///
/// libsecp256k1 (via the secp256k1.swift wrapper) already returns low-s
/// (canonical, EIP-2 compliant) signatures by construction, so — unlike a
/// hand-rolled ECDSA implementation — no separate low-s normalization step
/// is needed here.
enum EthSigner {

  struct KeyPair {
    // var, not let: callers zero this out via an inout reference once
    // they've persisted it (see BmoniEmbeddedSdkImpl.initWallet).
    var privateKey: Data
    let address: String
  }

  enum SigningError: Error {
    case invalidPrivateKey
    case signingFailed
  }

  static func generateKeyPair() throws -> KeyPair {
    let privateKey = try secp256k1.Signing.PrivateKey(format: .uncompressed)
    let address = try addressFromPublicKey(privateKey.publicKey)
    return KeyPair(privateKey: Data(privateKey.rawRepresentation), address: address)
  }

  static func addressFromPrivateKey(_ rawPrivateKey: Data) throws -> String {
    let privateKey = try secp256k1.Signing.PrivateKey(rawRepresentation: rawPrivateKey, format: .uncompressed)
    return try addressFromPublicKey(privateKey.publicKey)
  }

  private static func addressFromPublicKey(_ publicKey: secp256k1.Signing.PublicKey) throws -> String {
    let uncompressed = publicKey.rawRepresentation // 0x04 || X(32) || Y(32)
    let pubNoPrefix = uncompressed.dropFirst()
    let hash = keccak256(Data(pubNoPrefix))
    let addressBytes = hash.suffix(20)
    return "0x" + addressBytes.map { String(format: "%02x", $0) }.joined()
  }

  static func keccak256(_ data: Data) -> Data {
    Data(Array(data).sha3(.keccak256))
  }

  /// EIP-191 personal_sign digest: keccak256(0x19 || "Ethereum Signed Message:\n" || len || message).
  static func eip191Digest(_ message: Data) -> Data {
    var prefix = Data([0x19])
    prefix.append("Ethereum Signed Message:\n\(message.count)".data(using: .ascii)!)
    return keccak256(prefix + message)
  }

  /// Recoverable ECDSA signature over a 32-byte digest: 0x-prefixed
  /// r(32) || s(32) || v(1) hex, v in {27,28}.
  ///
  /// NOTE: written against secp256k1.swift's documented CryptoKit-mirroring
  /// API (`secp256k1.Recovery.PrivateKey.signature(for:)` ->
  /// `.compactRepresentation(format:)` giving `(signature: Data, recoveryId: Int32)`)
  /// without a live build to confirm the exact method/parameter names for
  /// the pinned 0.10.x version — verify this compiles against the actual
  /// installed pod on first build and adjust names if the API has shifted.
  static func signRecoverable(digest32: Data, privateKey rawPrivateKey: Data) throws -> String {
    guard digest32.count == 32 else { throw SigningError.invalidPrivateKey }

    let privateKey = try secp256k1.Recovery.PrivateKey(rawRepresentation: rawPrivateKey, format: .uncompressed)
    let recoverableSig = try privateKey.signature(for: Array(digest32))
    let compact = try recoverableSig.compactRepresentation(format: .uncompressed)

    guard compact.signature.count == 64 else { throw SigningError.signingFailed }

    var sig = Data(compact.signature) // r(32) || s(32)
    sig.append(UInt8(compact.recoveryId) + 27) // v

    return "0x" + sig.map { String(format: "%02x", $0) }.joined()
  }
}
