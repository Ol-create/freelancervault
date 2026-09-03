package com.bmoniembeddedsdk

import android.content.Context
import android.content.SharedPreferences
import android.util.Base64
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec

/**
 * All wallet and PIN state lives in one EncryptedSharedPreferences file,
 * whose keys and values are encrypted with an Android Keystore-backed
 * AES-256-GCM master key — so a plaintext private key or PIN digest never
 * touches disk. This is the "platform-managed wrapping key" referenced in
 * the SDK README; the raw private key bytes only ever exist in memory
 * transiently (see BmoniEmbeddedSdkModule).
 */
class SecureStore(context: Context) {
  private val prefs: SharedPreferences

  init {
    val masterKey = MasterKey.Builder(context)
      .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
      .build()
    prefs = EncryptedSharedPreferences.create(
      context,
      PREFS_NAME,
      masterKey,
      EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
      EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )
  }

  fun hasWallet(): Boolean = prefs.contains(KEY_PRIVATE_KEY)

  fun getPrivateKey(): ByteArray? =
    prefs.getString(KEY_PRIVATE_KEY, null)?.let { Base64.decode(it, Base64.NO_WRAP) }

  fun saveWallet(privateKey: ByteArray, address: String) {
    prefs.edit()
      .putString(KEY_PRIVATE_KEY, Base64.encodeToString(privateKey, Base64.NO_WRAP))
      .putString(KEY_ADDRESS, address)
      .apply()
  }

  fun getAddress(): String? = prefs.getString(KEY_ADDRESS, null)

  fun clearWallet() {
    prefs.edit().remove(KEY_PRIVATE_KEY).remove(KEY_ADDRESS).apply()
  }

  fun savePinPolicy(pinLength: Int, requirePin: Boolean) {
    prefs.edit()
      .putInt(KEY_PIN_LENGTH, pinLength)
      .putBoolean(KEY_REQUIRE_PIN, requirePin)
      .apply()
  }

  fun getPinLength(): Int = prefs.getInt(KEY_PIN_LENGTH, 6)
  fun isPinRequired(): Boolean = prefs.getBoolean(KEY_REQUIRE_PIN, true)
  fun hasPin(): Boolean = prefs.contains(KEY_PIN_HASH)

  fun savePin(pin: String) {
    val salt = ByteArray(16).also { SecureRandom().nextBytes(it) }
    val hash = pbkdf2(pin, salt)
    prefs.edit()
      .putString(KEY_PIN_SALT, Base64.encodeToString(salt, Base64.NO_WRAP))
      .putString(KEY_PIN_HASH, Base64.encodeToString(hash, Base64.NO_WRAP))
      .apply()
  }

  fun clearPin() {
    prefs.edit().remove(KEY_PIN_SALT).remove(KEY_PIN_HASH).apply()
  }

  fun matchesPin(pin: String): Boolean {
    val saltB64 = prefs.getString(KEY_PIN_SALT, null) ?: return false
    val hashB64 = prefs.getString(KEY_PIN_HASH, null) ?: return false
    val salt = Base64.decode(saltB64, Base64.NO_WRAP)
    val expected = Base64.decode(hashB64, Base64.NO_WRAP)
    val actual = pbkdf2(pin, salt)
    return MessageDigest.isEqual(expected, actual)
  }

  private fun pbkdf2(pin: String, salt: ByteArray): ByteArray {
    val spec = PBEKeySpec(pin.toCharArray(), salt, PBKDF2_ITERATIONS, 256)
    val factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
    return factory.generateSecret(spec).encoded
  }

  companion object {
    private const val PREFS_NAME = "bmoni_embedded_sdk_secure_prefs"
    private const val KEY_PRIVATE_KEY = "wallet_private_key"
    private const val KEY_ADDRESS = "wallet_address"
    private const val KEY_PIN_SALT = "pin_salt"
    private const val KEY_PIN_HASH = "pin_hash"
    private const val KEY_PIN_LENGTH = "pin_length"
    private const val KEY_REQUIRE_PIN = "require_pin"
    // OWASP-recommended minimum for PBKDF2-HMAC-SHA256 as of 2023.
    private const val PBKDF2_ITERATIONS = 210_000
  }
}
