import { Exercise, exById, exFilter, Part } from '../data/exercises';
import { recommendRoutine, routineById } from '../data/routines';
import { Plan, PlanDay, UserProfile } from '../types';

// ─── 시드 난수 (재생성 시마다 다른 구성) ───────────────────────────────────
function mulberry32(seed: number) {
  let a = seed >>> 0;
  return () => {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function shuffle<T>(arr: T[], rnd: () => number): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rnd() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// ─── 프리셋 루틴 → 플랜 ────────────────────────────────────────────────────
export function planFromRoutine(routineId: string): Plan | null {
  const r = routineById(routineId);
  if (!r) return null;
  return {
    routineId: r.id,
    days: r.days.map<PlanDay>((d) => ({ id: d.id, name: d.name, focus: d.focus, ids: d.exIds })),
    planSrc: 'PRESET',
    planReason: `${r.name} — ${r.subtitle}`,
  };
}

// ─── 자동 생성 플랜 (AI 실패 시 폴백 / 다시 생성) ──────────────────────────
type DaySpec = { id: string; name: string; focus: string; parts: Part[] };

const SPECS: Record<string, DaySpec> = {
  push: { id: 'push', name: '푸시데이', focus: '가슴 · 어깨 · 삼두', parts: ['chest', 'shoulders', 'triceps'] },
  pull: { id: 'pull', name: '풀데이', focus: '등 · 이두', parts: ['back', 'biceps'] },
  legs: { id: 'legs', name: '레그데이', focus: '하체 · 코어', parts: ['legs', 'abs'] },
  upper: { id: 'upper', name: '상체', focus: '가슴 · 등 · 어깨', parts: ['chest', 'back', 'shoulders'] },
  lower: { id: 'lower', name: '하체', focus: '하체 · 코어', parts: ['legs', 'abs'] },
  chest: { id: 'chest', name: '가슴', focus: '가슴 집중', parts: ['chest'] },
  back: { id: 'back', name: '등', focus: '등 집중', parts: ['back'] },
  shoulders: { id: 'shoulders', name: '어깨', focus: '삼각근 전체', parts: ['shoulders'] },
  arms: { id: 'arms', name: '팔', focus: '이두 · 삼두', parts: ['biceps', 'triceps'] },
};

const SPLITS: Record<number, string[]> = {
  2: ['upper', 'lower'],
  3: ['push', 'pull', 'legs'],
  4: ['push', 'pull', 'legs', 'upper'],
  5: ['chest', 'back', 'legs', 'shoulders', 'arms'],
  6: ['push', 'pull', 'legs', 'upper', 'lower', 'arms'],
};

export function buildLocalPlan(p: UserProfile, seed = Date.now()): Plan {
  const rnd = mulberry32(seed);
  const maxLevel = p.level;
  const perDay = p.goal === 'habit' ? 3 : 5;

  const poolFor = (parts: Part[]): Exercise[] => {
    const list = parts.flatMap((part) => exFilter({ place: p.env, maxLevel, part }));
    // 난이도가 맞는 종목이 부족하면 한 단계 위까지 허용
    if (list.length >= perDay) return list;
    return parts.flatMap((part) =>
      exFilter({ place: p.env, maxLevel: Math.min(3, maxLevel + 1) as 1 | 2 | 3, part })
    );
  };

  const used = new Set<string>();

  const buildDay = (specKey: string): PlanDay => {
    const spec = SPECS[specKey];
    const pool = shuffle(poolFor(spec.parts), rnd);
    const ids: string[] = [];

    // 부위를 고르게 섞기 위해 부위별로 한 종목씩 라운드로빈
    const byPart = new Map<Part, Exercise[]>();
    spec.parts.forEach((part) => byPart.set(part, pool.filter((e) => e.part === part)));

    let guard = 0;
    while (ids.length < perDay && guard++ < 50) {
      for (const part of spec.parts) {
        if (ids.length >= perDay) break;
        const bucket = byPart.get(part) ?? [];
        const next = bucket.find((e) => !ids.includes(e.id) && !used.has(e.id));
        const fallback = bucket.find((e) => !ids.includes(e.id));
        const chosen = next ?? fallback;
        if (chosen) ids.push(chosen.id);
      }
    }
    ids.forEach((id) => used.add(id));
    return { id: spec.id, name: spec.name, focus: spec.focus, ids };
  };

  const keys = SPLITS[p.days] ?? SPLITS[3];
  const days = keys.map(buildDay);

  return {
    routineId: null,
    days,
    planSrc: 'LOCAL',
    planReason:
      p.goal === 'habit'
        ? '습관 형성 목표에 맞춰 하루 3종목으로 짧게 구성했습니다.'
        : `주 ${p.days}일 · ${p.env === 'home' ? '홈트' : '헬스장'} 환경에 맞춰 자동 구성했습니다.`,
  };
}

/** AI 응답(days/reason)을 검증해 Plan 으로 변환. 유효하지 않으면 null */
export function planFromAI(
  raw: unknown,
  fallbackProfile: UserProfile
): Plan | null {
  const j = raw as { days?: { id?: string; name?: string; focus?: string; ids?: string[] }[]; reason?: string };
  if (!j?.days?.length) return null;

  const days: PlanDay[] = j.days
    .map((d, i) => {
      const ids = (d.ids ?? []).filter((id) => !!exById(id));
      return {
        id: d.id || `day${i + 1}`,
        name: d.name || `Day ${i + 1}`,
        focus: d.focus || '',
        ids,
      };
    })
    .filter((d) => d.ids.length > 0);

  if (!days.length) return null;
  return {
    routineId: null,
    days,
    planSrc: 'AI',
    planReason: j.reason || `주 ${fallbackProfile.days}일 목표에 맞춘 AI 구성입니다.`,
  };
}

/**
 * 구버전 플랜 문서 보정.
 * 이전 스키마의 PlanDay 에는 id 가 없어 key 가 NaN 이 되고 중복 키 에러가 발생한다.
 * 존재하지 않는 종목 id 도 함께 걸러낸다.
 */
export function normalizePlan(plan: Plan | null | undefined): Plan | null {
  if (!plan || !Array.isArray(plan.days) || plan.days.length === 0) return null;
  const days: PlanDay[] = plan.days
    .map((d, i) => ({
      id: d?.id || `day${i + 1}`,
      name: d?.name || `Day ${i + 1}`,
      focus: d?.focus || '',
      ids: Array.isArray(d?.ids) ? d.ids.filter((x) => !!exById(x)) : [],
    }))
    // 종목이 하나도 남지 않은 데이는 버린다 — 화면에서 undefined 참조를 만든다
    .filter((d) => d.ids.length > 0);
  if (!days.length) return null;
  return { ...plan, days };
}
