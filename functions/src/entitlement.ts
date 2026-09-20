/**
 * 구독 권한 — 서버 판정.
 *
 * 앱의 잠금 UI 는 우회할 수 있으므로 유료 기능의 실제 차단은 여기서 한다.
 * users/{uid}.sub 는 이 파일(Admin SDK)만 쓴다. 보안 규칙이 클라이언트의 쓰기를 막는다.
 *
 * 판정 규칙 사본: src/utils/subscription.ts (isProSub). 고칠 때 둘 다 고칠 것.
 * Feature 키 사본: src/config/entitlements.ts
 */
import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

if (!getApps().length) initializeApp();
export const db = getFirestore();

export type Feature = 'ai_plan' | 'ai_coach' | 'ai_diet' | 'routine_reco';

export const FEATURE_LABEL: Record<Feature, string> = {
  ai_plan: 'AI 개인화 플랜',
  ai_coach: 'AI 코치',
  ai_diet: 'AI 식단',
  routine_reco: '루틴 추천',
};

export type PlanTier = 'free' | 'pro';
export type SubStatus = 'none' | 'trial' | 'active' | 'grace' | 'expired' | 'canceled';
export type SubSource = 'none' | 'ios' | 'android' | 'promo' | 'admin';

export interface Subscription {
  tier: PlanTier;
  status: SubStatus;
  expiresAt: string | null;
  source: SubSource;
  productId: string | null;
  trialUsed: boolean;
  updatedAt: string;
}

export const FREE_SUB: Subscription = {
  tier: 'free',
  status: 'none',
  expiresAt: null,
  source: 'none',
  productId: null,
  trialUsed: false,
  updatedAt: '',
};

export function normalizeSub(raw: unknown): Subscription {
  const d = (raw ?? {}) as Partial<Subscription>;
  const status: SubStatus =
    d.status === 'trial' || d.status === 'active' || d.status === 'grace' ||
    d.status === 'expired' || d.status === 'canceled'
      ? d.status
      : 'none';
  const source: SubSource =
    d.source === 'ios' || d.source === 'android' || d.source === 'promo' || d.source === 'admin'
      ? d.source
      : 'none';
  return {
    tier: d.tier === 'pro' ? 'pro' : 'free',
    status,
    expiresAt: typeof d.expiresAt === 'string' ? d.expiresAt : null,
    source,
    productId: typeof d.productId === 'string' ? d.productId : null,
    trialUsed: d.trialUsed === true,
    updatedAt: typeof d.updatedAt === 'string' ? d.updatedAt : '',
  };
}

export function isProSub(sub: Subscription | null | undefined, now = Date.now()): boolean {
  if (!sub || sub.tier !== 'pro') return false;
  if (sub.status === 'none' || sub.status === 'expired') return false;
  if (!sub.expiresAt) return true;
  const t = Date.parse(sub.expiresAt);
  return Number.isFinite(t) && t > now;
}

export interface Account {
  sub: Subscription;
  isAdmin: boolean;
  pro: boolean;
}

export async function loadAccount(uid: string): Promise<Account> {
  const snap = await db.collection('users').doc(uid).get();
  const data = snap.exists ? snap.data() : undefined;
  const sub = normalizeSub(data?.sub);
  const isAdmin = data?.role === 'admin';
  return { sub, isAdmin, pro: isAdmin || isProSub(sub) };
}

/**
 * 유료 기능 진입 관문. 권한이 없으면 permission-denied 로 끊는다.
 * 앱은 이 코드를 보고 구독 화면을 연다.
 */
export async function requirePro(uid: string, feature: Feature): Promise<Account> {
  const acc = await loadAccount(uid);
  if (acc.pro) return acc;
  throw new HttpsError(
    'permission-denied',
    `${FEATURE_LABEL[feature]}은 구독 기능입니다.`,
    { reason: 'subscription_required', feature }
  );
}

/** users/{uid}.sub 를 통째로 교체하고 저장된 값을 돌려준다 */
export async function writeSub(uid: string, next: Omit<Subscription, 'updatedAt'>): Promise<Subscription> {
  const sub: Subscription = { ...next, updatedAt: new Date().toISOString() };
  await db.collection('users').doc(uid).set({ sub }, { merge: true });
  return sub;
}

/** 감사 로그 — 누가 언제 무슨 근거로 PRO 가 됐는지 남긴다 */
export async function logGrant(uid: string, kind: string, detail: Record<string, unknown>): Promise<void> {
  await db.collection('subEvents').add({
    uid, kind, detail, at: FieldValue.serverTimestamp(),
  });
}

export const addDays = (days: number, from = Date.now()): string =>
  new Date(from + days * 86_400_000).toISOString();
