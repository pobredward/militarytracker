/**
 * AI 기능은 전부 Cloud Functions(asia-northeast3) 프록시를 통해 호출한다.
 * 앱 번들에는 Anthropic API 키가 들어가지 않는다.
 * 함수가 아직 배포되지 않았거나 호출에 실패하면 로컬 폴백으로 조용히 전환된다.
 */
import { httpsCallable, FunctionsError } from 'firebase/functions';
import { functions } from './firebase';
import { DietPlan, Plan, UserProfile } from '../types';
import { buildLocalPlan, planFromAI } from '../utils/planner';
import { calcBodyStats, FOOD_LABEL, GOAL_LABEL } from '../utils/body';
import type { BodyStats } from '../types';
import { exFilter, PART_LABEL } from '../data/exercises';

export const FALLBACK_DIET: DietPlan = {
  meals: [
    { t: '아침', m: '그릭요거트 + 그래놀라 + 바나나', k: '약 450kcal · 단백질 25g 내외' },
    { t: '점심', m: '닭가슴살 샐러드 랩 + 삶은 달걀 2개', k: '약 550kcal · 단백질 45g 내외' },
    { t: '저녁', m: '잡곡밥 + 구운 생선/닭다리살 + 나물 반찬', k: '약 650kcal · 단백질 40g 내외' },
    { t: '간식', m: '프로틴 음료 1개 + 견과류 한 줌', k: '약 300kcal · 단백질 20g 내외' },
  ],
  tip: '연결에 실패해 기본 예시 식단을 표시합니다. 다시 시도하면 조건에 맞게 새로 구성합니다.',
  src: 'LOCAL',
};

export class AIUnavailable extends Error {}

/**
 * 서버가 구독을 요구했다. 화면 게이트를 우회했거나 대기 중에 구독이 끝난 경우.
 * 조용히 로컬 폴백으로 넘기지 않고 구독 안내를 띄우기 위해 따로 구분한다.
 */
export class SubscriptionRequired extends Error {
  readonly feature: string;
  constructor(message: string, feature: string) {
    super(message);
    this.feature = feature;
  }
}

function asSubRequired(e: unknown): SubscriptionRequired | null {
  const err = e as FunctionsError;
  if (err?.code !== 'functions/permission-denied') return null;
  const d = err.details as { reason?: string; feature?: string } | undefined;
  if (d?.reason !== 'subscription_required') return null;
  return new SubscriptionRequired(err.message || '구독이 필요합니다.', d.feature ?? '');
}

/** AI 사용 한도를 다 썼다 — 코치(월), 플랜·식단(일). kind 로 구분한다 */
export class QuotaExceeded extends Error {
  readonly limit: number;
  readonly kind: 'coach' | 'plan' | 'diet';
  constructor(message: string, limit: number, kind: 'coach' | 'plan' | 'diet') {
    super(message);
    this.limit = limit;
    this.kind = kind;
  }
}
/** 하위 호환 — 코치 화면이 이 이름으로 판별한다 */
export const CoachQuotaExceeded = QuotaExceeded;
export type CoachQuotaExceeded = QuotaExceeded;

function asQuotaExceeded(e: unknown): QuotaExceeded | null {
  const err = e as FunctionsError;
  if (err?.code !== 'functions/resource-exhausted') return null;
  const d = err.details as { reason?: string; limit?: number } | undefined;
  const kind = d?.reason === 'coach_quota_exceeded' ? 'coach'
    : d?.reason === 'plan_quota_exceeded' ? 'plan'
    : d?.reason === 'diet_quota_exceeded' ? 'diet' : null;
  if (!kind) return null;
  return new QuotaExceeded(err.message || 'AI 사용 한도를 모두 사용했습니다.', Number(d?.limit) || 0, kind);
}

/** 콜러블 대기 상한 — 서버는 55초에 끊는다. 기본 70초를 기다리게 두면 화면이 그만큼 잠긴다 */
const CALL_TIMEOUT_MS = 40_000;

function isUnavailable(e: unknown): boolean {
  const code = (e as FunctionsError)?.code ?? '';
  return (
    code === 'functions/not-found' ||
    code === 'functions/unavailable' ||
    code === 'functions/internal' ||
    code === 'functions/failed-precondition'
  );
}

/** AI 가 선택할 수 있는 종목 목록 (환경·난이도로 축소해 토큰 절약) */
function buildCatalog(p: UserProfile): string {
  return exFilter({ place: p.env, maxLevel: p.level })
    .map((e) => `${e.id}|${e.n}|${PART_LABEL[e.part]}|lv${e.lv}`)
    .join('\n');
}

// ─── 플랜 ──────────────────────────────────────────────────────────────────
export interface PlanResult {
  plan: Plan;
  /** AI 가 아니라 로컬 구성으로 대체됐는지 — 호출자가 사용자에게 알린다 */
  fallback: boolean;
  /** 폴백 사유(표시용) */
  reason?: string;
}

/**
 * AI 플랜. 실패하면 로컬 구성으로 대체하되 그 사실을 돌려준다 —
 * 온보딩·플랜 화면이 "AI 플랜" 이라고 잘못 안내하지 않도록.
 * 구독 없음(SubscriptionRequired)·한도 초과(QuotaExceeded)는 폴백하지 않고 던진다.
 */
export async function generatePlan(p: UserProfile): Promise<PlanResult> {
  try {
    const call = httpsCallable(functions, 'aiPlan', { timeout: CALL_TIMEOUT_MS });
    const res = await call({ profile: p, catalog: buildCatalog(p) });
    const plan = planFromAI(res.data, p);
    if (plan) return { plan, fallback: false };
    return { plan: buildLocalPlan(p), fallback: true, reason: 'AI 응답을 해석하지 못했습니다.' };
  } catch (e) {
    const need = asSubRequired(e);
    if (need) throw need;
    const over = asQuotaExceeded(e);
    if (over) throw over;
    if (!isUnavailable(e)) console.warn('[aiPlan]', e);
    return { plan: buildLocalPlan(p), fallback: true, reason: 'AI 연결에 실패했습니다.' };
  }
}

// ─── 식단 ──────────────────────────────────────────────────────────────────
export async function generateDiet(p: UserProfile, stats?: BodyStats): Promise<DietPlan> {
  // 호출 측에서 추세 체중이 반영된 stats 를 넘기면 그대로 쓴다
  const st = stats ?? calcBodyStats(p);
  if (!st) return FALLBACK_DIET;
  try {
    const call = httpsCallable(functions, 'aiDiet', { timeout: CALL_TIMEOUT_MS });
    const res = await call({
      bodyType: st.bodyType,
      goal: GOAL_LABEL[p.goal],
      kcal: st.kcal,
      protein: st.protein,
      carb: st.carb,
      fat: st.fat,
      foodEnv: FOOD_LABEL[p.food],
      allergy: p.allergy || '없음',
    });
    const j = normalizeDiet(res.data);
    if (j) return { ...j, src: 'AI', createdAt: new Date().toISOString() };
  } catch (e) {
    const need = asSubRequired(e);
    if (need) throw need;
    const over = asQuotaExceeded(e);
    if (over) throw over;
    if (!isUnavailable(e)) console.warn('[aiDiet]', e);
  }
  return FALLBACK_DIET;
}

/**
 * 서버 응답을 화면이 안전하게 렌더할 수 있는 형태로 정리한다.
 * diet 는 persist 되므로 여기서 걸러내지 않으면 잘못된 응답이 재시작마다 크래시를 일으킨다.
 */
function normalizeDiet(raw: unknown): DietPlan | null {
  const d = (raw ?? {}) as Partial<DietPlan>;
  const meals = (Array.isArray(d.meals) ? d.meals : [])
    .filter((m) => !!m && typeof m === 'object')
    .slice(0, 8)
    .map((m) => ({
      t: String((m as { t?: unknown }).t ?? '').slice(0, 20),
      m: String((m as { m?: unknown }).m ?? '').slice(0, 300),
      k: String((m as { k?: unknown }).k ?? '').slice(0, 60),
    }))
    .filter((m) => m.t && m.m);
  if (!meals.length) return null;
  return { meals, tip: typeof d.tip === 'string' ? d.tip.slice(0, 200) : '' };
}

// ─── 코치 ──────────────────────────────────────────────────────────────────
export interface CoachMessage {
  role: 'user' | 'assistant';
  content: string;
}

/** 남은 코치 대화 횟수 — 서버가 계산해서 내려 준다 (앱은 표시만) */
export interface CoachQuota {
  used: number;
  limit: number;
  remaining: number;
  unlimited?: boolean;
}

export interface CoachReply {
  reply: string;
  quota?: CoachQuota;
}

export async function askCoach(
  messages: CoachMessage[],
  context: string
): Promise<CoachReply> {
  try {
    const call = httpsCallable(functions, 'aiCoach', { timeout: CALL_TIMEOUT_MS });
    const res = await call({ messages: messages.slice(-20), context });
    const d = res.data as { reply?: string; quota?: CoachQuota };
    if (d?.reply) return { reply: d.reply, quota: d.quota };
    throw new AIUnavailable();
  } catch (e) {
    const need = asSubRequired(e);
    if (need) throw need;
    const over = asQuotaExceeded(e);
    if (over) throw over;
    if (!isUnavailable(e)) console.warn('[aiCoach]', e);
    throw new AIUnavailable('코치 연결에 실패했습니다. 잠시 후 다시 시도해주세요.');
  }
}
