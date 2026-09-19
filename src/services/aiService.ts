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
export async function generatePlan(p: UserProfile): Promise<Plan> {
  try {
    const call = httpsCallable(functions, 'aiPlan');
    const res = await call({ profile: p, catalog: buildCatalog(p) });
    const plan = planFromAI(res.data, p);
    if (plan) return plan;
  } catch (e) {
    if (!isUnavailable(e)) console.warn('[aiPlan]', e);
  }
  return buildLocalPlan(p);
}

// ─── 식단 ──────────────────────────────────────────────────────────────────
export async function generateDiet(p: UserProfile): Promise<DietPlan> {
  const st = calcBodyStats(p);
  if (!st) return FALLBACK_DIET;
  try {
    const call = httpsCallable(functions, 'aiDiet');
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
    const j = res.data as DietPlan;
    if (j?.meals?.length) return { ...j, src: 'AI' };
  } catch (e) {
    if (!isUnavailable(e)) console.warn('[aiDiet]', e);
  }
  return FALLBACK_DIET;
}

// ─── 코치 ──────────────────────────────────────────────────────────────────
export interface CoachMessage {
  role: 'user' | 'assistant';
  content: string;
}

export async function askCoach(
  messages: CoachMessage[],
  context: string
): Promise<string> {
  try {
    const call = httpsCallable(functions, 'aiCoach');
    const res = await call({ messages, context });
    const reply = (res.data as { reply?: string })?.reply;
    if (reply) return reply;
    throw new AIUnavailable();
  } catch (e) {
    if (!isUnavailable(e)) console.warn('[aiCoach]', e);
    throw new AIUnavailable('코치 연결에 실패했습니다. 잠시 후 다시 시도해주세요.');
  }
}
