import NativeBmoniEmbeddedSdk from './NativeBmoniEmbeddedSdk';
import { BmoniSignerError } from './BmoniSignerError';

export { BmoniSignerError };
export type { BmoniSignerErrorCode } from './BmoniSignerError';

export interface InitializeOptions {
  /** Number of digits the PIN must contain. Defaults to 6. */
  pinLength?: number;
  /** Whether PIN-gated methods (deleteWallet, signMessage, ...) require a PIN. Defaults to true. */
  requirePin?: boolean;
}

export interface ChangePinOptions {
  currentPin: string;
  newPin: string;
}

let initialized = false;
let requirePin = true;

function assertInitialized(): void {
  if (!initialized) {
    throw new BmoniSignerError(
      'NOT_INITIALIZED',
      'BmoniEmbeddedSdk.initialize() must be called before using any other method'
    );
  }
}

function resolvePin(pin?: string): string | null {
  if (requirePin && !pin) {
    throw new BmoniSignerError('PIN_REQUIRED', 'A PIN is required for this operation');
  }
  return pin ?? null;
}

async function wrap<T>(fn: () => Promise<T>): Promise<T> {
  try {
    return await fn();
  } catch (error) {
    throw BmoniSignerError.fromNativeError(error);
  }
}

/**
 * Static facade over the BMONISigner native SDKs. Call `initialize` once
 * before using any other method; every method below is static.
 */
export class BmoniEmbeddedSdk {
  private constructor() {}

  static initialize(options: InitializeOptions = {}): void {
    const { pinLength = 6, requirePin: requirePinOption = true } = options;
    NativeBmoniEmbeddedSdk.initialize(pinLength, requirePinOption);
    requirePin = requirePinOption;
    initialized = true;
  }

  static initWallet(): Promise<string> {
    assertInitialized();
    return wrap(() => NativeBmoniEmbeddedSdk.initWallet());
  }

  static walletAddress(): Promise<string | null> {
    assertInitialized();
    return wrap(() => NativeBmoniEmbeddedSdk.walletAddress());
  }

  static hasWallet(): Promise<boolean> {
    assertInitialized();
    return wrap(() => NativeBmoniEmbeddedSdk.hasWallet());
  }

  static deleteWallet(pin?: string): Promise<void> {
    assertInitialized();
    const resolved = resolvePin(pin);
    return wrap(() => NativeBmoniEmbeddedSdk.deleteWallet(resolved));
  }

  static setPin(pin: string): Promise<void> {
    assertInitialized();
    return wrap(() => NativeBmoniEmbeddedSdk.setPin(pin));
  }

  static changePin(options: ChangePinOptions): Promise<void> {
    assertInitialized();
    return wrap(() => NativeBmoniEmbeddedSdk.changePin(options.currentPin, options.newPin));
  }

  static removePin(currentPin: string): Promise<void> {
    assertInitialized();
    return wrap(() => NativeBmoniEmbeddedSdk.removePin(currentPin));
  }

  static matchPin(pin: string): Promise<boolean> {
    assertInitialized();
    return wrap(() => NativeBmoniEmbeddedSdk.matchPin(pin));
  }

  static hasPin(): Promise<boolean> {
    assertInitialized();
    return wrap(() => NativeBmoniEmbeddedSdk.hasPin());
  }

  /** Returns a 0x-prefixed 130-char recoverable signature (r ‖ s ‖ v, low-s, v ∈ {27,28}). */
  static signMessage(message: string, pin?: string): Promise<string> {
    assertInitialized();
    const resolved = resolvePin(pin);
    return wrap(() => NativeBmoniEmbeddedSdk.signMessage(message, resolved));
  }

  /** `hashHex` must be a 0x-prefixed 32-byte hex string. Returns the same signature format as signMessage. */
  static signTransactionHash(hashHex: string, pin?: string): Promise<string> {
    assertInitialized();
    const resolved = resolvePin(pin);
    return wrap(() => NativeBmoniEmbeddedSdk.signTransactionHash(hashHex, resolved));
  }
}

export default BmoniEmbeddedSdk;
