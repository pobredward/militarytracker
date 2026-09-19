import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  UserProfile, Plan, ExerciseSession, WorkoutLog, WeightRecord,
  DietPlan, LoggedExercise, SetDetail, SessionSummary,
} from '../types';
import { exById } from '../data/exercises';
import { localDate } from '../services/workoutService';
import { e1rm } from '../utils/stats';
import type { CoachMessage } from '../services/aiService';

export interface SessionState {
  dayIdx: number;
  dayName: string;
  exIdx: number;
  data: ExerciseSession[];
  startedAt: number;
  /** epoch ms — 휴식 종료 시각. 타임스탬프 기반이라 백그라운드에서도 정확 */
  restEndsAt: number | null;
}

/** 중단된 세션을 복구할 최대 시간 — 이보다 오래되면 버린다 */
const SESSION_TTL_MS = 12 * 60 * 60 * 1000;

interface AppState {
  /** 기기에 저장된 데이터의 소유자 — 다른 계정으로 로그인하면 폐기한다 */
  ownerUid: string | null;

  profile: UserProfile | null;
  plan: Plan | null;

  session: SessionState | null;
  /** 운동 완료 직후 요약 */
  summary: SessionSummary | null;
  /** 서버 저장에 실패해 재시도를 기다리는 로그 — 기기에 함께 보존된다 */
  pendingLogs: Omit<WorkoutLog, 'id'>[];

  logs: WorkoutLog[];
  weights: WeightRecord[];

  diet: DietPlan | null;
  dietLoading: boolean;

  chat: CoachMessage[];
  chatBusy: boolean;

  setOwner: (uid: string | null) => void;
  setProfile: (p: UserProfile | null) => void;
  setPlan: (plan: Plan | null) => void;

  startSession: (dayIdx: number) => boolean;
  setVal: (si: number, field: 'w' | 'r', v: string) => void;
  toggleSet: (si: number) => void;
  addSet: () => void;
  removeSet: (si: number) => void;
  startRest: (sec: number) => void;
  stopRest: () => void;
  goToEx: (exIdx: number) => void;
  moveEx: (delta: number) => void;
  swapExercise: (newId: string) => void;
  appendExercise: (newId: string) => boolean;
  /** 저장할 로그를 만들어 반환. 세션은 아직 지우지 않는다 */
  buildLog: (userId: string) => Omit<WorkoutLog, 'id'> | null;
  /** 저장이 끝난 뒤 세션을 닫는다 */
  closeSession: () => void;
  clearSession: () => void;
  setSummary: (s: SessionSummary | null) => void;
  pruneSession: () => void;

  queuePending: (log: Omit<WorkoutLog, 'id'>) => void;
  dropPending: (createdAt: string) => void;

  addLog: (log: WorkoutLog) => void;
  setLogs: (logs: WorkoutLog[]) => void;
  addWeight: (w: WeightRecord) => void;
  setWeights: (ws: WeightRecord[]) => void;

  setDiet: (d: DietPlan | null) => void;
  setDietLoading: (v: boolean) => void;

  addChat: (msg: CoachMessage) => void;
  clearChat: () => void;
  setChatBusy: (v: boolean) => void;

  resetAll: () => void;
}

const num = (v: string): number => {
  const n = parseFloat(v);
  return Number.isFinite(n) ? n : 0;
};

export const useAppStore = create<AppState>()(
  persist(
    (set, get) => ({
      ownerUid: null,
      profile: null,
      plan: null,
      session: null,
      summary: null,
      pendingLogs: [],
      logs: [],
      weights: [],
      diet: null,
      dietLoading: false,
      chat: [],
      chatBusy: false,

      setOwner: (uid) => {
        // 다른 계정이 로그인하면 기기에 남은 이전 사용자 데이터를 폐기한다
        if (uid && get().ownerUid && get().ownerUid !== uid) {
          set({ session: null, summary: null, pendingLogs: [], diet: null, chat: [] });
        }
        set({ ownerUid: uid });
      },

      setProfile: (p) => set({ profile: p }),
      setPlan: (plan) => set({ plan }),

      startSession: (dayIdx) => {
        const { plan } = get();
        const day = plan?.days[dayIdx];
        if (!day || !day.ids.length) return false;
        const data: ExerciseSession[] = day.ids
          .filter((id) => !!exById(id))
          .map((id) => {
            const count = exById(id)?.s ?? 3;
            return { id, sets: Array.from({ length: count }, () => ({ w: '', r: '', done: false })) };
          });
        if (!data.length) return false;
        set({
          summary: null,
          session: { dayIdx, dayName: day.name, exIdx: 0, data, startedAt: Date.now(), restEndsAt: null },
        });
        return true;
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
        // 체크를 풀 때는 진행 중인 휴식을 건드리지 않는다
        set({
          session: { ...s, data, restEndsAt: justDone ? Date.now() + restSec * 1000 : s.restEndsAt },
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
        set({ session: { ...s, exIdx: idx } });
      },

      moveEx: (delta) => get().goToEx((get().session?.exIdx ?? 0) + delta),

      swapExercise: (newId) => {
        const s = get().session;
        const target = exById(newId);
        if (!s || !target) return;
        if (s.data.some((x, i) => x.id === newId && i !== s.exIdx)) return; // 중복 방지
        const data = s.data.map((ex, ei) => {
          if (ei !== s.exIdx) return ex;
          const keep = ex.sets.length || target.s;
          return {
            id: newId,
            sets: Array.from({ length: keep }, () => ({ w: '', r: '', done: false })),
          };
        });
        set({ session: { ...s, data } });
      },

      appendExercise: (newId) => {
        const s = get().session;
        const target = exById(newId);
        if (!s || !target) return false;
        if (s.data.some((x) => x.id === newId)) return false; // 이미 있는 종목
        const data = [
          ...s.data,
          { id: newId, sets: Array.from({ length: target.s }, () => ({ w: '', r: '', done: false })) },
        ];
        set({ session: { ...s, data, exIdx: data.length - 1 } });
        return true;
      },

      buildLog: (userId) => {
        const s = get().session;
        if (!s) return null;

        const exercises: LoggedExercise[] = s.data.map((x) => {
          // 무게·횟수가 모두 비어 있는 세트는 기록으로 치지 않는다
          const done = x.sets.filter((t) => t.done && (num(t.w) > 0 || num(t.r) > 0));
          const detail: SetDetail[] = done.map((t) => ({ w: num(t.w), r: num(t.r) }));
          const scored = detail.filter((d) => d.w > 0 && d.r > 0);
          const best = scored.reduce<SetDetail | undefined>(
            (acc, d) => (!acc || e1rm(d.w, d.r) > e1rm(acc.w, acc.r) ? d : acc),
            undefined
          );
          return {
            id: x.id,
            sets: done.length,
            volume: Math.round(detail.reduce((a, d) => a + d.w * d.r, 0)),
            ...(detail.length ? { detail } : {}),
            ...(best ? { best } : {}),
          };
        });

        return {
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
      },

      closeSession: () => set({ session: null }),
      clearSession: () => set({ session: null, summary: null }),
      setSummary: (summary) => set({ summary }),

      pruneSession: () => {
        const s = get().session;
        if (s && Date.now() - s.startedAt > SESSION_TTL_MS) set({ session: null });
      },

      queuePending: (log) => set((s) => ({ pendingLogs: [...s.pendingLogs, log] })),
      dropPending: (createdAt) =>
        set((s) => ({ pendingLogs: s.pendingLogs.filter((l) => l.createdAt !== createdAt) })),

      addLog: (log) =>
        set((s) => ({ logs: [log, ...s.logs.filter((l) => l.createdAt !== log.createdAt)] })),
      setLogs: (logs) => set({ logs }),
      addWeight: (w) => set((s) => ({ weights: [w, ...s.weights] })),
      setWeights: (ws) => set({ weights: ws }),

      setDiet: (d) => set({ diet: d }),
      setDietLoading: (v) => set({ dietLoading: v }),

      addChat: (msg) => set((s) => ({ chat: [...s.chat, msg] })),
      clearChat: () => set({ chat: [] }),
      setChatBusy: (v) => set({ chatBusy: v }),

      resetAll: () =>
        set({
          ownerUid: null, profile: null, plan: null,
          session: null, summary: null, pendingLogs: [],
          logs: [], weights: [],
          diet: null, dietLoading: false,
          chat: [], chatBusy: false,
        }),
    }),
    {
      name: 'mt-app-store',
      storage: createJSONStorage(() => AsyncStorage),
      // 서버에서 다시 받아오는 값(logs/weights/plan/profile)은 저장하지 않는다.
      // 유실되면 안 되는 것만 기기에 남긴다.
      partialize: (s) => ({
        ownerUid: s.ownerUid,
        session: s.session,
        pendingLogs: s.pendingLogs,
        diet: s.diet,
        chat: s.chat,
      }),
      version: 2,
      migrate: (persisted, version) => {
        // v1 에는 ownerUid·pendingLogs 가 없었다 — 소유자 불명이므로 폐기한다
        if (version < 2) return { ownerUid: null, session: null, pendingLogs: [], diet: null, chat: [] };
        return persisted as never;
      },
      onRehydrateStorage: () => (state) => {
        state?.pruneSession();
      },
    }
  )
);

export const hasHydrated = () => useAppStore.persist.hasHydrated();
