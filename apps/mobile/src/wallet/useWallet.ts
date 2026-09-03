import {useCallback, useState} from 'react';
import BmoniEmbeddedSdk from 'bmoni_embedded_sdk';

function errorMessage(error: unknown, fallback: string): string {
  return error instanceof Error ? error.message : fallback;
}

export function useWallet() {
  const [address, setAddress] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const checkWalletStatus = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      if (await BmoniEmbeddedSdk.hasWallet()) {
        setAddress(await BmoniEmbeddedSdk.walletAddress());
      } else {
        setAddress(null);
      }
    } catch (caught: unknown) {
      setError(errorMessage(caught, 'Wallet check failed'));
    } finally {
      setLoading(false);
    }
  }, []);

  const createWallet = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const walletAddress = await BmoniEmbeddedSdk.initWallet();
      setAddress(walletAddress);
      return walletAddress;
    } catch (caught: unknown) {
      setError(errorMessage(caught, 'Failed to initialize wallet'));
      throw caught;
    } finally {
      setLoading(false);
    }
  }, []);

  const setPin = useCallback(async (pin: string) => {
    await BmoniEmbeddedSdk.setPin(pin);
  }, []);

  return {
    address,
    loading,
    error,
    checkWalletStatus,
    createWallet,
    setPin,
  };
}
