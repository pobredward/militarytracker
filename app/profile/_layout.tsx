import { Stack } from 'expo-router';
import { colors } from '../../src/utils/colors';

export default function ProfileLayout() {
  return (
    <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: colors.bg } }} />
  );
}
