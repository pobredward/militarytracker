import { UserProfile, BodyStats, WeightRecord } from '../types';

// ─── 추세 체중 ──────────────────────────────────────────────────────────────
/** 추세 계산에 사용할 기간과 표본 수 */
const TREND_WINDOW_DAYS = 14;
const TREND_SAMPLE = 7;
/** 기준 체중 갱신을 제안하는 차이 (kg) */
export const WEIGHT_DRIFT_THRESHOLD = 1.5;

/**
 * 최근 기록의 중앙값으로 계산한 추세 체중.
 *
 * 체중은 수분·식사·측정 시각에 따라 하루에도 1~2kg 움직인다.
 * 최신값을 그대로 쓰면 칼로리 목표가 매일 출렁이므로 평활화한다.
 * 평균 대신 중앙값을 쓰는 이유는 오타(예: 800) 한 건에 끌려가지 않기 위해서다.
 */
export function trendWeight(weights: WeightRecord[]): number | null {
  if (!weights?.length) return null;

  const cutoff = Date.now() - TREND_WINDOW_DAYS * 86_400_000;

  // 같은 날 여러 번 기록했으면 가장 최근 1건만 사용 (weights 는 createdAt desc 정렬)
  const byDate = new Map<string, number>();
  for (const w of weights) {
    if (!byDate.has(w.date) && Number.isFinite(w.kg) && w.kg > 0) byDate.set(w.date, w.kg);
  }

  const recent = [...byDate.entries()]
    .filter(([date]) => new Date(`${date}T00:00:00`).getTime() >= cutoff)
    .sort((a, b) => b[0].localeCompare(a[0]))
    .slice(0, TREND_SAMPLE)
    .map(([, kg]) => kg);

  if (!recent.length) return null;

  const sorted = [...recent].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  const median = sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
  return Math.round(median * 10) / 10;
}

export interface EffectiveWeight {
  /** 실제 계산에 쓰인 체중 */
  kg: number;
  /** trend = 최근 기록 기반, profile = 온보딩/프로필에 저장된 기준 체중 */
  src: 'trend' | 'profile';
  /** 추세 체중 (기록이 없으면 null) */
  trend: number | null;
  /** 프로필에 저장된 기준 체중 */
  baseline: number;
  /** 기준과 추세의 차이 — 양수면 추세가 더 무겁다 */
  drift: number;
  /** 기준 체중 갱신을 제안할 만큼 벌어졌는지 */
  shouldUpdate: boolean;
}

export function effectiveWeight(
  profile: UserProfile | null | undefined,
  weights: WeightRecord[] = []
): EffectiveWeight | null {
  if (!profile) return null;
  const baseline = Number(profile.weight);
  if (!baseline) return null;

  const trend = trendWeight(weights);
  const kg = trend ?? baseline;
  const drift = trend !== null ? Math.round((trend - baseline) * 10) / 10 : 0;

  return {
    kg,
    src: trend !== null ? 'trend' : 'profile',
    trend,
    baseline,
    drift,
    shouldUpdate: trend !== null && Math.abs(drift) >= WEIGHT_DRIFT_THRESHOLD,
  };
}

// ─── 체형·칼로리 계산 ───────────────────────────────────────────────────────
/**
 * Mifflin-St Jeor + 활동계수 1.5.
 * weights 를 넘기면 추세 체중으로 계산하고, 없으면 프로필의 기준 체중을 쓴다.
 */
export function calcBodyStats(
  p: UserProfile | null | undefined,
  weights: WeightRecord[] = []
): BodyStats | null {
  if (!p) return null;
  const eff = effectiveWeight(p, weights);
  const W = eff?.kg ?? Number(p.weight);
  const H = Number(p.height);
  const A = Number(p.age);
  if (!W || !H || !A) return null;

  const bmi = W / (H / 100) ** 2;
  const bodyType =
    bmi < 18.5 ? '마른 체형' : bmi < 23 ? '표준 체형' : bmi < 25 ? '과체중 경계' : '과체중';

  const bmr = 10 * W + 6.25 * H - 5 * A + (p.sex === 'male' ? 5 : -161);
  const tdee = Math.round(bmr * 1.5);

  let kcal = tdee;
  let tagline = '유지 칼로리';
  if (p.goal === 'muscle') {
    kcal = tdee + 300;
    tagline = '증량 (+300kcal)';
  }
  if (p.goal === 'cut') {
    kcal = tdee - 400;
    tagline = '감량 (-400kcal)';
  }

  const protein = Math.round(W * (p.goal === 'cut' ? 2.0 : 1.8));
  const fat = Math.round((kcal * 0.25) / 9);
  const carb = Math.max(0, Math.round((kcal - protein * 4 - fat * 9) / 4));

  return {
    bmi: bmi.toFixed(1),
    bodyType,
    tdee,
    kcal,
    tagline,
    protein,
    fat,
    carb,
    weightUsed: Math.round(W * 10) / 10,
    weightSrc: eff?.src ?? 'profile',
  };
}

export const GOAL_LABEL: Record<UserProfile['goal'], string> = {
  muscle: '근성장',
  cut: '체지방 감량',
  habit: '운동 습관 만들기',
};

export const FOOD_LABEL: Record<UserProfile['food'], string> = {
  convenience: '편의점',
  self: '자취 요리',
  family: '집밥',
  out: '외식',
};
