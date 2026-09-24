/**
 * AI 코치 사용 한도.
 *
 * 왜 필요한가: 코치 대화는 호출당 원가가 붙는데 구독료는 정액이다.
 * 무제한으로 두면 극소수 헤비 유저가 구독 매출을 전부 상쇄한다.
 * (월 구독 ₩4,900 → 수수료 제하면 약 ₩4,165. 코치 500회면 원가가 그걸 넘는다.)
 *
 * 한도는 반드시 서버에서 센다. 앱에 남은 횟수를 내려 주긴 하지만
 * 그건 표시용이고, 실제 차단은 여기서 한다.
 * users/{uid}.coachUsage 는 이 파일만 쓴다 — 보안 규칙이 클라이언트 쓰기를 막는다.
 */
import { HttpsError } from 'firebase-functions/v2/https';
import { db } from './entitlement';

/** 구독에 포함된 월 코치 대화 횟수 */
export const COACH_MONTHLY_LIMIT = 100;

export interface CoachQuota {
  used: number;
  limit: number;
  remaining: number;
  /** 관리자는 한도가 없다 */
  unlimited?: boolean;
}

/**
 * 한국 시간 기준 YYYY-MM.
 * UTC 로 계산하면 매월 1일 오전 9시에 초기화돼 유저가 이상하게 느낀다.
 */
function periodKey(now = new Date()): string {
  const kst = new Date(now.getTime() + 9 * 60 * 60 * 1000);
  return `${kst.getUTCFullYear()}-${String(kst.getUTCMonth() + 1).padStart(2, '0')}`;
}

interface StoredUsage {
  period?: string;
  count?: number;
}

/**
 * 호출 전에 확인한다. 한도를 넘었으면 resource-exhausted 로 끊는다.
 * 앱은 이 코드를 보고 충전 안내를 띄운다.
 */
export async function checkCoachQuota(uid: string, isAdmin: boolean): Promise<CoachQuota> {
  if (isAdmin) {
    return { used: 0, limit: COACH_MONTHLY_LIMIT, remaining: COACH_MONTHLY_LIMIT, unlimited: true };
  }

  const snap = await db.collection('users').doc(uid).get();
  const raw = (snap.data()?.coachUsage ?? {}) as StoredUsage;
  // 달이 바뀌면 저장된 값은 무시한다 (따로 초기화 작업이 필요 없다)
  const used = raw.period === periodKey() ? Math.max(0, Number(raw.count) || 0) : 0;

  if (used >= COACH_MONTHLY_LIMIT) {
    throw new HttpsError(
      'resource-exhausted',
      `이번 달 코치 대화 ${COACH_MONTHLY_LIMIT}회를 모두 사용했습니다.`,
      { reason: 'coach_quota_exceeded', limit: COACH_MONTHLY_LIMIT, used }
    );
  }
  return { used, limit: COACH_MONTHLY_LIMIT, remaining: COACH_MONTHLY_LIMIT - used };
}

/**
 * AI 응답이 실제로 온 뒤에만 차감한다 — 연결 실패로 횟수가 깎이면 안 된다.
 * 동시 호출 시 한두 번 덜 세질 수 있으나, 월 100회 한도에서는 무시할 수준이다.
 */
export async function recordCoachUse(uid: string, quota: CoachQuota): Promise<CoachQuota> {
  if (quota.unlimited) return quota;

  const count = quota.used + 1;
  await db.collection('users').doc(uid).set(
    { coachUsage: { period: periodKey(), count } },
    { merge: true }
  );
  return { used: count, limit: quota.limit, remaining: Math.max(0, quota.limit - count) };
}
