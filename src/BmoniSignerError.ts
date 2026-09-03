export type BmoniSignerErrorCode =
  | 'NOT_INITIALIZED'
  | 'WALLET_NOT_FOUND'
  | 'WALLET_ALREADY_EXISTS'
  | 'PIN_REQUIRED'
  | 'PIN_NOT_SET'
  | 'PIN_ALREADY_SET'
  | 'INVALID_PIN'
  | 'INVALID_PIN_LENGTH'
  | 'INVALID_HASH'
  | 'SECURE_HARDWARE_UNAVAILABLE'
  | 'KEYSTORE_ERROR'
  | 'UNKNOWN';

/**
 * Mirrors the Flutter SDK's BmoniSignerException codes 1:1 so the same
 * server-side/error-handling logic can key off `code` on either platform.
 */
export class BmoniSignerError extends Error {
  readonly code: BmoniSignerErrorCode;
  readonly nativeMessage?: string;

  constructor(code: BmoniSignerErrorCode, message: string, nativeMessage?: string) {
    super(message);
    this.name = 'BmoniSignerError';
    this.code = code;
    this.nativeMessage = nativeMessage;
    Object.setPrototypeOf(this, BmoniSignerError.prototype);
  }

  static fromNativeError(error: unknown): BmoniSignerError {
    if (error instanceof BmoniSignerError) return error;

    const anyErr = error as { code?: string; message?: string; userInfo?: Record<string, unknown> };
    const code = (anyErr?.code as BmoniSignerErrorCode) ?? 'UNKNOWN';
    const message = anyErr?.message ?? 'An unknown BmoniEmbeddedSdk error occurred';
    return new BmoniSignerError(code, message, anyErr?.message);
  }
}
