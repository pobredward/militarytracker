import { create } from 'zustand';
import { User } from '../types';

interface AuthState {
  user: User | null;
  /** onAuthStateChanged 첫 응답 + 프로필/플랜 복원까지 끝났는지 */
  isInitialized: boolean;
  /**
   * 로그인 직후 플랜·기록을 서버에서 받아오는 중.
   * 이 동안 홈·운동 탭은 "플랜 없음" 대신 로딩을 보여준다 — 빈 상태에서 루틴을 고르면 기존 플랜을 덮어쓴다.
   */
  hydrating: boolean;
  setUser: (user: User | null) => void;
  patchUser: (patch: Partial<User>) => void;
  setInitialized: (initialized: boolean) => void;
  setHydrating: (v: boolean) => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  isInitialized: false,
  hydrating: false,
  setUser: (user) => set({ user }),
  patchUser: (patch) => set((s) => (s.user ? { user: { ...s.user, ...patch } } : {})),
  setInitialized: (isInitialized) => set({ isInitialized }),
  setHydrating: (hydrating) => set({ hydrating }),
}));
