package com.bmoniembeddedsdk

import com.bmoniembeddedsdk.crypto.EthSigner
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.annotations.ReactModule
import java.util.Arrays

/**
 * TurboModule implementation backing the JS facade in src/index.tsx.
 *
 * Wallet keys are generated in-process with secp256k1 (see EthSigner) and
 * immediately persisted only as Keystore-wrapped ciphertext (see
 * SecureStore) — plaintext key bytes exist only transiently in local
 * variables here and are zeroed out with Arrays.fill as soon as an
 * operation using them completes.
 */
@ReactModule(name = BmoniEmbeddedSdkModule.NAME)
class BmoniEmbeddedSdkModule(reactContext: ReactApplicationContext) :
  NativeBmoniEmbeddedSdkSpec(reactContext) {

  private val store: SecureStore by lazy { SecureStore(reactApplicationContext) }

  override fun getName(): String = NAME

  override fun initialize(pinLength: Double, requirePin: Boolean) {
    runCatching { store.savePinPolicy(pinLength.toInt(), requirePin) }
  }

  override fun initWallet(promise: Promise) {
    try {
      if (store.hasWallet()) {
        promise.reject("WALLET_ALREADY_EXISTS", "A wallet already exists on this device")
        return
      }
      val keyPair = EthSigner.generateKeyPair()
      try {
        store.saveWallet(keyPair.privateKey, keyPair.address)
        promise.resolve(keyPair.address)
      } finally {
        Arrays.fill(keyPair.privateKey, 0)
      }
    } catch (e: Exception) {
      promise.reject("KEYSTORE_ERROR", e.message ?: "Failed to provision wallet", e)
    }
  }

  override fun walletAddress(promise: Promise) {
    try {
      promise.resolve(store.getAddress())
    } catch (e: Exception) {
      promise.reject("KEYSTORE_ERROR", e.message ?: "Failed to read wallet address", e)
    }
  }

  override fun hasWallet(promise: Promise) {
    try {
      promise.resolve(store.hasWallet())
    } catch (e: Exception) {
      promise.reject("KEYSTORE_ERROR", e.message ?: "Failed to check wallet state", e)
    }
  }

  override fun deleteWallet(pin: String?, promise: Promise) {
    try {
      if (!store.hasWallet()) {
        promise.reject("WALLET_NOT_FOUND", "No wallet exists on this device")
        return
      }
      val pinError = checkPin(pin)
      if (pinError != null) {
        promise.reject(pinError.first, pinError.second)
        return
      }
      store.clearWallet()
      store.clearPin()
      promise.resolve(null)
    } catch (e: Exception) {
      promise.reject("KEYSTORE_ERROR", e.message ?: "Failed to delete wallet", e)
    }
  }

  override fun setPin(pin: String, promise: Promise) {
    try {
      if (pin.length != store.getPinLength()) {
        promise.reject("INVALID_PIN_LENGTH", "PIN must be ${store.getPinLength()} digits")
        return
      }
      if (store.hasPin()) {
        promise.reject("PIN_ALREADY_SET", "A PIN is already set — use changePin instead")
        return
      }
      store.savePin(pin)
      promise.resolve(null)
    } catch (e: Exception) {
      promise.reject("KEYSTORE_ERROR", e.message ?: "Failed to set PIN", e)
    }
  }

  override fun changePin(currentPin: String, newPin: String, promise: Promise) {
    try {
      if (!store.hasPin()) {
        promise.reject("PIN_NOT_SET", "No PIN is set on this device")
        return
      }
      if (!store.matchesPin(currentPin)) {
        promise.reject("INVALID_PIN", "Current PIN is incorrect")
        return
      }
      if (newPin.length != store.getPinLength()) {
        promise.reject("INVALID_PIN_LENGTH", "PIN must be ${store.getPinLength()} digits")
        return
      }
      store.savePin(newPin)
      promise.resolve(null)
    } catch (e: Exception) {
      promise.reject("KEYSTORE_ERROR", e.message ?: "Failed to change PIN", e)
    }
  }

  override fun removePin(currentPin: String, promise: Promise) {
    try {
      if (!store.hasPin()) {
        promise.reject("PIN_NOT_SET", "No PIN is set on this device")
        return
      }
      if (!store.matchesPin(currentPin)) {
        promise.reject("INVALID_PIN", "Current PIN is incorrect")
        return
      }
      store.clearPin()
      promise.resolve(null)
    } catch (e: Exception) {
      promise.reject("KEYSTORE_ERROR", e.message ?: "Failed to remove PIN", e)
    }
  }

  override fun matchPin(pin: String, promise: Promise) {
    try {
      if (!store.hasPin()) {
        promise.reject("PIN_NOT_SET", "No PIN is set on this device")
        return
      }
      promise.resolve(store.matchesPin(pin))
    } catch (e: Exception) {
      promise.reject("KEYSTORE_ERROR", e.message ?: "Failed to verify PIN", e)
    }
  }

  override fun hasPin(promise: Promise) {
    try {
      promise.resolve(store.hasPin())
    } catch (e: Exception) {
      promise.reject("KEYSTORE_ERROR", e.message ?: "Failed to check PIN state", e)
    }
  }

  override fun signMessage(message: String, pin: String?, promise: Promise) {
    try {
      val pinError = checkPin(pin)
      if (pinError != null) {
        promise.reject(pinError.first, pinError.second)
        return
      }
      val privateKey = store.getPrivateKey()
      if (privateKey == null) {
        promise.reject("WALLET_NOT_FOUND", "No wallet exists on this device")
        return
      }
      try {
        val digest = EthSigner.eip191Digest(message.toByteArray(Charsets.UTF_8))
        promise.resolve(EthSigner.signRecoverable(digest, privateKey))
      } finally {
        Arrays.fill(privateKey, 0)
      }
    } catch (e: Exception) {
      promise.reject("UNKNOWN", e.message ?: "Failed to sign message", e)
    }
  }

  override fun signTransactionHash(hashHex: String, pin: String?, promise: Promise) {
    try {
      val digest = parse32ByteHex(hashHex)
      if (digest == null) {
        promise.reject("INVALID_HASH", "hashHex must be a 0x-prefixed 32-byte hex string")
        return
      }
      val pinError = checkPin(pin)
      if (pinError != null) {
        promise.reject(pinError.first, pinError.second)
        return
      }
      val privateKey = store.getPrivateKey()
      if (privateKey == null) {
        promise.reject("WALLET_NOT_FOUND", "No wallet exists on this device")
        return
      }
      try {
        promise.resolve(EthSigner.signRecoverable(digest, privateKey))
      } finally {
        Arrays.fill(privateKey, 0)
      }
    } catch (e: Exception) {
      promise.reject("UNKNOWN", e.message ?: "Failed to sign transaction hash", e)
    }
  }

  /** Null means the PIN check passed (or isn't required); otherwise (code, message) to reject with. */
  private fun checkPin(pin: String?): Pair<String, String>? {
    if (!store.isPinRequired()) return null
    if (pin == null) return "PIN_REQUIRED" to "A PIN is required for this operation"
    if (!store.hasPin()) return "PIN_NOT_SET" to "No PIN is set on this device"
    if (!store.matchesPin(pin)) return "INVALID_PIN" to "PIN is incorrect"
    return null
  }

  private fun parse32ByteHex(hex: String): ByteArray? {
    if (!hex.matches(Regex("^0x[0-9a-fA-F]{64}$"))) return null
    val clean = hex.substring(2)
    val bytes = ByteArray(32)
    for (i in 0 until 32) {
      bytes[i] = ((Character.digit(clean[i * 2], 16) shl 4) + Character.digit(clean[i * 2 + 1], 16)).toByte()
    }
    return bytes
  }

  companion object {
    const val NAME = "BmoniEmbeddedSdk"
  }
}
