import Foundation
import Security
import CryptoSwift

/// All wallet and PIN state lives in the iOS Keychain under
/// `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — items encrypted at rest
/// with a key tied to the device's hardware (Secure Enclave-anchored) UID,
/// never synced to iCloud Keychain or any other device. This is the
/// "platform-managed wrapping key" referenced in the SDK README; the raw
/// private key bytes only ever exist in memory transiently
/// (see BmoniEmbeddedSdk.mm / BmoniEmbeddedSdkImpl.swift).
///
/// True Secure Enclave key *generation* isn't an option here — the Secure
/// Enclave only supports P-256, not the secp256k1 curve Ethereum uses (the
/// same limitation Android's Keystore has, see SecureStore.kt) — so, as on
/// Android, the wrapping happens one layer up: at the storage layer, not
/// inside the key-generation call itself.
final class SecureStore {
  private let service = "com.bmoniembeddedsdk.securestore"
  private static let pbkdf2Iterations = 210_000 // OWASP-recommended minimum for PBKDF2-HMAC-SHA256 as of 2023.

  private enum Key: String {
    case privateKey = "wallet_private_key"
    case address = "wallet_address"
    case pinSalt = "pin_salt"
    case pinHash = "pin_hash"
    case pinLength = "pin_length"
    case requirePin = "require_pin"
  }

  // MARK: - Wallet

  func hasWallet() -> Bool { read(.privateKey) != nil }

  func getPrivateKey() -> Data? { read(.privateKey) }

  func saveWallet(privateKey: Data, address: String) {
    write(.privateKey, privateKey)
    write(.address, Data(address.utf8))
  }

  func getAddress() -> String? {
    read(.address).flatMap { String(data: $0, encoding: .utf8) }
  }

  func clearWallet() {
    delete(.privateKey)
    delete(.address)
  }

  // MARK: - PIN policy

  func savePinPolicy(pinLength: Int, requirePin: Bool) {
    write(.pinLength, Data(String(pinLength).utf8))
    write(.requirePin, Data(String(requirePin).utf8))
  }

  func getPinLength() -> Int {
    read(.pinLength).flatMap { Int(String(data: $0, encoding: .utf8) ?? "") } ?? 6
  }

  func isPinRequired() -> Bool {
    read(.requirePin).flatMap { Bool(String(data: $0, encoding: .utf8) ?? "") } ?? true
  }

  // MARK: - PIN

  func hasPin() -> Bool { read(.pinHash) != nil }

  func savePin(_ pin: String) {
    var salt = [UInt8](repeating: 0, count: 16)
    _ = SecRandomCopyBytes(kSecRandomDefault, salt.count, &salt)
    let hash = Self.pbkdf2(pin: pin, salt: salt)
    write(.pinSalt, Data(salt))
    write(.pinHash, Data(hash))
  }

  func clearPin() {
    delete(.pinSalt)
    delete(.pinHash)
  }

  func matchesPin(_ pin: String) -> Bool {
    guard let salt = read(.pinSalt), let expected = read(.pinHash) else { return false }
    let actual = Data(Self.pbkdf2(pin: pin, salt: Array(salt)))
    return Self.constantTimeEquals(expected, actual)
  }

  private static func pbkdf2(pin: String, salt: [UInt8]) -> [UInt8] {
    // Both platforms use the same primitive (PBKDF2-HMAC-SHA256, 210k
    // iterations, 32-byte output) so a digest computed on one platform
    // is never expected to migrate to the other — devices don't share
    // wallets — but keeping the parameters identical avoids drift.
    (try? PKCS5.PBKDF2(
      password: Array(pin.utf8),
      salt: salt,
      iterations: pbkdf2Iterations,
      keyLength: 32,
      variant: .sha2(.sha256)
    ).calculate()) ?? []
  }

  private static func constantTimeEquals(_ a: Data, _ b: Data) -> Bool {
    guard a.count == b.count else { return false }
    var diff: UInt8 = 0
    for i in 0..<a.count {
      diff |= a[a.startIndex + i] ^ b[b.startIndex + i]
    }
    return diff == 0
  }

  // MARK: - Keychain primitives

  private func read(_ key: Key) -> Data? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key.rawValue,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess else { return nil }
    return result as? Data
  }

  private func write(_ key: Key, _ value: Data) {
    let base: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key.rawValue,
    ]
    if read(key) != nil {
      SecItemUpdate(base as CFDictionary, [kSecValueData as String: value] as CFDictionary)
    } else {
      var attributes = base
      attributes[kSecValueData as String] = value
      attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
      SecItemAdd(attributes as CFDictionary, nil)
    }
  }

  private func delete(_ key: Key) {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key.rawValue,
    ]
    SecItemDelete(query as CFDictionary)
  }
}
