import { useEffect } from 'react';
import { Stack, useRouter, useSegments } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { onAuthChange, fetchUserProfile } from '../src/services/authService';
import { useAuthStore } from '../src/stores/authStore';

export default function RootLayout() {
  const { setUser, setInitialized, isInitialized, user } = useAuthStore();
  const router = useRouter();
  const segments = useSegments();

  useEffect(() => {
    const unsubscribe = onAuthChange(async (firebaseUser) => {
      if (firebaseUser) {
        const profile = await fetchUserProfile(firebaseUser.uid);
        setUser(profile);
      } else {
        setUser(null);
      }
      setInitialized(true);
    });
    return unsubscribe;
  }, []);

  useEffect(() => {
    if (!isInitialized) return;
    const inAuthGroup = segments[0] === 'auth';
    if (!user && !inAuthGroup) {
      router.replace('/auth/login');
    } else if (user && inAuthGroup) {
      router.replace('/tabs/home');
    }
  }, [user, isInitialized, segments]);

  return (
    <>
      <StatusBar style="light" />
      <Stack screenOptions={{ headerShown: false }}>
        <Stack.Screen name="auth" />
        <Stack.Screen name="tabs" />
      </Stack>
    </>
  );
}
