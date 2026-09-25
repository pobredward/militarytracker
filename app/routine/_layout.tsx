import { Stack } from 'expo-router';
import { colors } from '../../src/utils/colors';

export default function RoutineLayout() {
  return (
    <Stack
      screenOptions={{ headerShown: false, contentStyle: { backgroundColor: colors.bg } }}
    />
  );
}
