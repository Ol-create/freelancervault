import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

/**
 * Codegen requires a flat, JSON-serializable spec: methods return
 * primitives/objects, never class instances. Errors cross the bridge as
 * native NSError/Exception and are re-hydrated into BmoniSignerError on
 * the JS side (see src/BmoniSignerError.ts).
 */
export interface Spec extends TurboModule {
  initialize(pinLength: number, requirePin: boolean): void;

  initWallet(): Promise<string>;
  walletAddress(): Promise<string | null>;
  hasWallet(): Promise<boolean>;
  deleteWallet(pin: string | null): Promise<void>;

  setPin(pin: string): Promise<void>;
  changePin(currentPin: string, newPin: string): Promise<void>;
  removePin(currentPin: string): Promise<void>;
  matchPin(pin: string): Promise<boolean>;
  hasPin(): Promise<boolean>;

  signMessage(message: string, pin: string | null): Promise<string>;
  signTransactionHash(hashHex: string, pin: string | null): Promise<string>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('BmoniEmbeddedSdk');
