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
import { SafeAreaView } from 'react-native-safe-area-context';
import { Link } from 'expo-router';
import { signUpWithEmail } from '../../src/services/authService';
import { colors } from '../../src/utils/colors';

export default function SignupScreen() {
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
      // _layout.tsx의 onAuthChange가 onboarding 라우팅 처리
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
    <SafeAreaView style={s.root}>
    <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
      <ScrollView contentContainerStyle={s.scroll} keyboardShouldPersistTaps="handled">
        <View style={s.header}>
          <Text style={s.logo}>MILITARYTRACKER</Text>
          <Text style={s.sub}>계정을 만들고 시작하세요</Text>
        </View>

        <View style={s.form}>
          <Text style={s.label}>닉네임</Text>
          <TextInput style={s.input} placeholder="사용할 이름" placeholderTextColor={colors.muted} value={displayName} onChangeText={setDisplayName} maxLength={20} />
          <Text style={s.label}>이메일</Text>
          <TextInput style={s.input} placeholder="email@example.com" placeholderTextColor={colors.muted} value={email} onChangeText={setEmail} keyboardType="email-address" autoCapitalize="none" autoCorrect={false} />
          <Text style={s.label}>비밀번호</Text>
          <TextInput style={s.input} placeholder="6자 이상" placeholderTextColor={colors.muted} value={password} onChangeText={setPassword} secureTextEntry />
          <Text style={s.label}>비밀번호 확인</Text>
          <TextInput style={s.input} placeholder="동일하게 입력" placeholderTextColor={colors.muted} value={confirmPassword} onChangeText={setConfirmPassword} secureTextEntry />

          <TouchableOpacity style={[s.btn, loading && s.btnOff]} onPress={handleSignup} disabled={loading}>
            {loading ? <ActivityIndicator color={colors.bg} /> : <Text style={s.btnTxt}>가입하기</Text>}
          </TouchableOpacity>

          <View style={s.footer}>
            <Text style={s.footerTxt}>이미 계정이 있으신가요? </Text>
            <Link href="/auth/login" asChild>
              <TouchableOpacity>
                <Text style={s.link}>로그인</Text>
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
  header: { alignItems: 'center', marginBottom: 40 },
  logo: { fontSize: 22, fontWeight: '700', color: colors.ink, letterSpacing: 2 },
  sub: { fontSize: 13, color: colors.muted, marginTop: 10 },
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
  btnTxt: { color: colors.bg, fontSize: 15, fontWeight: '700' },
  footer: { flexDirection: 'row', justifyContent: 'center', alignItems: 'center', marginTop: 24 },
  footerTxt: { color: colors.muted, fontSize: 13 },
  link: { color: colors.ink, fontWeight: '700', fontSize: 13 },
});
