import type { Part, Place } from '../data/exercises';

// ─── Auth / User ───────────────────────────────────────────────────────────
export type Role = 'user' | 'admin';

export interface User {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoURL: string | null;
  authProvider: 'email' | 'google';
  /** 'admin' 인 계정은 보안 규칙에서 전체 권한을 가진다 */
  role: Role;
  onboardingDone: boolean;
  /** 온보딩에서 저장된 신체·목표 정보 (콜드스타트 시 복원용) */
  profile?: UserProfile | null;
  createdAt: string;
  lastLoginAt: string;
}

// ─── Onboarding Profile ────────────────────────────────────────────────────
export type Goal = 'muscle' | 'cut' | 'habit';
export type Level = 1 | 2 | 3;
export type FoodEnv = 'convenience' | 'self' | 'family' | 'out';

export interface UserProfile {
  sex: 'male' | 'female';
  age: string;
  height: string;
  weight: string;
  goal: Goal;
  env: Place;
  days: 2 | 3 | 4 | 5 | 6;
  level: Level;
  food: FoodEnv;
  allergy: string;
}

// ─── Plan ──────────────────────────────────────────────────────────────────
export interface PlanDay {
  /** 루틴 프리셋에서 온 경우 RoutineDay.id, 자동 생성이면 슬러그 */
  id: string;
  name: string;
  focus: string;
  ids: string[];
}

export interface Plan {
  /** 프리셋 루틴에서 시작한 경우의 루틴 id */
  routineId?: string | null;
  days: PlanDay[];
  planSrc: 'AI' | 'LOCAL' | 'PRESET';
  planReason: string;
  updatedAt?: string;
}

// ─── Session / Workout Log ─────────────────────────────────────────────────
export interface SetRecord {
  w: string;
  r: string;
  done: boolean;
}

export interface ExerciseSession {
  id: string;
  sets: SetRecord[];
}

export interface LoggedExercise {
  id: string;
  /** 완료한 세트 수 */
  sets: number;
  /** Σ(무게 × 반복) — 맨몸/시간 종목은 0 */
  volume: number;
}

export interface WorkoutLog {
  id?: string;
  userId: string;
  /** YYYY-MM-DD (로컬 기준) */
  date: string;
  /** 플랜 내 몇 번째 데이였는지 — 다음 데이 계산에 사용 */
  dayIdx: number;
  dayName: string;
  exercises: LoggedExercise[];
  totalSets: number;
  totalVolume: number;
  /** 운동 소요 시간(초) */
  durationSec: number;
  createdAt: string;
}

// ─── Weight ────────────────────────────────────────────────────────────────
export interface WeightRecord {
  id?: string;
  userId: string;
  date: string;
  kg: number;
  createdAt?: string;
}

// ─── Diet ──────────────────────────────────────────────────────────────────
export interface MealItem {
  t: string;
  m: string;
  k: string;
}

export interface DietPlan {
  meals: MealItem[];
  tip: string;
  src?: 'AI' | 'LOCAL';
}

// ─── Body Stats (computed) ────────────────────────────────────────────────
export interface BodyStats {
  bmi: string;
  bodyType: string;
  tdee: number;
  kcal: number;
  tagline: string;
  protein: number;
  fat: number;
  carb: number;
}

// ─── Report ────────────────────────────────────────────────────────────────
export type PartVolume = Record<Part, number>;
