import { exById, Part, PART_ORDER } from '../data/exercises';
import { Plan, WorkoutLog, PartVolume } from '../types';
import { localDate } from '../services/workoutService';

// ─── 주간 계산 (월요일 시작) ───────────────────────────────────────────────
export function mondayOf(d: Date = new Date()): Date {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  const dow = (x.getDay() + 6) % 7; // 월=0
  x.setDate(x.getDate() - dow);
  return x;
}

export function weekDates(d: Date = new Date()): string[] {
  const mon = mondayOf(d);
  return Array.from({ length: 7 }, (_, i) => {
    const day = new Date(mon);
    day.setDate(mon.getDate() + i);
    return localDate(day);
  });
}

/** 이번 주 월~일 운동 여부 — 로그에서 계산하므로 앱을 껐다 켜도 유지된다 */
export function weekStreak(logs: WorkoutLog[]): boolean[] {
  const dates = weekDates();
  const done = new Set(logs.map((l) => l.date));
  return dates.map((d) => done.has(d));
}

export function currentStreakDays(logs: WorkoutLog[]): number {
  if (!logs.length) return 0;
  const done = new Set(logs.map((l) => l.date));
  let streak = 0;
  const cursor = new Date();
  // 오늘 기록이 없으면 어제부터 센다
  if (!done.has(localDate(cursor))) cursor.setDate(cursor.getDate() - 1);
  for (;;) {
    if (!done.has(localDate(cursor))) break;
    streak++;
    cursor.setDate(cursor.getDate() - 1);
  }
  return streak;
}

// ─── 다음 운동 데이 ────────────────────────────────────────────────────────
/** 가장 최근 로그의 다음 데이를 반환. 로그가 없으면 0 */
export function nextDayIdx(logs: WorkoutLog[], plan: Plan | null): number {
  if (!plan?.days.length) return 0;
  const len = plan.days.length;
  const last = logs[0]; // createdAt desc 정렬 가정
  if (!last) return 0;

  let idx = last.dayIdx;
  if (idx < 0 || idx >= len) {
    // 구버전 로그 — 이름으로 역추적
    idx = plan.days.findIndex((d) => d.name === last.dayName);
  }
  if (idx < 0) return 0;
  return (idx + 1) % len;
}

// ─── 볼륨 집계 ─────────────────────────────────────────────────────────────
const emptyVolume = (): PartVolume =>
  PART_ORDER.reduce((acc, p) => ({ ...acc, [p]: 0 }), {} as PartVolume);

/** 부위별 세트 수 — opts.weekOnly 면 이번 주만 */
export function setsByPart(logs: WorkoutLog[], opts: { weekOnly?: boolean } = {}): PartVolume {
  const acc = emptyVolume();
  const week = new Set(weekDates());
  logs.forEach((l) => {
    if (opts.weekOnly && !week.has(l.date)) return;
    l.exercises.forEach((x) => {
      const e = exById(x.id);
      if (!e) return;
      acc[e.part] += x.sets;
    });
  });
  return acc;
}

export function weakestPart(vol: PartVolume): Part | null {
  const entries = PART_ORDER.map((p) => [p, vol[p]] as const);
  if (entries.every(([, v]) => v === 0)) return null;
  return entries.reduce((a, b) => (a[1] <= b[1] ? a : b))[0];
}

export function totalSets(logs: WorkoutLog[], opts: { weekOnly?: boolean } = {}): number {
  const week = new Set(weekDates());
  return logs
    .filter((l) => !opts.weekOnly || week.has(l.date))
    .reduce((a, l) => a + l.totalSets, 0);
}

export function totalVolume(logs: WorkoutLog[], opts: { weekOnly?: boolean } = {}): number {
  const week = new Set(weekDates());
  return logs
    .filter((l) => !opts.weekOnly || week.has(l.date))
    .reduce((a, l) => a + l.totalVolume, 0);
}

/** 특정 종목의 최근 세트 기록 (다음 세션 기본값으로 사용) */
export function lastRecordOf(logs: WorkoutLog[], exId: string): { sets: number; volume: number } | null {
  for (const l of logs) {
    const hit = l.exercises.find((x) => x.id === exId);
    if (hit) return { sets: hit.sets, volume: hit.volume };
  }
  return null;
}

export const fmtDuration = (sec: number): string => {
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return m > 0 ? `${m}분 ${s}초` : `${s}초`;
};

export const fmtClock = (sec: number): string =>
  `${String(Math.floor(Math.max(0, sec) / 60)).padStart(2, '0')}:${String(Math.max(0, sec) % 60).padStart(2, '0')}`;
