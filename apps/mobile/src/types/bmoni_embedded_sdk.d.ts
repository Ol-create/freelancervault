declare module 'bmoni_embedded_sdk' {
  export interface InitializeOptions {
    pinLength?: number;
    requirePin?: boolean;
  }

  export class BmoniEmbeddedSdk {
    static initialize(options?: InitializeOptions): void;
    static hasWallet(): Promise<boolean>;
    static walletAddress(): Promise<string | null>;
    static initWallet(): Promise<string>;
    static hasPin(): Promise<boolean>;
    static setPin(pin: string): Promise<void>;
    static signMessage(message: string, pin?: string): Promise<string>;
  }

  export default BmoniEmbeddedSdk;
}
