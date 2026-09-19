import { useEffect } from 'react';
import { Stack, useRouter, useSegments } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import * as SplashScreen from 'expo-splash-screen';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { onAuthChange, fetchUserProfile, fetchPlan } from '../src/services/authService';
import { getWorkoutLogs, getWeights } from '../src/services/workoutService';
import { useAuthStore } from '../src/stores/authStore';
import { useAppStore } from '../src/stores/appStore';

// 하이드레이션이 끝날 때까지 스플래시를 잡아둔다 (로그인 화면 깜빡임 방지)
SplashScreen.preventAutoHideAsync().catch(() => {});

export default function RootLayout() {
  const { setUser, setInitialized, isInitialized, user } = useAuthStore();
  const { setProfile, setPlan, setLogs, setWeights, resetAll } = useAppStore();
  const router = useRouter();
  const segments = useSegments();

  // ─── 인증 + 사용자 데이터 복원 ──────────────────────────────────────────
  useEffect(() => {
    const unsubscribe = onAuthChange(async (firebaseUser) => {
      try {
        if (!firebaseUser) {
          setUser(null);
          resetAll();
          return;
        }
        const profile = await fetchUserProfile(firebaseUser.uid);
        setUser(profile);
        if (!profile) return;

        // 온보딩에서 저장한 신체 정보 — 식단·코치·플랜 재생성이 모두 여기에 의존
        if (profile.profile) setProfile(profile.profile);

        const [plan, logs, weights] = await Promise.all([
          fetchPlan(firebaseUser.uid),
          getWorkoutLogs(firebaseUser.uid, 60),
          getWeights(firebaseUser.uid, 30),
        ]);
        if (plan) setPlan(plan);
        setLogs(logs);
        setWeights(weights);
      } catch (e) {
        console.warn('[hydrate]', e);
      } finally {
        setInitialized(true);
      }
    });
    return unsubscribe;
  }, []);

  useEffect(() => {
    if (isInitialized) SplashScreen.hideAsync().catch(() => {});
  }, [isInitialized]);

  // ─── 라우팅 가드 ────────────────────────────────────────────────────────
  useEffect(() => {
    if (!isInitialized) return;
    const root = segments[0];

    if (!user) {
      if (root !== 'auth') router.replace('/auth/login');
      return;
    }
    if (!user.onboardingDone) {
      if (root !== 'onboard') router.replace('/onboard');
      return;
    }
    // 로그인 + 온보딩 완료 상태에서 진입점/인증 화면에 있으면 홈으로
    if (root === undefined || root === 'auth' || root === 'onboard') {
      router.replace('/tabs/home');
    }
  }, [user, isInitialized, segments]);

  return (
    <SafeAreaProvider>
      <StatusBar style="light" />
      <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: '#09090A' } }}>
        <Stack.Screen name="index" />
        <Stack.Screen name="auth" />
        <Stack.Screen name="onboard" />
        <Stack.Screen name="tabs" />
        <Stack.Screen name="routine" />
        <Stack.Screen name="exercise" />
        <Stack.Screen name="library" />
      </Stack>
    </SafeAreaProvider>
  );
}
