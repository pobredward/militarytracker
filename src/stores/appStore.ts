import { create } from 'zustand';
import {
  UserProfile,
  Plan,
  ExerciseSession,
  WorkoutLog,
  WeightRecord,
  DietPlan,
  LoggedExercise,
} from '../types';
import { exById } from '../data/exercises';
import { localDate } from '../services/workoutService';
import type { CoachMessage } from '../services/aiService';

export interface SessionState {
  dayIdx: number;
  dayName: string;
  exIdx: number;
  data: ExerciseSession[];
  /** epoch ms — 경과 시간 계산 */
  startedAt: number;
  /** epoch ms — 휴식 종료 시각. 타임스탬프 기반이라 백그라운드에서도 정확 */
  restEndsAt: number | null;
}

interface AppState {
  profile: UserProfile | null;
  plan: Plan | null;
  planLoading: boolean;

  session: SessionState | null;

  logs: WorkoutLog[];
  weights: WeightRecord[];

  diet: DietPlan | null;
  dietLoading: boolean;

  chat: CoachMessage[];
  chatBusy: boolean;

  setProfile: (p: UserProfile | null) => void;
  setPlan: (plan: Plan | null) => void;
  setPlanLoading: (v: boolean) => void;

  startSession: (dayIdx: number) => void;
  setVal: (si: number, field: 'w' | 'r', v: string) => void;
  toggleSet: (si: number) => void;
  addSet: () => void;
  removeSet: (si: number) => void;
  startRest: (sec: number) => void;
  stopRest: () => void;
  goToEx: (exIdx: number) => void;
  moveEx: (delta: number) => void;
  /** 세션을 종료하고 저장할 로그를 반환 (저장은 호출 측에서) */
  finishSession: (userId: string) => Omit<WorkoutLog, 'id'> | null;
  clearSession: () => void;

  addLog: (log: WorkoutLog) => void;
  setLogs: (logs: WorkoutLog[]) => void;
  addWeight: (w: WeightRecord) => void;
  setWeights: (ws: WeightRecord[]) => void;

  setDiet: (d: DietPlan | null) => void;
  setDietLoading: (v: boolean) => void;

  addChat: (msg: CoachMessage) => void;
  setChatBusy: (v: boolean) => void;

  /** 로그아웃 시 사용자 데이터 초기화 */
  resetAll: () => void;
}

const num = (v: string): number => {
  const n = parseFloat(v);
  return Number.isFinite(n) ? n : 0;
};

export const useAppStore = create<AppState>((set, get) => ({
  profile: null,
  plan: null,
  planLoading: false,
  session: null,
  logs: [],
  weights: [],
  diet: null,
  dietLoading: false,
  chat: [],
  chatBusy: false,

  setProfile: (p) => set({ profile: p }),
  setPlan: (plan) => set({ plan }),
  setPlanLoading: (v) => set({ planLoading: v }),

  startSession: (dayIdx) => {
    const { plan } = get();
    const day = plan?.days[dayIdx];
    if (!day) return;
    const data: ExerciseSession[] = day.ids.map((id) => {
      const e = exById(id);
      const count = e?.s ?? 3;
      return { id, sets: Array.from({ length: count }, () => ({ w: '', r: '', done: false })) };
    });
    set({
      session: {
        dayIdx,
        dayName: day.name,
        exIdx: 0,
        data,
        startedAt: Date.now(),
        restEndsAt: null,
      },
    });
  },

  setVal: (si, field, v) => {
    const s = get().session;
    if (!s) return;
    const data = s.data.map((ex, ei) =>
      ei === s.exIdx
        ? { ...ex, sets: ex.sets.map((st, i) => (i === si ? { ...st, [field]: v } : st)) }
        : ex
    );
    set({ session: { ...s, data } });
  },

  toggleSet: (si) => {
    const s = get().session;
    if (!s) return;
    const justDone = !s.data[s.exIdx].sets[si].done;
    const data = s.data.map((ex, ei) =>
      ei === s.exIdx
        ? { ...ex, sets: ex.sets.map((st, i) => (i === si ? { ...st, done: !st.done } : st)) }
        : ex
    );
    const restSec = exById(s.data[s.exIdx].id)?.rest ?? 75;
    set({
      session: {
        ...s,
        data,
        restEndsAt: justDone ? Date.now() + restSec * 1000 : null,
      },
    });
  },

  addSet: () => {
    const s = get().session;
    if (!s) return;
    const data = s.data.map((ex, ei) =>
      ei === s.exIdx ? { ...ex, sets: [...ex.sets, { w: '', r: '', done: false }] } : ex
    );
    set({ session: { ...s, data } });
  },

  removeSet: (si) => {
    const s = get().session;
    if (!s) return;
    const data = s.data.map((ex, ei) =>
      ei === s.exIdx && ex.sets.length > 1
        ? { ...ex, sets: ex.sets.filter((_, i) => i !== si) }
        : ex
    );
    set({ session: { ...s, data } });
  },

  startRest: (sec) => {
    const s = get().session;
    if (!s) return;
    set({ session: { ...s, restEndsAt: Date.now() + sec * 1000 } });
  },

  stopRest: () => {
    const s = get().session;
    if (!s) return;
    set({ session: { ...s, restEndsAt: null } });
  },

  goToEx: (exIdx) => {
    const s = get().session;
    if (!s) return;
    const idx = Math.max(0, Math.min(s.data.length - 1, exIdx));
    set({ session: { ...s, exIdx: idx, restEndsAt: null } });
  },

  moveEx: (delta) => get().goToEx((get().session?.exIdx ?? 0) + delta),

  finishSession: (userId) => {
    const s = get().session;
    if (!s) return null;

    const exercises: LoggedExercise[] = s.data.map((x) => {
      const done = x.sets.filter((t) => t.done);
      return {
        id: x.id,
        sets: done.length,
        volume: Math.round(done.reduce((a, t) => a + num(t.w) * num(t.r), 0)),
      };
    });

    const log: Omit<WorkoutLog, 'id'> = {
      userId,
      date: localDate(),
      dayIdx: s.dayIdx,
      dayName: s.dayName,
      exercises,
      totalSets: exercises.reduce((a, x) => a + x.sets, 0),
      totalVolume: exercises.reduce((a, x) => a + x.volume, 0),
      durationSec: Math.round((Date.now() - s.startedAt) / 1000),
      createdAt: new Date().toISOString(),
    };

    set({ session: null });
    return log;
  },

  clearSession: () => set({ session: null }),

  addLog: (log) => set((s) => ({ logs: [log, ...s.logs] })),
  setLogs: (logs) => set({ logs }),
  addWeight: (w) => set((s) => ({ weights: [w, ...s.weights] })),
  setWeights: (ws) => set({ weights: ws }),

  setDiet: (d) => set({ diet: d }),
  setDietLoading: (v) => set({ dietLoading: v }),

  addChat: (msg) => set((s) => ({ chat: [...s.chat, msg] })),
  setChatBusy: (v) => set({ chatBusy: v }),

  resetAll: () =>
    set({
      profile: null,
      plan: null,
      planLoading: false,
      session: null,
      logs: [],
      weights: [],
      diet: null,
      dietLoading: false,
      chat: [],
      chatBusy: false,
    }),
}));
