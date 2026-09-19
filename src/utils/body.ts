import { UserProfile, BodyStats } from '../types';

/** Mifflin-St Jeor + 활동계수 1.5 기반 체형·칼로리 계산 */
export function calcBodyStats(p: UserProfile | null | undefined): BodyStats | null {
  if (!p) return null;
  const W = Number(p.weight);
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

  return { bmi: bmi.toFixed(1), bodyType, tdee, kcal, tagline, protein, fat, carb };
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

export const ENV_LABEL: Record<UserProfile['env'], string> = {
  gym: '헬스장',
  home: '홈트레이닝',
};
