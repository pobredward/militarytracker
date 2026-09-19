import {
  collection,
  addDoc,
  deleteDoc,
  doc,
  query,
  where,
  orderBy,
  limit as fsLimit,
  getDocs,
  writeBatch,
} from 'firebase/firestore';
import { db } from './firebase';
import { WorkoutLog, WeightRecord } from '../types';

const nowIso = () => new Date().toISOString();

/** 로컬 시간 기준 YYYY-MM-DD (toISOString 은 UTC라 한국 새벽에 날짜가 밀린다) */
export function localDate(d: Date = new Date()): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

// ─── Workout Logs ─────────────────────────────────────────────────────────
export async function saveWorkoutLog(log: Omit<WorkoutLog, 'id'>): Promise<WorkoutLog> {
  const ref = await addDoc(collection(db, 'workoutLogs'), log);
  return { id: ref.id, ...log };
}

export async function getWorkoutLogs(userId: string, limitCount = 60): Promise<WorkoutLog[]> {
  const q = query(
    collection(db, 'workoutLogs'),
    where('userId', '==', userId),
    orderBy('createdAt', 'desc'),
    fsLimit(limitCount)
  );
  const snap = await getDocs(q);
  return snap.docs.map((d) => normalizeLog(d.id, d.data()));
}

/** 구버전 문서(dayIdx·totalSets 없음) 대비 정규화 */
function normalizeLog(id: string, data: Record<string, unknown>): WorkoutLog {
  const d = data as Partial<WorkoutLog>;
  const exercises = (d.exercises ?? []).map((x) => ({
    id: x.id,
    sets: x.sets ?? 0,
    volume: x.volume ?? 0,
  }));
  return {
    id,
    userId: d.userId ?? '',
    date: d.date ?? localDate(),
    dayIdx: typeof d.dayIdx === 'number' ? d.dayIdx : -1,
    dayName: d.dayName ?? '',
    exercises,
    totalSets: d.totalSets ?? exercises.reduce((a, x) => a + x.sets, 0),
    totalVolume: d.totalVolume ?? exercises.reduce((a, x) => a + x.volume, 0),
    durationSec: d.durationSec ?? 0,
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

export async function deleteWeight(id: string): Promise<void> {
  await deleteDoc(doc(db, 'weights', id));
}

// ─── Cascade delete ───────────────────────────────────────────────────────
async function deleteByUser(col: 'workoutLogs' | 'weights', userId: string): Promise<void> {
  // 배치 한도 500 — 나눠서 커밋
  for (;;) {
    const snap = await getDocs(
      query(collection(db, col), where('userId', '==', userId), fsLimit(400))
    );
    if (snap.empty) return;
    const batch = writeBatch(db);
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    if (snap.size < 400) return;
  }
}

/** 계정 삭제 시 users/plans/workoutLogs/weights 전부 정리 */
export async function deleteAllUserData(userId: string): Promise<void> {
  await Promise.all([deleteByUser('workoutLogs', userId), deleteByUser('weights', userId)]);
  const batch = writeBatch(db);
  batch.delete(doc(db, 'plans', userId));
  batch.delete(doc(db, 'users', userId));
  await batch.commit();
}
