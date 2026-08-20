import { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { useAuthStore } from '../../src/stores/authStore';
import { logout, deleteAccount } from '../../src/services/authService';
import { Colors } from '../../src/utils/colors';

interface StatRowProps {
  emoji: string;
  label: string;
  value: string;
}

function StatRow({ emoji, label, value }: StatRowProps) {
  return (
    <View style={styles.statRow}>
      <Text style={styles.statEmoji}>{emoji}</Text>
      <Text style={styles.statLabel}>{label}</Text>
      <Text style={styles.statValue}>{value}</Text>
    </View>
  );
}

export default function ProfileScreen() {
  const { user, setUser } = useAuthStore();
  const router = useRouter();
  const [loading, setLoading] = useState(false);

  async function handleLogout() {
    Alert.alert('로그아웃', '로그아웃 하시겠습니까?', [
      { text: '취소', style: 'cancel' },
      {
        text: '로그아웃',
        onPress: async () => {
          setLoading(true);
          try {
            await logout();
            setUser(null);
            router.replace('/auth/login');
          } finally {
            setLoading(false);
          }
        },
      },
    ]);
  }

  async function handleDeleteAccount() {
    Alert.alert(
      '계정 삭제',
      '계정을 삭제하면 모든 데이터가 영구적으로 삭제됩니다. 정말 삭제하시겠습니까?',
      [
        { text: '취소', style: 'cancel' },
        {
          text: '삭제',
          style: 'destructive',
          onPress: async () => {
            setLoading(true);
            try {
              await deleteAccount();
              setUser(null);
              router.replace('/auth/login');
            } catch {
              Alert.alert('오류', '계정 삭제에 실패했습니다. 다시 로그인 후 시도해주세요.');
            } finally {
              setLoading(false);
            }
          },
        },
      ]
    );
  }

  if (!user) return null;

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView style={styles.container}>
        <View style={styles.profileHeader}>
          <View style={styles.avatarLarge}>
            <Text style={styles.avatarText}>{user.displayName?.[0]?.toUpperCase() ?? '?'}</Text>
          </View>
          <Text style={styles.displayName}>{user.displayName}</Text>
          <Text style={styles.email}>{user.email}</Text>
          <View style={styles.providerBadge}>
            <Text style={styles.providerText}>
              {user.authProvider === 'google' ? '🔵 Google' : '📧 이메일'} 로그인
            </Text>
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>운동 통계</Text>
          <View style={styles.statsCard}>
            <StatRow emoji="📅" label="총 운동일" value={`${user.workoutDays}일`} />
            <View style={styles.divider} />
            <StatRow
              emoji="🏋️"
              label="총 스쿼트"
              value={`${user.totalSquats.toLocaleString()}회`}
            />
            <View style={styles.divider} />
            <StatRow
              emoji="🦵"
              label="총 런지"
              value={`${user.totalLunges.toLocaleString()}회`}
            />
            <View style={styles.divider} />
            <StatRow
              emoji="🚶"
              label="총 걷기"
              value={`${user.totalWalkSteps.toLocaleString()}보`}
            />
            <View style={styles.divider} />
            <StatRow
              emoji="🏃"
              label="총 달리기"
              value={`${user.totalRunDistance.toFixed(1)}km`}
            />
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>계정 관리</Text>
          <TouchableOpacity
            style={styles.menuItem}
            onPress={handleLogout}
            disabled={loading}
          >
            <Text style={styles.menuEmoji}>🚪</Text>
            <Text style={styles.menuText}>로그아웃</Text>
            {loading && <ActivityIndicator color={Colors.textSecondary} />}
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.menuItem, styles.menuItemDanger]}
            onPress={handleDeleteAccount}
            disabled={loading}
          >
            <Text style={styles.menuEmoji}>🗑️</Text>
            <Text style={styles.menuTextDanger}>계정 삭제</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.appInfo}>
          <Text style={styles.appInfoText}>밀리터리트래커 v1.0.0</Text>
          <Text style={styles.appInfoSubText}>군 훈련 목표 달성을 위한 앱</Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.background },
  container: { flex: 1 },
  profileHeader: {
    backgroundColor: Colors.primary,
    alignItems: 'center',
    paddingVertical: 32,
    paddingHorizontal: 20,
  },
  avatarLarge: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: Colors.accent,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
  },
  avatarText: { fontSize: 32, fontWeight: '800', color: Colors.text },
  displayName: { fontSize: 22, fontWeight: '800', color: Colors.white, marginBottom: 4 },
  email: { fontSize: 13, color: 'rgba(255,255,255,0.7)', marginBottom: 10 },
  providerBadge: {
    backgroundColor: 'rgba(255,255,255,0.15)',
    borderRadius: 20,
    paddingHorizontal: 12,
    paddingVertical: 4,
  },
  providerText: { fontSize: 12, color: Colors.white, fontWeight: '600' },
  section: { padding: 16 },
  sectionTitle: { fontSize: 14, fontWeight: '700', color: Colors.textSecondary, marginBottom: 10 },
  statsCard: {
    backgroundColor: Colors.white,
    borderRadius: 16,
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 8,
    elevation: 3,
  },
  statRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 14,
  },
  statEmoji: { fontSize: 20, marginRight: 12, width: 28 },
  statLabel: { flex: 1, fontSize: 14, color: Colors.text },
  statValue: { fontSize: 15, fontWeight: '700', color: Colors.primary },
  divider: { height: 1, backgroundColor: Colors.border, marginHorizontal: 16 },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.white,
    borderRadius: 14,
    padding: 16,
    marginBottom: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 4,
    elevation: 2,
  },
  menuItemDanger: { backgroundColor: '#FFF5F5' },
  menuEmoji: { fontSize: 20, marginRight: 12 },
  menuText: { flex: 1, fontSize: 15, color: Colors.text, fontWeight: '600' },
  menuTextDanger: { flex: 1, fontSize: 15, color: Colors.danger, fontWeight: '600' },
  appInfo: { alignItems: 'center', paddingVertical: 24 },
  appInfoText: { fontSize: 13, color: Colors.textMuted, fontWeight: '600' },
  appInfoSubText: { fontSize: 11, color: Colors.textMuted, marginTop: 2 },
});
