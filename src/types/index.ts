import type { Part, Place } from '../data/exercises';

// ─── Auth / User ───────────────────────────────────────────────────────────
export type Role = 'user' | 'admin';

// ─── Subscription ──────────────────────────────────────────────────────────
export type PlanTier = 'free' | 'pro';
/** canceled = 해지했지만 기간은 남음, grace = 결제 실패 유예 */
export type SubStatus = 'none' | 'trial' | 'active' | 'grace' | 'expired' | 'canceled';
export type SubSource = 'none' | 'ios' | 'android' | 'promo' | 'admin';

/**
 * users/{uid}.sub — 서버(Cloud Functions)만 쓴다.
 * 보안 규칙이 클라이언트의 sub 수정을 막고 있으므로, 앱에서 이 값을 바꿔도
 * 저장되지 않는다. 실제 권한 판정도 서버가 다시 한다.
 */
export interface Subscription {
  tier: PlanTier;
  status: SubStatus;
  /** ISO. null 이면 만료 없음(관리자 지급) */
  expiresAt: string | null;
  source: SubSource;
  productId: string | null;
  /** 무료 체험을 이미 사용했는지 — 재발급 방지 */
  trialUsed: boolean;
  updatedAt: string;
}

/**
 * users/{uid}.stats — 개인 기록 요약. 클라이언트가 로그 저장 직후 갱신한다.
 * 앱은 최근 로그 일부만 불러오므로, 오래된 PR 과 누적치는 여기서 읽는다.
 */
export interface UserStats {
  /** exId → 역대 최고 세트 (맨몸/시간 종목은 w=0, r 최대) */
  pr: Record<string, { w: number; r: number; date: string }>;
  totalLogs: number;
  totalVolume: number;
}

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
  /** 구독 상태 — 서버 전용 필드 */
  sub?: Subscription | null;
  /** 개인 기록 요약 — 클라이언트가 로그 저장 시 갱신 */
  stats?: UserStats;
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
  id: string;
  name: string;
  focus: string;
  ids: string[];
}

export interface Plan {
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

/** 완료된 한 세트의 실제 수치 */
export interface SetDetail {
  w: number;
  r: number;
}

export interface LoggedExercise {
  id: string;
  /** 완료한 세트 수 */
  sets: number;
  /** Σ(무게 × 반복) — 맨몸/시간 종목은 0 */
  volume: number;
  /** 완료 세트별 수치 — 다음 세션에서 "지난 기록"으로 보여준다 */
  detail?: SetDetail[];
  /** 그날의 최고 세트 (추정 1RM 기준) */
  best?: SetDetail;
}

export interface WorkoutLog {
  id?: string;
  userId: string;
  /** YYYY-MM-DD (로컬 기준) */
  date: string;
  dayIdx: number;
  dayName: string;
  exercises: LoggedExercise[];
  totalSets: number;
  totalVolume: number;
  durationSec: number;
  createdAt: string;
}

/** 운동 완료 직후 보여줄 요약 */
export interface SessionSummary {
  dayName: string;
  totalSets: number;
  totalVolume: number;
  durationSec: number;
  exercises: LoggedExercise[];
  /** 개인 기록을 갱신한 종목 id 목록 */
  prIds: string[];
  saved: boolean;
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
  /** 생성 시점 — 오래된 식단인지 표시하는 데 사용 */
  createdAt?: string;
}

// ─── Body Stats (computed) ────────────────────────────────────────────────
export interface BodyStats {
  bmi: string;
  bodyType: string;
  tdee: number;
  /** TDEE 계산에 쓴 활동계수 (주 운동 일수 기준) */
  activityFactor: number;
  kcal: number;
  tagline: string;
  protein: number;
  fat: number;
  carb: number;
  /** 실제 계산에 사용한 체중 */
  weightUsed: number;
  /** trend = 최근 체중 기록의 추세값, profile = 저장된 기준 체중 */
  weightSrc: 'trend' | 'profile';
}

// ─── Report ────────────────────────────────────────────────────────────────
export type PartVolume = Record<Part, number>;
