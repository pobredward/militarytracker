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
import { signUpWithEmail } from '../../src/services/authService';
import { Colors } from '../../src/utils/colors';

export default function SignupScreen() {
  const router = useRouter();
  const [displayName, setDisplayName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSignup() {
    if (!displayName.trim() || !email.trim() || !password || !confirmPassword) {
      Alert.alert('입력 오류', '모든 항목을 입력해주세요.');
      return;
    }
    if (password !== confirmPassword) {
      Alert.alert('비밀번호 오류', '비밀번호가 일치하지 않습니다.');
      return;
    }
    if (password.length < 6) {
      Alert.alert('비밀번호 오류', '비밀번호는 6자 이상이어야 합니다.');
      return;
    }
    setLoading(true);
    try {
      await signUpWithEmail(email.trim(), password, displayName.trim());
      router.replace('/tabs/home');
    } catch (e: any) {
      const msg =
        e.code === 'auth/email-already-in-use'
          ? '이미 사용 중인 이메일입니다.'
          : e.code === 'auth/invalid-email'
          ? '올바른 이메일 형식이 아닙니다.'
          : '회원가입에 실패했습니다. 다시 시도해주세요.';
      Alert.alert('회원가입 실패', msg);
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
          <Text style={styles.title}>회원가입</Text>
          <Text style={styles.subtitle}>밀리터리트래커에 오신 것을 환영합니다</Text>
        </View>

        <View style={styles.form}>
          <TextInput
            style={styles.input}
            placeholder="닉네임"
            placeholderTextColor={Colors.textMuted}
            value={displayName}
            onChangeText={setDisplayName}
            maxLength={20}
          />
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
            placeholder="비밀번호 (6자 이상)"
            placeholderTextColor={Colors.textMuted}
            value={password}
            onChangeText={setPassword}
            secureTextEntry
          />
          <TextInput
            style={styles.input}
            placeholder="비밀번호 확인"
            placeholderTextColor={Colors.textMuted}
            value={confirmPassword}
            onChangeText={setConfirmPassword}
            secureTextEntry
          />

          <TouchableOpacity
            style={[styles.button, loading && styles.buttonDisabled]}
            onPress={handleSignup}
            disabled={loading}
          >
            {loading ? (
              <ActivityIndicator color={Colors.white} />
            ) : (
              <Text style={styles.buttonText}>가입하기</Text>
            )}
          </TouchableOpacity>

          <View style={styles.footer}>
            <Text style={styles.footerText}>이미 계정이 있으신가요? </Text>
            <Link href="/auth/login" asChild>
              <TouchableOpacity>
                <Text style={styles.link}>로그인</Text>
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
  header: { alignItems: 'center', marginBottom: 36 },
  emoji: { fontSize: 56, marginBottom: 10 },
  title: { fontSize: 26, fontWeight: '800', color: Colors.white },
  subtitle: { fontSize: 13, color: 'rgba(255,255,255,0.7)', marginTop: 6 },
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
    marginBottom: 12,
    backgroundColor: Colors.background,
  },
  button: {
    backgroundColor: Colors.primary,
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: 'center',
    marginTop: 8,
  },
  buttonDisabled: { opacity: 0.6 },
  buttonText: { color: Colors.white, fontSize: 16, fontWeight: '700' },
  footer: { flexDirection: 'row', justifyContent: 'center', alignItems: 'center', marginTop: 20 },
  footerText: { color: Colors.textSecondary, fontSize: 14 },
  link: { color: Colors.primary, fontWeight: '700', fontSize: 14 },
});
