# bmoni_embedded_sdk — on-device Ethereum wallet provisioning and signing for React Native

`bmoni_embedded_sdk` is a React Native library that exposes the BMONISigner native SDKs for Android and iOS. It lets you provision a self-custodied secp256k1 wallet and produce EIP-191 / EIP-712 compatible signatures entirely within the device's secure hardware boundary.

It is a port of the Flutter plugin of the same name, and keeps the same API surface, PIN policy, and error codes. The npm package and the pub.dev package are both called `bmoni_embedded_sdk`.

**Security first.** Private keys are generated on-device, encrypted with a platform-managed wrapping key (Android Keystore on Android, Secure Enclave on iOS), and persisted only as ciphertext. Plaintext keys never leave the secure boundary and are zeroized in RAM after each operation.

## What it does

| Capability | API |
| --- | --- |
| Provision a wallet | `initWallet()` |
| Read the cached address | `walletAddress()`, `hasWallet()` |
| Delete the wallet | `deleteWallet(pin?)` |
| Set / change / remove PIN | `setPin`, `changePin`, `removePin`, `matchPin`, `hasPin` |
| Sign a personal message (EIP-191) | `signMessage(message, pin?)` |
| Sign a 32-byte hash | `signTransactionHash(hashHex, pin?)` |
| Configure PIN policy | `BmoniEmbeddedSdk.initialize({ pinLength, requirePin })` |

All signatures are returned as `0x`-prefixed 130-character hex strings in recoverable `r(32) ‖ s(32) ‖ v(1)` format with `v ∈ {27, 28}` and low-s normalisation (EIP-2 compliant), ready to be verified server-side with `ecrecover`.

## Platform support

| Android | iOS |
| --- | --- |
| ✅ Android Keystore (minSdk 24+) | ✅ Secure Enclave (iOS 15.1+) |

The library ships a TurboModule, so it requires the New Architecture — the default since React Native 0.76.

The BMONISigner Android AAR ships an `arm64-v8a` slice only. Build for `arm64-v8a` and run on an arm64 device or emulator, or the native library fails to load at runtime.

## Installation

```bash
npm install bmoni_embedded_sdk
# or
yarn add bmoni_embedded_sdk
```

### iOS

```bash
cd ios && pod install
```

### Android

Ensure your app builds with `minSdkVersion 24+` and restricts (or includes) the `arm64-v8a` ABI:

```gradle
android {
  defaultConfig {
    ndk {
      abiFilters "arm64-v8a"
    }
  }
}
```

## Usage

```ts
import { BmoniEmbeddedSdk, BmoniSignerError } from 'bmoni_embedded_sdk';

// Call once, before any other method.
BmoniEmbeddedSdk.initialize({ pinLength: 6, requirePin: true });

async function onboard() {
  if (!(await BmoniEmbeddedSdk.hasWallet())) {
    const address = await BmoniEmbeddedSdk.initWallet();
    console.log('Provisioned wallet:', address);
  }

  await BmoniEmbeddedSdk.setPin('123456');
}

async function sign(message: string) {
  try {
    const signature = await BmoniEmbeddedSdk.signMessage(message, '123456');
    return signature; // 0x-prefixed 130-char hex, ready for ecrecover
  } catch (error) {
    if (error instanceof BmoniSignerError) {
      console.error(error.code, error.message);
    }
    throw error;
  }
}
```

## Architecture

`BmoniEmbeddedSdk` is a static facade — you never instantiate it. Every method is static and can be called from anywhere after a single `initialize` call.

```
BmoniEmbeddedSdk (TypeScript facade)
        │
        ├── PIN layer (platform secure storage + PBKDF2-HMAC-SHA256)
        │
        └── TurboModule ──► BMONISigner (native)
                                 ├── Android Keystore
                                 └── iOS Secure Enclave
```

The TypeScript layer adds:

- **Address caching** — the `initWallet()` result is persisted in platform secure storage, so you can read it back after the app restarts without re-provisioning.
- **PIN gating** — when `requirePin` is `true`, the PIN digest is verified in TypeScript before forwarding to the native module.

Secure storage and the key derivation are provided by the native module itself (Android Keystore-wrapped preferences and the iOS Keychain), so the library adds no peer dependencies beyond `react-native`.

## Differences from the Flutter SDK

The API is the same, with the adjustments you would expect from moving to TypeScript:

| Flutter | React Native |
| --- | --- |
| `BmoniEmbeddedSdk.initialize(pinLength: 6, requirePin: true)` | `BmoniEmbeddedSdk.initialize({ pinLength: 6, requirePin: true })` |
| `signMessage(msg, pin: '123456')` | `signMessage(msg, '123456')` |
| `changePin(currentPin: a, newPin: b)` | `changePin({ currentPin: a, newPin: b })` |
| `BmoniSignerException` | `BmoniSignerError` (extends `Error`) |
| `on BmoniSignerException catch (e)` | `if (error instanceof BmoniSignerError)` |

## Project status

- **Android** — implemented. `EthSigner` (Bouncy Castle) generates secp256k1 keys and produces recoverable, low-s ECDSA signatures; `SecureStore` persists the private key and PIN digest only as Keystore-backed `EncryptedSharedPreferences` ciphertext.
- **iOS** — not yet implemented. `BmoniEmbeddedSdkImpl.swift` still stubs every method with `reject("UNKNOWN", "... not implemented yet")` pending a Secure Enclave-backed implementation.

## License

MIT
