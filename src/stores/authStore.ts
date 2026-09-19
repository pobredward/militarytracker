import { create } from 'zustand';
import { User } from '../types';

interface AuthState {
  user: User | null;
  /** onAuthStateChanged 첫 응답 + 프로필/플랜 복원까지 끝났는지 */
  isInitialized: boolean;
  setUser: (user: User | null) => void;
  patchUser: (patch: Partial<User>) => void;
  setInitialized: (initialized: boolean) => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  isInitialized: false,
  setUser: (user) => set({ user }),
  patchUser: (patch) => set((s) => (s.user ? { user: { ...s.user, ...patch } } : {})),
  setInitialized: (isInitialized) => set({ isInitialized }),
}));
