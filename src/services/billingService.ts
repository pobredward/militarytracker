/**
 * 구독 결제 어댑터.
 *
 * ── 지금 동작하는 것 ────────────────────────────────────────────────────
 *   startTrial()    무료 체험 시작 (서버가 계정당 1회만 허용)
 *   redeemPromo()   프로모션 코드 등록
 *   refreshSub()    서버가 보는 구독 상태를 다시 받아온다
 *
 * ── 스토어 결제를 붙일 자리 ─────────────────────────────────────────────
 *   purchase() / restore() 한 곳만 갈아 끼우면 된다.
 *   iOS·Android 의 디지털 구독은 반드시 인앱결제를 써야 하므로
 *   (Apple 3.1.1 / Google Play 결제 정책) 외부 결제 링크를 넣으면 심사에서 막힌다.
 *   RevenueCat 또는 expo-iap 을 붙인 뒤,
 *   구매 영수증을 subApplyReceipt 콜러블로 넘겨 서버가 검증·기록하게 한다.
 *   클라이언트가 users/{uid}.sub 를 직접 쓰는 길은 보안 규칙이 막아 두었다.
 */
import { Platform } from 'react-native';
import { httpsCallable, FunctionsError } from 'firebase/functions';
import { functions } from './firebase';
import { refreshIdToken } from './authService';
import type { Subscription } from '../types';
import { normalizeSub } from '../utils/subscription';
import { PRODUCTS, SubProduct } from '../config/entitlements';

export class BillingUnavailable extends Error {}
export class PromoError extends Error {}
/** 서버가 이메일 인증을 요구했다 — 화면은 "인증 메일 다시 보내기" 를 띄운다 */
export class EmailUnverified extends Error {}

/**
 * ⚠️ 결제 SDK(RevenueCat/expo-iap)를 붙이면 true 로 바꾼다.
 * false 인 동안 구독 화면은 가격표·구매·복원·코드 입력을 숨긴다 — 동작하지 않는
 * 결제 UI 와 앱 자체 코드로 유료 기능을 여는 UI 는 스토어 심사 거절 사유다(Apple 3.1.1/2.1).
 */
export const STORE_BILLING_READY = false;

const msg = (e: unknown, fallback: string): string => {
  const m = (e as FunctionsError)?.message;
  return typeof m === 'string' && m.trim() ? m : fallback;
};

/** 스토어에서 받아온 상품 목록. 아직 결제 SDK 가 없으면 기본값을 그대로 쓴다. */
export async function getOfferings(): Promise<SubProduct[]> {
  return [...PRODUCTS];
}

/** 서버가 보는 현재 구독 상태 */
export async function refreshSub(): Promise<Subscription | null> {
  try {
    const call = httpsCallable(functions, 'subStatus', { timeout: 15_000 });
    const res = await call({});
    return normalizeSub((res.data as { sub?: unknown })?.sub);
  } catch {
    // 함수 미배포·오프라인 — 기존 상태를 유지한다
    return null;
  }
}

/** 무료 체험 시작. 계정당 1회 + 이메일 인증, 서버에서 판정한다. */
export async function startTrial(): Promise<Subscription> {
  // 방금 인증을 마쳤어도 email_verified 클레임은 새 토큰에만 실린다
  await refreshIdToken();
  try {
    const call = httpsCallable(functions, 'subStartTrial', { timeout: 20_000 });
    const res = await call({});
    return normalizeSub((res.data as { sub?: unknown })?.sub);
  } catch (e) {
    const d = (e as FunctionsError)?.details as { reason?: string } | undefined;
    if (d?.reason === 'email_unverified') {
      throw new EmailUnverified(msg(e, '이메일 인증 후 무료 체험을 시작할 수 있습니다.'));
    }
    throw new PromoError(msg(e, '체험을 시작하지 못했습니다. 잠시 후 다시 시도해주세요.'));
  }
}

/** 프로모션 코드 등록 */
export async function redeemPromo(code: string): Promise<Subscription> {
  const clean = code.trim().toUpperCase();
  if (!clean) throw new PromoError('코드를 입력해주세요.');
  try {
    const call = httpsCallable(functions, 'subRedeemPromo', { timeout: 20_000 });
    const res = await call({ code: clean });
    return normalizeSub((res.data as { sub?: unknown })?.sub);
  } catch (e) {
    throw new PromoError(msg(e, '코드를 확인하지 못했습니다.'));
  }
}

/** 스토어 결제가 이 기기에서 가능한가 */
export function canPurchase(): boolean {
  // 웹에서는 인앱결제가 없다. 구독은 앱에서만.
  if (Platform.OS === 'web') return false;
  return STORE_BILLING_READY;
}

export async function purchase(_productId: string): Promise<Subscription> {
  if (Platform.OS === 'web') {
    throw new BillingUnavailable('구독은 앱에서만 결제할 수 있습니다. iOS·Android 앱에서 진행해주세요.');
  }
  throw new BillingUnavailable(
    '스토어 결제가 아직 연결되지 않았습니다. 지금은 무료 체험이나 코드로 이용할 수 있습니다.'
  );
  // 붙일 때:
  //   const result = await IAP.purchase(_productId);
  //   const call = httpsCallable(functions, 'subApplyReceipt');
  //   const res = await call({ platform: Platform.OS, receipt: result.transactionReceipt });
  //   return normalizeSub((res.data as { sub?: unknown })?.sub);
}

export async function restore(): Promise<Subscription | null> {
  if (!canPurchase()) {
    // 결제 SDK 가 없어도 서버 기록(코드·관리자 지급)은 되살릴 수 있다
    return refreshSub();
  }
  throw new BillingUnavailable('복원 기능이 아직 연결되지 않았습니다.');
}
