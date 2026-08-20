import { useState, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAuthStore } from '../../src/stores/authStore';
import { useWorkoutStore } from '../../src/stores/workoutStore';
import { getTodayWorkout, saveOrUpdateTodayWorkout, updateUserStats } from '../../src/services/workoutService';
import { Colors } from '../../src/utils/colors';
import { getProgressPercent } from '../../src/utils/formatters';
import { Workout } from '../../src/types';

interface CounterProps {
  emoji: string;
  label: string;
  value: number;
  goal: number;
  unit: string;
  step: number;
  onIncrease: () => void;
  onDecrease: () => void;
}

function Counter({ emoji, label, value, goal, unit, step, onIncrease, onDecrease }: CounterProps) {
  const pct = getProgressPercent(value, goal);
  return (
    <View style={styles.counterCard}>
      <View style={styles.counterHeader}>
        <Text style={styles.counterEmoji}>{emoji}</Text>
        <View style={{ flex: 1 }}>
          <Text style={styles.counterLabel}>{label}</Text>
          <Text style={styles.counterGoal}>목표: {goal.toLocaleString()}{unit}</Text>
        </View>
        <View style={[styles.pctBadge, pct >= 100 && styles.pctBadgeDone]}>
          <Text style={[styles.pctText, pct >= 100 && styles.pctTextDone]}>{pct}%</Text>
        </View>
      </View>
      <View style={styles.progressBar}>
        <View
          style={[
            styles.progressFill,
            { width: `${pct}%` as any },
            pct >= 100 && styles.progressFillDone,
          ]}
        />
      </View>
      <View style={styles.counterControls}>
        <TouchableOpacity
          style={[styles.ctrlBtn, styles.ctrlBtnMinus]}
          onPress={onDecrease}
          disabled={value <= 0}
        >
          <Text style={styles.ctrlBtnText}>−</Text>
        </TouchableOpacity>
        <View style={styles.valueContainer}>
          <Text style={styles.valueText}>{value.toLocaleString()}</Text>
          <Text style={styles.valueUnit}>{unit}</Text>
        </View>
        <TouchableOpacity style={[styles.ctrlBtn, styles.ctrlBtnPlus]} onPress={onIncrease}>
          <Text style={[styles.ctrlBtnText, { color: Colors.white }]}>+</Text>
        </TouchableOpacity>
      </View>
      <Text style={styles.stepHint}>1회 버튼 = {step}{unit}</Text>
    </View>
  );
}

export default function WorkoutScreen() {
  const { user } = useAuthStore();
  const { todayWorkout, goal, isLoading, setTodayWorkout, setLoading } = useWorkoutStore();
  const [saving, setSaving] = useState(false);

  const [squats, setSquats] = useState(0);
  const [lunges, setLunges] = useState(0);
  const [steps, setSteps] = useState(0);
  const [distance, setDistance] = useState(0);

  useEffect(() => {
    loadWorkout();
  }, [user]);

  useEffect(() => {
    if (todayWorkout) {
      setSquats(todayWorkout.squatCount);
      setLunges(todayWorkout.lungeCount);
      setSteps(todayWorkout.walkSteps);
      setDistance(todayWorkout.runDistance);
    }
  }, [todayWorkout]);

  async function loadWorkout() {
    if (!user) return;
    setLoading(true);
    try {
      const w = await getTodayWorkout(user.uid);
      setTodayWorkout(w);
    } finally {
      setLoading(false);
    }
  }

  async function handleSave() {
    if (!user) return;
    setSaving(true);
    try {
      const previous = todayWorkout;
      const updated = await saveOrUpdateTodayWorkout(user.uid, {
        squatCount: squats,
        lungeCount: lunges,
        walkSteps: steps,
        runDistance: distance,
      });
      await updateUserStats(user.uid, updated, previous);
      setTodayWorkout(updated);
      Alert.alert('저장 완료', '오늘의 운동이 저장되었습니다! 💪');
    } catch {
      Alert.alert('오류', '저장에 실패했습니다. 다시 시도해주세요.');
    } finally {
      setSaving(false);
    }
  }

  if (isLoading) {
    return (
      <SafeAreaView style={styles.safe}>
        <ActivityIndicator size="large" color={Colors.primary} style={{ flex: 1 }} />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView style={styles.container}>
        <View style={styles.header}>
          <Text style={styles.title}>💪 오늘의 운동</Text>
          <Text style={styles.subtitle}>목표를 향해 파이팅!</Text>
        </View>

        <View style={styles.content}>
          <Counter
            emoji="🏋️"
            label="스쿼트"
            value={squats}
            goal={goal.squats}
            unit="회"
            step={5}
            onIncrease={() => setSquats((v) => v + 5)}
            onDecrease={() => setSquats((v) => Math.max(0, v - 5))}
          />
          <Counter
            emoji="🦵"
            label="런지"
            value={lunges}
            goal={goal.lunges}
            unit="회"
            step={5}
            onIncrease={() => setLunges((v) => v + 5)}
            onDecrease={() => setLunges((v) => Math.max(0, v - 5))}
          />
          <Counter
            emoji="🚶"
            label="걷기"
            value={steps}
            goal={goal.walkSteps}
            unit="보"
            step={500}
            onIncrease={() => setSteps((v) => v + 500)}
            onDecrease={() => setSteps((v) => Math.max(0, v - 500))}
          />
          <Counter
            emoji="🏃"
            label="달리기"
            value={distance}
            goal={goal.runDistance}
            unit="km"
            step={0.5}
            onIncrease={() => setDistance((v) => Math.round((v + 0.5) * 10) / 10)}
            onDecrease={() => setDistance((v) => Math.max(0, Math.round((v - 0.5) * 10) / 10))}
          />

          <TouchableOpacity
            style={[styles.saveBtn, saving && styles.saveBtnDisabled]}
            onPress={handleSave}
            disabled={saving}
          >
            {saving ? (
              <ActivityIndicator color={Colors.white} />
            ) : (
              <Text style={styles.saveBtnText}>💾 저장하기</Text>
            )}
          </TouchableOpacity>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.primary },
  container: { flex: 1, backgroundColor: Colors.background },
  header: {
    backgroundColor: Colors.primary,
    padding: 24,
    paddingBottom: 28,
  },
  title: { fontSize: 22, fontWeight: '800', color: Colors.white },
  subtitle: { fontSize: 13, color: 'rgba(255,255,255,0.7)', marginTop: 4 },
  content: { padding: 16, marginTop: -8 },
  counterCard: {
    backgroundColor: Colors.white,
    borderRadius: 16,
    padding: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 8,
    elevation: 3,
  },
  counterHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: 10 },
  counterEmoji: { fontSize: 28, marginRight: 12 },
  counterLabel: { fontSize: 15, fontWeight: '700', color: Colors.text },
  counterGoal: { fontSize: 11, color: Colors.textMuted, marginTop: 2 },
  pctBadge: {
    backgroundColor: Colors.surfaceAlt,
    borderRadius: 8,
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  pctBadgeDone: { backgroundColor: Colors.success },
  pctText: { fontSize: 12, fontWeight: '700', color: Colors.textSecondary },
  pctTextDone: { color: Colors.white },
  progressBar: {
    height: 6,
    backgroundColor: Colors.surfaceAlt,
    borderRadius: 3,
    overflow: 'hidden',
    marginBottom: 12,
  },
  progressFill: { height: '100%', backgroundColor: Colors.primaryLight, borderRadius: 3 },
  progressFillDone: { backgroundColor: Colors.success },
  counterControls: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  ctrlBtn: {
    width: 48,
    height: 48,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  ctrlBtnMinus: { backgroundColor: Colors.surfaceAlt },
  ctrlBtnPlus: { backgroundColor: Colors.primary },
  ctrlBtnText: { fontSize: 24, fontWeight: '700', color: Colors.text },
  valueContainer: { alignItems: 'center' },
  valueText: { fontSize: 28, fontWeight: '800', color: Colors.text },
  valueUnit: { fontSize: 12, color: Colors.textSecondary },
  stepHint: { fontSize: 11, color: Colors.textMuted, marginTop: 8, textAlign: 'right' },
  saveBtn: {
    backgroundColor: Colors.accent,
    borderRadius: 14,
    paddingVertical: 16,
    alignItems: 'center',
    marginTop: 8,
    marginBottom: 24,
  },
  saveBtnDisabled: { opacity: 0.6 },
  saveBtnText: { fontSize: 16, fontWeight: '800', color: Colors.text },
});
