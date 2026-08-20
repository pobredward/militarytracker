import { useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  ActivityIndicator,
  RefreshControl,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAuthStore } from '../../src/stores/authStore';
import { useWorkoutStore } from '../../src/stores/workoutStore';
import { getTodayWorkout } from '../../src/services/workoutService';
import { Colors } from '../../src/utils/colors';
import { formatDate, getProgressPercent } from '../../src/utils/formatters';

interface StatCardProps {
  emoji: string;
  label: string;
  current: number;
  goal: number;
  unit: string;
}

function StatCard({ emoji, label, current, goal, unit }: StatCardProps) {
  const pct = getProgressPercent(current, goal);
  return (
    <View style={styles.statCard}>
      <View style={styles.statHeader}>
        <Text style={styles.statEmoji}>{emoji}</Text>
        <View style={styles.statInfo}>
          <Text style={styles.statLabel}>{label}</Text>
          <Text style={styles.statValue}>
            {current.toLocaleString()}
            <Text style={styles.statUnit}>{unit}</Text>
          </Text>
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
      <Text style={styles.goalText}>
        목표: {goal.toLocaleString()}
        {unit}
      </Text>
    </View>
  );
}

export default function HomeScreen() {
  const { user } = useAuthStore();
  const { todayWorkout, goal, isLoading, setTodayWorkout, setLoading } = useWorkoutStore();

  async function loadTodayWorkout() {
    if (!user) return;
    setLoading(true);
    try {
      const workout = await getTodayWorkout(user.uid);
      setTodayWorkout(workout);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadTodayWorkout();
  }, [user]);

  const today = new Date().toISOString();
  const w = todayWorkout;

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView
        style={styles.container}
        refreshControl={<RefreshControl refreshing={isLoading} onRefresh={loadTodayWorkout} />}
      >
        <View style={styles.headerBg}>
          <Text style={styles.greeting}>안녕하세요, {user?.displayName ?? '전우'}님 👋</Text>
          <Text style={styles.date}>{formatDate(today)}</Text>
        </View>

        {isLoading && !w ? (
          <ActivityIndicator size="large" color={Colors.primary} style={{ marginTop: 40 }} />
        ) : (
          <View style={styles.content}>
            <Text style={styles.sectionTitle}>오늘의 운동 현황</Text>

            {!w ? (
              <View style={styles.emptyCard}>
                <Text style={styles.emptyEmoji}>🏃‍♂️</Text>
                <Text style={styles.emptyText}>아직 오늘의 운동 기록이 없어요</Text>
                <Text style={styles.emptySubText}>운동 탭에서 기록을 시작하세요!</Text>
              </View>
            ) : (
              <>
                <StatCard
                  emoji="🏋️"
                  label="스쿼트"
                  current={w.squatCount}
                  goal={goal.squats}
                  unit="회"
                />
                <StatCard
                  emoji="🦵"
                  label="런지"
                  current={w.lungeCount}
                  goal={goal.lunges}
                  unit="회"
                />
                <StatCard
                  emoji="🚶"
                  label="걷기"
                  current={w.walkSteps}
                  goal={goal.walkSteps}
                  unit="보"
                />
                <StatCard
                  emoji="🏃"
                  label="달리기"
                  current={w.runDistance}
                  goal={goal.runDistance}
                  unit="km"
                />
              </>
            )}

            <Text style={styles.sectionTitle}>전체 통계</Text>
            <View style={styles.totalGrid}>
              {[
                { label: '운동일', value: user?.workoutDays ?? 0, unit: '일', emoji: '📅' },
                { label: '총 스쿼트', value: user?.totalSquats ?? 0, unit: '회', emoji: '🏋️' },
                { label: '총 런지', value: user?.totalLunges ?? 0, unit: '회', emoji: '🦵' },
                { label: '총 걷기', value: user?.totalWalkSteps ?? 0, unit: '보', emoji: '🚶' },
              ].map((item) => (
                <View key={item.label} style={styles.totalCard}>
                  <Text style={styles.totalEmoji}>{item.emoji}</Text>
                  <Text style={styles.totalValue}>{item.value.toLocaleString()}</Text>
                  <Text style={styles.totalUnit}>{item.unit}</Text>
                  <Text style={styles.totalLabel}>{item.label}</Text>
                </View>
              ))}
            </View>
          </View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.primary },
  container: { flex: 1, backgroundColor: Colors.background },
  headerBg: {
    backgroundColor: Colors.primary,
    padding: 24,
    paddingBottom: 32,
  },
  greeting: { fontSize: 22, fontWeight: '800', color: Colors.white },
  date: { fontSize: 13, color: 'rgba(255,255,255,0.7)', marginTop: 4 },
  content: { padding: 16, marginTop: -12 },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: Colors.text,
    marginBottom: 12,
    marginTop: 8,
  },
  statCard: {
    backgroundColor: Colors.white,
    borderRadius: 16,
    padding: 16,
    marginBottom: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 8,
    elevation: 3,
  },
  statHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: 10 },
  statEmoji: { fontSize: 28, marginRight: 12 },
  statInfo: { flex: 1 },
  statLabel: { fontSize: 12, color: Colors.textSecondary, fontWeight: '600' },
  statValue: { fontSize: 22, fontWeight: '800', color: Colors.text },
  statUnit: { fontSize: 13, color: Colors.textSecondary, fontWeight: '400' },
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
    marginBottom: 6,
  },
  progressFill: {
    height: '100%',
    backgroundColor: Colors.primaryLight,
    borderRadius: 3,
  },
  progressFillDone: { backgroundColor: Colors.success },
  goalText: { fontSize: 11, color: Colors.textMuted },
  emptyCard: {
    backgroundColor: Colors.white,
    borderRadius: 16,
    padding: 32,
    alignItems: 'center',
    marginBottom: 12,
  },
  emptyEmoji: { fontSize: 48, marginBottom: 12 },
  emptyText: { fontSize: 15, fontWeight: '600', color: Colors.text },
  emptySubText: { fontSize: 13, color: Colors.textSecondary, marginTop: 4 },
  totalGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  totalCard: {
    backgroundColor: Colors.white,
    borderRadius: 14,
    padding: 16,
    alignItems: 'center',
    width: '47.5%',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 6,
    elevation: 2,
  },
  totalEmoji: { fontSize: 24, marginBottom: 6 },
  totalValue: { fontSize: 20, fontWeight: '800', color: Colors.primary },
  totalUnit: { fontSize: 11, color: Colors.textSecondary },
  totalLabel: { fontSize: 12, color: Colors.textMuted, marginTop: 2 },
});
