import { useEffect } from 'react';
import { Stack, useRouter, useSegments } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import * as SplashScreen from 'expo-splash-screen';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { onAuthChange, fetchUserProfile, fetchPlan } from '../src/services/authService';
import { getWorkoutLogs, getWeights, saveWorkoutLog } from '../src/services/workoutService';
import { useAuthStore } from '../src/stores/authStore';
import { useAppStore } from '../src/stores/appStore';
import MobileFrame from '../src/components/MobileFrame';

// 하이드레이션이 끝날 때까지 스플래시를 잡아둔다 (로그인 화면 깜빡임 방지)
SplashScreen.preventAutoHideAsync().catch(() => {});

export default function RootLayout() {
  const { setUser, setInitialized, isInitialized, user } = useAuthStore();
  const { setOwner, setProfile, setPlan, setLogs, setWeights, resetAll, addLog, dropPending } = useAppStore();
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

        // 기기에 남은 이전 계정 데이터를 폐기한다
        setOwner(firebaseUser.uid);

        let profile = await fetchUserProfile(firebaseUser.uid).catch(() => undefined);
        if (profile === undefined) {
          // 오프라인 등으로 프로필을 못 읽었을 때 로그인 화면으로 튕기지 않도록
          // 최소 정보로 세션을 유지한다
          setUser({
            uid: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL,
            authProvider: 'email',
            role: 'user',
            onboardingDone: true,
            profile: null,
            createdAt: new Date().toISOString(),
            lastLoginAt: new Date().toISOString(),
          });
          return;
        }
        setUser(profile);
        if (!profile) return;

        // 온보딩에서 저장한 신체 정보 — 식단·코치·플랜 재생성이 모두 여기에 의존
        if (profile.profile) setProfile(profile.profile);

        // 하나가 실패해도 나머지는 살린다
        const [planR, logsR, weightsR] = await Promise.allSettled([
          fetchPlan(firebaseUser.uid),
          getWorkoutLogs(firebaseUser.uid, 60),
          getWeights(firebaseUser.uid, 30),
        ]);
        if (planR.status === 'fulfilled' && planR.value) setPlan(planR.value);
        if (logsR.status === 'fulfilled') setLogs(logsR.value);
        if (weightsR.status === 'fulfilled') setWeights(weightsR.value);

        // 지난번에 서버 저장이 실패한 운동 기록을 재시도한다
        const pending = useAppStore.getState().pendingLogs;
        for (const log of pending) {
          try {
            addLog(await saveWorkoutLog(log));
            dropPending(log.createdAt);
          } catch {
            break; // 아직 연결이 안 되면 다음 실행에서 다시 시도
          }
        }
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
    if (root === undefined || root === 'auth') {
      router.replace('/tabs/home');
    }
  }, [user, isInitialized, segments]);

  return (
    <SafeAreaProvider>
      <StatusBar style="light" />
      <MobileFrame>
      <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: '#09090A' } }}>
        <Stack.Screen name="index" />
        <Stack.Screen name="auth" />
        <Stack.Screen name="onboard" />
        <Stack.Screen name="tabs" />
        <Stack.Screen name="routine" />
        <Stack.Screen name="exercise" />
        <Stack.Screen name="library" />
        <Stack.Screen name="history" />
        <Stack.Screen name="profile" />
      </Stack>
      </MobileFrame>
    </SafeAreaProvider>
  );
}
