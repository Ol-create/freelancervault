import Foundation

/// Secure Enclave-backed implementation, called from the ObjC++ TurboModule
/// shim in BmoniEmbeddedSdk.mm. Kept in Swift because Security/Secure Enclave
/// key generation (kSecAttrTokenIDSecureEnclave) is far more ergonomic here
/// than in Objective-C++.
///
/// TODO: wire up the actual BMONISigner iOS SDK (Secure Enclave) once it's
/// added as a pod dependency in bmoni_embedded_sdk.podspec.
@objc(BmoniEmbeddedSdkImpl)
public class BmoniEmbeddedSdkImpl: NSObject {

  @objc public func initialize(pinLength: Double, requirePin: Bool) {
    // TODO: persist PIN policy (pinLength, requirePin) to the Keychain.
  }

  @objc public func initWallet(resolve: @escaping (String) -> Void, reject: @escaping (String, String) -> Void) {
    // TODO: generate a secp256k1 key pair inside the Secure Enclave,
    // derive the Ethereum address, cache it, and resolve with the address.
    reject("UNKNOWN", "initWallet is not implemented yet")
  }

  @objc public func walletAddress(resolve: @escaping (String?) -> Void, reject: @escaping (String, String) -> Void) {
    // TODO: read the cached address from the Keychain; resolve nil if absent.
    reject("UNKNOWN", "walletAddress is not implemented yet")
  }

  @objc public func hasWallet(resolve: @escaping (Bool) -> Void, reject: @escaping (String, String) -> Void) {
    reject("UNKNOWN", "hasWallet is not implemented yet")
  }

  @objc public func deleteWallet(pin: String?, resolve: @escaping () -> Void, reject: @escaping (String, String) -> Void) {
    // TODO: verify pin (if PIN gating enabled), delete Secure Enclave key + cached address.
    reject("UNKNOWN", "deleteWallet is not implemented yet")
  }

  @objc public func setPin(pin: String, resolve: @escaping () -> Void, reject: @escaping (String, String) -> Void) {
    reject("UNKNOWN", "setPin is not implemented yet")
  }

  @objc public func changePin(currentPin: String, newPin: String, resolve: @escaping () -> Void, reject: @escaping (String, String) -> Void) {
    reject("UNKNOWN", "changePin is not implemented yet")
  }

  @objc public func removePin(currentPin: String, resolve: @escaping () -> Void, reject: @escaping (String, String) -> Void) {
    reject("UNKNOWN", "removePin is not implemented yet")
  }

  @objc public func matchPin(pin: String, resolve: @escaping (Bool) -> Void, reject: @escaping (String, String) -> Void) {
    reject("UNKNOWN", "matchPin is not implemented yet")
  }

  @objc public func hasPin(resolve: @escaping (Bool) -> Void, reject: @escaping (String, String) -> Void) {
    reject("UNKNOWN", "hasPin is not implemented yet")
  }

  @objc public func signMessage(message: String, pin: String?, resolve: @escaping (String) -> Void, reject: @escaping (String, String) -> Void) {
    // TODO: verify pin, EIP-191 prefix + hash the message, sign with the
    // Secure Enclave key, return 0x + r(32) + s(32) + v(1) hex with low-s normalisation.
    reject("UNKNOWN", "signMessage is not implemented yet")
  }

  @objc public func signTransactionHash(hashHex: String, pin: String?, resolve: @escaping (String) -> Void, reject: @escaping (String, String) -> Void) {
    // TODO: verify pin, validate hashHex is a 32-byte 0x-prefixed hex string,
    // sign with the Secure Enclave key, return the same signature format as signMessage.
    reject("UNKNOWN", "signTransactionHash is not implemented yet")
  }
}
