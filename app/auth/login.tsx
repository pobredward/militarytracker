import { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
  Alert,
  ScrollView,
} from 'react-native';
import { useRouter, Link } from 'expo-router';
import { signInWithEmail } from '../../src/services/authService';
import { Colors } from '../../src/utils/colors';

export default function LoginScreen() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleLogin() {
    if (!email.trim() || !password.trim()) {
      Alert.alert('입력 오류', '이메일과 비밀번호를 모두 입력해주세요.');
      return;
    }
    setLoading(true);
    try {
      await signInWithEmail(email.trim(), password);
      router.replace('/tabs/home');
    } catch (e: any) {
      const msg =
        e.code === 'auth/user-not-found' || e.code === 'auth/wrong-password'
          ? '이메일 또는 비밀번호가 올바르지 않습니다.'
          : e.code === 'auth/invalid-email'
          ? '올바른 이메일 형식이 아닙니다.'
          : '로그인에 실패했습니다. 다시 시도해주세요.';
      Alert.alert('로그인 실패', msg);
    } finally {
      setLoading(false);
    }
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">
        <View style={styles.header}>
          <Text style={styles.emoji}>🪖</Text>
          <Text style={styles.title}>밀리터리트래커</Text>
          <Text style={styles.subtitle}>군 훈련 목표를 달성하세요</Text>
        </View>

        <View style={styles.form}>
          <TextInput
            style={styles.input}
            placeholder="이메일"
            placeholderTextColor={Colors.textMuted}
            value={email}
            onChangeText={setEmail}
            keyboardType="email-address"
            autoCapitalize="none"
            autoCorrect={false}
          />
          <TextInput
            style={styles.input}
            placeholder="비밀번호"
            placeholderTextColor={Colors.textMuted}
            value={password}
            onChangeText={setPassword}
            secureTextEntry
          />

          <TouchableOpacity
            style={[styles.button, loading && styles.buttonDisabled]}
            onPress={handleLogin}
            disabled={loading}
          >
            {loading ? (
              <ActivityIndicator color={Colors.white} />
            ) : (
              <Text style={styles.buttonText}>로그인</Text>
            )}
          </TouchableOpacity>

          <View style={styles.divider}>
            <View style={styles.dividerLine} />
            <Text style={styles.dividerText}>또는</Text>
            <View style={styles.dividerLine} />
          </View>

          <View style={styles.footer}>
            <Text style={styles.footerText}>계정이 없으신가요? </Text>
            <Link href="/auth/signup" asChild>
              <TouchableOpacity>
                <Text style={styles.link}>회원가입</Text>
              </TouchableOpacity>
            </Link>
          </View>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.primary },
  scroll: { flexGrow: 1, justifyContent: 'center', padding: 24 },
  header: { alignItems: 'center', marginBottom: 48 },
  emoji: { fontSize: 64, marginBottom: 12 },
  title: { fontSize: 28, fontWeight: '800', color: Colors.white, letterSpacing: 1 },
  subtitle: { fontSize: 14, color: 'rgba(255,255,255,0.7)', marginTop: 6 },
  form: {
    backgroundColor: Colors.white,
    borderRadius: 20,
    padding: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.15,
    shadowRadius: 16,
    elevation: 8,
  },
  input: {
    borderWidth: 1.5,
    borderColor: Colors.border,
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontSize: 15,
    color: Colors.text,
    marginBottom: 14,
    backgroundColor: Colors.background,
  },
  button: {
    backgroundColor: Colors.primary,
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: 'center',
    marginTop: 4,
  },
  buttonDisabled: { opacity: 0.6 },
  buttonText: { color: Colors.white, fontSize: 16, fontWeight: '700' },
  divider: { flexDirection: 'row', alignItems: 'center', marginVertical: 20 },
  dividerLine: { flex: 1, height: 1, backgroundColor: Colors.border },
  dividerText: { marginHorizontal: 12, color: Colors.textMuted, fontSize: 13 },
  footer: { flexDirection: 'row', justifyContent: 'center', alignItems: 'center' },
  footerText: { color: Colors.textSecondary, fontSize: 14 },
  link: { color: Colors.primary, fontWeight: '700', fontSize: 14 },
});
