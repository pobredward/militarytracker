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
  
  ScrollView,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter, Link } from 'expo-router';
import { signInWithEmail, resetPassword } from '../../src/services/authService';
import { colors } from '../../src/utils/colors';
import { showAlert } from '../../src/utils/alert';

export default function LoginScreen() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleLogin() {
    if (!email.trim() || !password.trim()) {
      showAlert('입력 오류', '이메일과 비밀번호를 모두 입력해주세요.');
      return;
    }
    setLoading(true);
    try {
      await signInWithEmail(email.trim(), password);
    } catch (e: any) {
      const msg =
        e.code === 'auth/user-not-found' || e.code === 'auth/wrong-password'
          ? '이메일 또는 비밀번호가 올바르지 않습니다.'
          : e.code === 'auth/invalid-email'
          ? '올바른 이메일 형식이 아닙니다.'
          : '로그인에 실패했습니다. 다시 시도해주세요.';
      showAlert('로그인 실패', msg);
    } finally {
      setLoading(false);
    }
  }

  async function handleReset() {
    const target = email.trim();
    if (!target) {
      showAlert('이메일 입력', '가입하신 이메일을 먼저 입력해주세요.');
      return;
    }
    try {
      await resetPassword(target);
      showAlert('메일 발송', `${target} 으로 비밀번호 재설정 링크를 보냈습니다.\n메일함을 확인해주세요.`);
    } catch (e: any) {
      showAlert(
        '발송 실패',
        e?.code === 'auth/invalid-email'
          ? '올바른 이메일 형식이 아닙니다.'
          : '메일 발송에 실패했습니다. 잠시 후 다시 시도해주세요.'
      );
    }
  }

  return (
    <SafeAreaView style={s.root}>
    <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
      <ScrollView contentContainerStyle={s.scroll} keyboardShouldPersistTaps="handled">
        <View style={s.header}>
          <Text style={s.logo}>MILITARYTRACKER</Text>
          <Text style={s.sub}>검증된 자세 가이드 위에서 기록하는{'\n'}가장 단순한 트레이닝 앱</Text>
        </View>

        <View style={s.form}>
          <Text style={s.label}>이메일</Text>
          <TextInput
            style={s.input}
            placeholder="email@example.com"
            placeholderTextColor={colors.muted}
            value={email}
            onChangeText={setEmail}
            keyboardType="email-address"
            autoCapitalize="none"
            autoCorrect={false}
          />
          <Text style={s.label}>비밀번호</Text>
          <TextInput
            style={s.input}
            placeholder="6자 이상"
            placeholderTextColor={colors.muted}
            value={password}
            onChangeText={setPassword}
            secureTextEntry
          />

          <TouchableOpacity style={[s.btn, loading && s.btnOff]} onPress={handleLogin} disabled={loading}>
            {loading ? <ActivityIndicator color={colors.bg} /> : <Text style={s.btnTxt}>로그인</Text>}
          </TouchableOpacity>

          <TouchableOpacity style={s.resetBtn} onPress={handleReset}>
            <Text style={s.resetTxt}>비밀번호를 잊으셨나요?</Text>
          </TouchableOpacity>

          <View style={s.footer}>
            <Text style={s.footerTxt}>계정이 없으신가요? </Text>
            <Link href="/auth/signup" asChild>
              <TouchableOpacity>
                <Text style={s.link}>회원가입</Text>
              </TouchableOpacity>
            </Link>
          </View>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const s = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.bg },
  scroll: { flexGrow: 1, justifyContent: 'center', padding: 24 },
  header: { alignItems: 'center', marginBottom: 48 },
  logo: { fontSize: 22, fontWeight: '700', color: colors.ink, letterSpacing: 2 },
  sub: { fontSize: 13, color: colors.muted, marginTop: 10, textAlign: 'center', lineHeight: 20 },
  form: {},
  label: { fontSize: 12, color: colors.muted, marginBottom: 6, marginTop: 14 },
  input: {
    backgroundColor: colors.panel2,
    borderWidth: 1,
    borderColor: colors.line2,
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 13,
    fontSize: 15,
    color: colors.ink,
  },
  btn: {
    backgroundColor: colors.ink,
    borderRadius: 10,
    paddingVertical: 15,
    alignItems: 'center',
    marginTop: 24,
  },
  btnOff: { opacity: 0.4 },
  resetBtn: { alignItems: 'center', paddingVertical: 14 },
  resetTxt: { color: colors.muted, fontSize: 12.5 },
  btnTxt: { color: colors.bg, fontSize: 15, fontWeight: '700' },
  footer: { flexDirection: 'row', justifyContent: 'center', alignItems: 'center', marginTop: 24 },
  footerTxt: { color: colors.muted, fontSize: 13 },
  link: { color: colors.ink, fontWeight: '700', fontSize: 13 },
});
