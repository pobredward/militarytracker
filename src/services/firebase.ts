import { initializeApp, getApps, getApp } from 'firebase/app';
import * as FirebaseAuth from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getFunctions } from 'firebase/functions';
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { Auth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: process.env.EXPO_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.EXPO_PUBLIC_FIREBASE_APP_ID,
};

const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApp();

/**
 * React Native 에서는 기본 getAuth() 가 메모리 persistence 로 동작해
 * 앱을 껐다 켜면 로그인이 풀린다. AsyncStorage persistence 로 초기화한다.
 * (getReactNativePersistence 는 RN 전용 export 라 웹 타입 정의에 노출되지 않음)
 */
function createAuth(): Auth {
  const rnPersistence = (FirebaseAuth as unknown as {
    getReactNativePersistence?: (storage: unknown) => unknown;
  }).getReactNativePersistence;

  if (rnPersistence) {
    try {
      return FirebaseAuth.initializeAuth(app, {
        persistence: rnPersistence(AsyncStorage) as never,
      });
    } catch {
      // Fast Refresh 등으로 이미 초기화된 경우
      return FirebaseAuth.getAuth(app);
    }
  }
  return FirebaseAuth.getAuth(app);
}

export const auth = createAuth();
export const db = getFirestore(app);
/** Cloud Functions — AI 프록시가 배포된 서울 리전 */
export const functions = getFunctions(app, 'asia-northeast3');
export default app;
