import { create } from 'zustand';
import { Workout, WorkoutGoal, DEFAULT_WORKOUT_GOAL } from '../types';

interface WorkoutState {
  todayWorkout: Workout | null;
  history: Workout[];
  goal: WorkoutGoal;
  isLoading: boolean;
  setTodayWorkout: (workout: Workout | null) => void;
  setHistory: (history: Workout[]) => void;
  setGoal: (goal: WorkoutGoal) => void;
  setLoading: (loading: boolean) => void;
  updateTodayField: (field: keyof WorkoutGoal, value: number) => void;
}

export const useWorkoutStore = create<WorkoutState>((set) => ({
  todayWorkout: null,
  history: [],
  goal: DEFAULT_WORKOUT_GOAL,
  isLoading: false,
  setTodayWorkout: (todayWorkout) => set({ todayWorkout }),
  setHistory: (history) => set({ history }),
  setGoal: (goal) => set({ goal }),
  setLoading: (isLoading) => set({ isLoading }),
  updateTodayField: (field, value) =>
    set((state) => {
      if (!state.todayWorkout) return state;
      const fieldMap: Record<keyof WorkoutGoal, keyof Workout> = {
        squats: 'squatCount',
        lunges: 'lungeCount',
        walkSteps: 'walkSteps',
        runDistance: 'runDistance',
      };
      return {
        todayWorkout: {
          ...state.todayWorkout,
          [fieldMap[field]]: value,
        },
      };
    }),
}));
