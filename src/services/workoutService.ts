import {
  collection,
  addDoc,
  query,
  where,
  orderBy,
  limit as fsLimit,
  getDocs,
} from 'firebase/firestore';
import { db } from './firebase';
import { WorkoutLog, WeightRecord, SetDetail } from '../types';

const nowIso = () => new Date().toISOString();

/** 로컬 시간 기준 YYYY-MM-DD (toISOString 은 UTC라 한국 새벽에 날짜가 밀린다) */
export function localDate(d: Date = new Date()): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export class SaveTimeout extends Error {}

/**
 * 서버 저장 확인을 이 시간까지만 기다린다.
 * Firestore JS SDK 의 addDoc 은 오프라인에서 reject 하지 않고 재접속까지 pending 이라,
 * 타임아웃이 없으면 오프라인 사용자는 무한 스피너를 본다.
 */
const SAVE_TIMEOUT_MS = 8_000;

// ─── Workout Logs ─────────────────────────────────────────────────────────
export async function saveWorkoutLog(log: Omit<WorkoutLog, 'id'>): Promise<WorkoutLog> {
  const write = addDoc(collection(db, 'workoutLogs'), log).then((ref) => ({ id: ref.id, ...log }));
  const timeout = new Promise<never>((_, reject) =>
    setTimeout(() => reject(new SaveTimeout('save timeout')), SAVE_TIMEOUT_MS)
  );
  // 타임아웃으로 빠져나가도 SDK 의 쓰기는 큐에 남아 재접속 시 커밋될 수 있다.
  // 호출자는 pendingLogs 에 넣고, 재시도 전에 서버에 같은 createdAt 이 있는지 확인한다(flushPendingLogs).
  return Promise.race([write, timeout]);
}

export async function getWorkoutLogs(userId: string, limitCount = 60): Promise<WorkoutLog[]> {
  const q = query(
    collection(db, 'workoutLogs'),
    where('userId', '==', userId),
    orderBy('createdAt', 'desc'),
    fsLimit(limitCount)
  );
  const snap = await getDocs(q);
  const out: WorkoutLog[] = [];
  for (const d of snap.docs) {
    // 문서 하나가 깨졌다고 전체 기록을 잃지 않는다
    try { out.push(normalizeLog(d.id, d.data())); } catch { /* skip */ }
  }
  return out;
}

/** 같은 createdAt 의 로그가 이미 서버에 있는지 — 타임아웃 후 재시도의 중복 방지 */
export async function findLogByCreatedAt(userId: string, createdAt: string): Promise<WorkoutLog | null> {
  const q = query(
    collection(db, 'workoutLogs'),
    where('userId', '==', userId),
    where('createdAt', '==', createdAt),
    fsLimit(1)
  );
  const snap = await getDocs(q);
  if (snap.empty) return null;
  const d = snap.docs[0];
  return normalizeLog(d.id, d.data());
}

const sanitizeDetail = (v: unknown): SetDetail[] | undefined => {
  if (!Array.isArray(v)) return undefined;
  const list = v
    .filter((x): x is SetDetail => !!x && typeof x === 'object')
    .map((x) => ({ w: Number(x.w) || 0, r: Number(x.r) || 0 }));
  return list.length ? list : undefined;
};

/** 구버전 문서(dayIdx·totalSets·detail 없음) 대비 정규화 */
export function normalizeLog(id: string, data: Record<string, unknown>): WorkoutLog {
  const d = data as Partial<WorkoutLog>;
  const rawEx = Array.isArray(d.exercises) ? d.exercises : [];
  const exercises = rawEx.filter((x) => !!x && typeof x === 'object' && typeof x.id === 'string').map((x) => {
    const detail = sanitizeDetail(x.detail);
    // 맨몸·시간 종목은 w=0 이 정상이다 — r 만 있으면 best 로 인정한다
    const best =
      x.best && Number(x.best.r) > 0 && Number(x.best.w) >= 0
        ? { w: Number(x.best.w) || 0, r: Number(x.best.r) }
        : undefined;
    return {
      id: x.id,
      sets: Math.max(0, Number(x.sets) || 0),
      volume: Math.max(0, Number(x.volume) || 0),
      // 세트별 수치는 '지난 기록'·개인기록 판정의 근거라 반드시 보존한다
      ...(detail ? { detail } : {}),
      ...(best ? { best } : {}),
    };
  });
  return {
    id,
    userId: d.userId ?? '',
    date: d.date ?? localDate(),
    dayIdx: typeof d.dayIdx === 'number' ? d.dayIdx : -1,
    dayName: d.dayName ?? '',
    exercises,
    totalSets: Number.isFinite(Number(d.totalSets)) && d.totalSets != null
      ? Number(d.totalSets) : exercises.reduce((a, x) => a + x.sets, 0),
    totalVolume: Number.isFinite(Number(d.totalVolume)) && d.totalVolume != null
      ? Number(d.totalVolume) : exercises.reduce((a, x) => a + x.volume, 0),
    durationSec: Math.max(0, Number(d.durationSec) || 0),
    createdAt: d.createdAt ?? nowIso(),
  };
}

// ─── Weight Records ───────────────────────────────────────────────────────
export async function saveWeight(userId: string, kg: number): Promise<WeightRecord> {
  const record: Omit<WeightRecord, 'id'> = {
    userId,
    date: localDate(),
    kg,
    createdAt: nowIso(),
  };
  const ref = await addDoc(collection(db, 'weights'), record);
  return { id: ref.id, ...record };
}

export async function getWeights(userId: string, limitCount = 30): Promise<WeightRecord[]> {
  const q = query(
    collection(db, 'weights'),
    where('userId', '==', userId),
    orderBy('createdAt', 'desc'),
    fsLimit(limitCount)
  );
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<WeightRecord, 'id'>) }));
}
