/**
 * 구독 권한 판정 훅.
 *
 * 화면을 어떻게 보여 줄지만 정한다. 실제 차단은 서버가 하므로
 * 이 훅을 우회해도 AI 호출은 permission-denied 로 막힌다.
 */
import { useCallback, useMemo } from 'react';
import { useRouter } from 'expo-router';
import { useAuthStore } from '../stores/authStore';
import { isProSub, normalizeSub, daysLeft } from '../utils/subscription';
import { Feature, isProFeature } from '../config/entitlements';
import type { Subscription } from '../types';

export interface Entitlement {
  sub: Subscription;
  /** 지금 PRO 인가 (admin 계정은 항상 통과) */
  pro: boolean;
  /** 이 기능을 쓸 수 있는가 */
  can: (f: Feature) => boolean;
  /** 남은 구독 일수 — 무기한이면 null */
  left: number | null;
}

export function useEntitlement(): Entitlement {
  const user = useAuthStore((s) => s.user);
  const sub = useMemo(() => normalizeSub(user?.sub), [user?.sub]);
  const pro = user?.role === 'admin' || isProSub(sub);
  const can = useCallback((f: Feature) => pro || !isProFeature(f), [pro]);
  return { sub, pro, can, left: daysLeft(sub) };
}

/**
 * 유료 기능 실행 게이트.
 *   const gate = useProGate();
 *   onPress={() => gate('ai_diet', genDiet)}
 * 권한이 없으면 실행 대신 구독 화면으로 보낸다.
 */
export function useProGate(): (f: Feature, run: () => void) => void {
  const router = useRouter();
  const { can } = useEntitlement();
  return useCallback(
    (f: Feature, run: () => void) => {
      if (can(f)) {
        run();
        return;
      }
      router.push(`/subscribe?f=${f}`);
    },
    [can, router]
  );
}
