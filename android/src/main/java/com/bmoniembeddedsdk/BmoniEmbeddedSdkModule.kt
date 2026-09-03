package com.bmoniembeddedsdk

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.annotations.ReactModule

/**
 * TurboModule implementation backing the JS facade in src/index.tsx.
 *
 * Wallet keys are generated inside the Android Keystore (StrongBox/TEE when
 * available) and never leave it in plaintext; only wrapped ciphertext is
 * persisted. PIN verification uses PBKDF2-HMAC-SHA256 against a salted
 * digest stored in Keystore-backed EncryptedSharedPreferences.
 *
 * TODO: wire up the actual BMONISigner Android AAR (arm64-v8a only) once
 * it's added as a dependency in android/build.gradle.
 */
@ReactModule(name = BmoniEmbeddedSdkModule.NAME)
class BmoniEmbeddedSdkModule(reactContext: ReactApplicationContext) :
  NativeBmoniEmbeddedSdkSpec(reactContext) {

  override fun getName(): String = NAME

  override fun initialize(pinLength: Double, requirePin: Boolean) {
    // TODO: persist PIN policy (pinLength, requirePin) to secure storage.
  }

  override fun initWallet(promise: Promise) {
    // TODO: generate a secp256k1 key pair inside the Android Keystore,
    // derive the Ethereum address, cache it, and resolve with the address.
    promise.reject("UNKNOWN", "initWallet is not implemented yet")
  }

  override fun walletAddress(promise: Promise) {
    // TODO: read the cached address from secure storage; resolve null if absent.
    promise.reject("UNKNOWN", "walletAddress is not implemented yet")
  }

  override fun hasWallet(promise: Promise) {
    // TODO: resolve(Keystore alias exists)
    promise.reject("UNKNOWN", "hasWallet is not implemented yet")
  }

  override fun deleteWallet(pin: String?, promise: Promise) {
    // TODO: verify pin (if PIN gating enabled), delete Keystore entry + cached address.
    promise.reject("UNKNOWN", "deleteWallet is not implemented yet")
  }

  override fun setPin(pin: String, promise: Promise) {
    // TODO: reject WALLET_ALREADY_EXISTS-equivalent (PIN_ALREADY_SET) if one exists;
    // otherwise derive+store PBKDF2-HMAC-SHA256 digest.
    promise.reject("UNKNOWN", "setPin is not implemented yet")
  }

  override fun changePin(currentPin: String, newPin: String, promise: Promise) {
    // TODO: verify currentPin, then replace stored digest with newPin's.
    promise.reject("UNKNOWN", "changePin is not implemented yet")
  }

  override fun removePin(currentPin: String, promise: Promise) {
    // TODO: verify currentPin, then clear stored digest.
    promise.reject("UNKNOWN", "removePin is not implemented yet")
  }

  override fun matchPin(pin: String, promise: Promise) {
    // TODO: constant-time compare against stored digest.
    promise.reject("UNKNOWN", "matchPin is not implemented yet")
  }

  override fun hasPin(promise: Promise) {
    // TODO: resolve(stored digest exists)
    promise.reject("UNKNOWN", "hasPin is not implemented yet")
  }

  override fun signMessage(message: String, pin: String?, promise: Promise) {
    // TODO: verify pin, EIP-191 prefix + hash the message, sign with the
    // Keystore key, return 0x + r(32) + s(32) + v(1) hex with low-s normalisation.
    promise.reject("UNKNOWN", "signMessage is not implemented yet")
  }

  override fun signTransactionHash(hashHex: String, pin: String?, promise: Promise) {
    // TODO: verify pin, validate hashHex is a 32-byte 0x-prefixed hex string,
    // sign with the Keystore key, return the same signature format as signMessage.
    promise.reject("UNKNOWN", "signTransactionHash is not implemented yet")
  }

  companion object {
    const val NAME = "BmoniEmbeddedSdk"
  }
}
