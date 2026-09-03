import Foundation

/// Secure-storage-backed implementation, called from the ObjC++ TurboModule
/// shim in BmoniEmbeddedSdk.mm. Mirrors
/// android/.../BmoniEmbeddedSdkModule.kt method-for-method (including error
/// codes) so JS callers see identical behavior on both platforms.
@objc(BmoniEmbeddedSdkImpl)
public class BmoniEmbeddedSdkImpl: NSObject {
  private let store = SecureStore()

  @objc public func initialize(pinLength: Double, requirePin: Bool) {
    store.savePinPolicy(pinLength: Int(pinLength), requirePin: requirePin)
  }

  @objc public func initWallet(resolve: @escaping (Any?) -> Void, reject: @escaping (String, String) -> Void) {
    if store.hasWallet() {
      reject("WALLET_ALREADY_EXISTS", "A wallet already exists on this device")
      return
    }
    do {
      var keyPair = try EthSigner.generateKeyPair()
      defer { zero(&keyPair.privateKey) }
      store.saveWallet(privateKey: keyPair.privateKey, address: keyPair.address)
      resolve(keyPair.address)
    } catch {
      reject("KEYSTORE_ERROR", error.localizedDescription)
    }
  }

  @objc public func walletAddress(resolve: @escaping (Any?) -> Void, reject: @escaping (String, String) -> Void) {
    resolve(store.getAddress())
  }

  @objc public func hasWallet(resolve: @escaping (Any?) -> Void, reject: @escaping (String, String) -> Void) {
    resolve(store.hasWallet())
  }

  @objc public func deleteWallet(pin: String?, resolve: @escaping (Any?) -> Void, reject: @escaping (String, String) -> Void) {
    guard store.hasWallet() else {
      reject("WALLET_NOT_FOUND", "No wallet exists on this device")
      return
    }
    if let pinError = checkPin(pin) {
      reject(pinError.code, pinError.message)
      return
    }
    store.clearWallet()
    store.clearPin()
    resolve(nil)
  }

  @objc public func setPin(pin: String, resolve: @escaping (Any?) -> Void, reject: @escaping (String, String) -> Void) {
    guard pin.count == store.getPinLength() else {
      reject("INVALID_PIN_LENGTH", "PIN must be \(store.getPinLength()) digits")
      return
    }
    guard !store.hasPin() else {
      reject("PIN_ALREADY_SET", "A PIN is already set — use changePin instead")
      return
    }
    store.savePin(pin)
    resolve(nil)
  }

  @objc public func changePin(currentPin: String, newPin: String, resolve: @escaping (Any?) -> Void, reject: @escaping (String, String) -> Void) {
    guard store.hasPin() else {
      reject("PIN_NOT_SET", "No PIN is set on this device")
      return
    }
    guard store.matchesPin(currentPin) else {
      reject("INVALID_PIN", "Current PIN is incorrect")
      return
    }
    guard newPin.count == store.getPinLength() else {
      reject("INVALID_PIN_LENGTH", "PIN must be \(store.getPinLength()) digits")
      return
    }
    store.savePin(newPin)
    resolve(nil)
  }

  @objc public func removePin(currentPin: String, resolve: @escaping (Any?) -> Void, reject: @escaping (String, String) -> Void) {
    guard store.hasPin() else {
      reject("PIN_NOT_SET", "No PIN is set on this device")
      return
    }
    guard store.matchesPin(currentPin) else {
      reject("INVALID_PIN", "Current PIN is incorrect")
      return
    }
    store.clearPin()
    resolve(nil)
  }

  @objc public func matchPin(pin: String, resolve: @escaping (Any?) -> Void, reject: @escaping (String, String) -> Void) {
    guard store.hasPin() else {
      reject("PIN_NOT_SET", "No PIN is set on this device")
      return
    }
    resolve(store.matchesPin(pin))
  }

  @objc public func hasPin(resolve: @escaping (Any?) -> Void, reject: @escaping (String, String) -> Void) {
    resolve(store.hasPin())
  }

  @objc public func signMessage(message: String, pin: String?, resolve: @escaping (Any?) -> Void, reject: @escaping (String, String) -> Void) {
    if let pinError = checkPin(pin) {
      reject(pinError.code, pinError.message)
      return
    }
    guard var privateKey = store.getPrivateKey() else {
      reject("WALLET_NOT_FOUND", "No wallet exists on this device")
      return
    }
    defer { zero(&privateKey) }
    do {
      let digest = EthSigner.eip191Digest(Data(message.utf8))
      resolve(try EthSigner.signRecoverable(digest32: digest, privateKey: privateKey))
    } catch {
      reject("UNKNOWN", error.localizedDescription)
    }
  }

  @objc public func signTransactionHash(hashHex: String, pin: String?, resolve: @escaping (Any?) -> Void, reject: @escaping (String, String) -> Void) {
    guard let digest = Self.parse32ByteHex(hashHex) else {
      reject("INVALID_HASH", "hashHex must be a 0x-prefixed 32-byte hex string")
      return
    }
    if let pinError = checkPin(pin) {
      reject(pinError.code, pinError.message)
      return
    }
    guard var privateKey = store.getPrivateKey() else {
      reject("WALLET_NOT_FOUND", "No wallet exists on this device")
      return
    }
    defer { zero(&privateKey) }
    do {
      resolve(try EthSigner.signRecoverable(digest32: digest, privateKey: privateKey))
    } catch {
      reject("UNKNOWN", error.localizedDescription)
    }
  }

  // MARK: - Helpers

  private struct PinError { let code: String; let message: String }

  /// Nil means the PIN check passed (or isn't required); otherwise the (code, message) to reject with.
  private func checkPin(_ pin: String?) -> PinError? {
    guard store.isPinRequired() else { return nil }
    guard let pin else { return PinError(code: "PIN_REQUIRED", message: "A PIN is required for this operation") }
    guard store.hasPin() else { return PinError(code: "PIN_NOT_SET", message: "No PIN is set on this device") }
    guard store.matchesPin(pin) else { return PinError(code: "INVALID_PIN", message: "PIN is incorrect") }
    return nil
  }

  private static func parse32ByteHex(_ hex: String) -> Data? {
    guard hex.count == 66, hex.hasPrefix("0x") else { return nil }
    let clean = hex.dropFirst(2)
    var bytes = [UInt8]()
    bytes.reserveCapacity(32)
    var index = clean.startIndex
    while index < clean.endIndex {
      let next = clean.index(index, offsetBy: 2)
      guard let byte = UInt8(clean[index..<next], radix: 16) else { return nil }
      bytes.append(byte)
      index = next
    }
    return Data(bytes)
  }

  /// Best-effort zeroing of private key bytes once an operation using them completes.
  private func zero(_ data: inout Data) {
    data.withUnsafeMutableBytes { raw in
      guard let base = raw.baseAddress else { return }
      memset(base, 0, raw.count)
    }
  }
}
