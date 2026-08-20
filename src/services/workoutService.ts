import {
  collection,
  doc,
  getDoc,
  setDoc,
  addDoc,
  query,
  where,
  orderBy,
  getDocs,
  updateDoc,
  serverTimestamp,
  Timestamp,
  limit,
} from 'firebase/firestore';
import { db } from './firebase';
import { Workout } from '../types';

const todayDateString = () => new Date().toISOString().split('T')[0];

export async function getTodayWorkout(userId: string): Promise<Workout | null> {
  const today = todayDateString();
  const q = query(
    collection(db, 'workouts'),
    where('userId', '==', userId),
    where('date', '==', today),
    limit(1)
  );
  const snap = await getDocs(q);
  if (snap.empty) return null;
  const d = snap.docs[0];
  return { id: d.id, ...(d.data() as Omit<Workout, 'id'>) };
}

export async function saveOrUpdateTodayWorkout(
  userId: string,
  data: Partial<Pick<Workout, 'squatCount' | 'lungeCount' | 'walkSteps' | 'runDistance' | 'duration' | 'notes'>>
): Promise<Workout> {
  const today = todayDateString();
  const existing = await getTodayWorkout(userId);
  const now = new Date().toISOString();

  if (existing) {
    const ref = doc(db, 'workouts', existing.id);
    await updateDoc(ref, { ...data, updatedAt: now });
    return { ...existing, ...data, updatedAt: now };
  }

  const newWorkout: Omit<Workout, 'id'> = {
    userId,
    squatCount: 0,
    lungeCount: 0,
    walkSteps: 0,
    runDistance: 0,
    duration: 0,
    date: today,
    createdAt: now,
    updatedAt: now,
    ...data,
  };
  const ref = await addDoc(collection(db, 'workouts'), newWorkout);
  return { id: ref.id, ...newWorkout };
}

export async function getWorkoutHistory(userId: string, limitCount = 30): Promise<Workout[]> {
  const q = query(
    collection(db, 'workouts'),
    where('userId', '==', userId),
    orderBy('date', 'desc'),
    limit(limitCount)
  );
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Workout, 'id'>) }));
}

export async function updateUserStats(
  userId: string,
  workout: Workout,
  previousWorkout: Workout | null
): Promise<void> {
  const userRef = doc(db, 'users', userId);
  const userSnap = await getDoc(userRef);
  if (!userSnap.exists()) return;

  const userData = userSnap.data();
  const prev = previousWorkout ?? { squatCount: 0, lungeCount: 0, walkSteps: 0, runDistance: 0 };

  const delta: Record<string, number> = {
    totalSquats: (userData.totalSquats ?? 0) - prev.squatCount + workout.squatCount,
    totalLunges: (userData.totalLunges ?? 0) - prev.lungeCount + workout.lungeCount,
    totalWalkSteps: (userData.totalWalkSteps ?? 0) - prev.walkSteps + workout.walkSteps,
    totalRunDistance: (userData.totalRunDistance ?? 0) - prev.runDistance + workout.runDistance,
  };

  if (!previousWorkout) {
    delta.workoutDays = (userData.workoutDays ?? 0) + 1;
  }

  await updateDoc(userRef, delta);
}
