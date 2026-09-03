import { create } from 'zustand';

interface AppState {
  isAuthenticated: boolean;
  userId: string | null;
  kycStatus: 'PENDING' | 'VERIFIED' | 'NOT_STARTED';
  setAuth: (userId: string) => void;
  clearAuth: () => void;
  setKycStatus: (status: 'PENDING' | 'VERIFIED' | 'NOT_STARTED') => void;
}

export const useAppStore = create<AppState>((set) => ({
  isAuthenticated: false,
  userId: null,
  kycStatus: 'NOT_STARTED',
  setAuth: (userId) => set({ isAuthenticated: true, userId }),
  clearAuth: () => set({ isAuthenticated: false, userId: null, kycStatus: 'NOT_STARTED' }),
  setKycStatus: (kycStatus) => set({ kycStatus }),
}));
