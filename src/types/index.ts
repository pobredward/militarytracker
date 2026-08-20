export interface User {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoURL: string | null;
  authProvider: 'email' | 'google';
  totalSquats: number;
  totalLunges: number;
  totalWalkSteps: number;
  totalRunDistance: number;
  workoutDays: number;
  createdAt: string;
  lastLoginAt: string;
}

export interface Workout {
  id: string;
  userId: string;
  squatCount: number;
  lungeCount: number;
  walkSteps: number;
  runDistance: number;
  duration: number;
  notes?: string;
  date: string;
  createdAt: string;
  updatedAt: string;
}

export interface Post {
  id: string;
  userId: string;
  authorName: string;
  authorPhotoURL?: string;
  title: string;
  content: string;
  imageURL?: string;
  likes: string[];
  commentCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface Comment {
  id: string;
  postId: string;
  userId: string;
  authorName: string;
  authorPhotoURL?: string;
  content: string;
  createdAt: string;
}

export interface WorkoutGoal {
  squats: number;
  lunges: number;
  walkSteps: number;
  runDistance: number;
}

export const DEFAULT_WORKOUT_GOAL: WorkoutGoal = {
  squats: 100,
  lunges: 50,
  walkSteps: 10000,
  runDistance: 5,
};
