import { useEffect, useState } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, StyleSheet, KeyboardAvoidingView, Platform,
} from 'react-native';
import { useRouter } from 'expo-router';
import { colors } from '../../src/utils/colors';
import { showAlert } from '../../src/utils/alert';
import { Screen, TopBar, Body, SectionLabel, PrimaryBtn, EmptyState } from '../../src/components/ui';
import { useAppStore } from '../../src/stores/appStore';
import { useAuthStore } from '../../src/stores/authStore';
import { saveProfile } from '../../src/services/authService';
import { calcBodyStats, effectiveWeight } from '../../src/utils/body';
import { UserProfile } from '../../src/types';

export default function ProfileEditScreen() {
  const router = useRouter();
  const { user, patchUser } = useAuthStore();
  const { profile, weights, setProfile } = useAppStore();
  const [p, setP] = useState<UserProfile | null>(profile);
  const [saving, setSaving] = useState(false);

  // 하이드레이션이 늦게 끝나면 마운트 시점에는 profile 이 없다
  useEffect(() => {
    if (profile && !p) setP(profile);
  }, [profile]);

  if (!p) {
    return (
      <Screen>
        <TopBar title="내 정보" onBack={() => router.back()} />
        <EmptyState text={'신체 정보를 불러오지 못했습니다.\n잠시 후 다시 시도해주세요.'} />
      </Screen>
    );
  }

  const update = <K extends keyof UserProfile>(k: K, v: UserProfile[K]) =>
    setP((prev) => (prev ? { ...prev, [k]: v } : prev));

  const st = calcBodyStats(p, weights);
  const eff = effectiveWeight(p, weights);
  const changed = JSON.stringify(p) !== JSON.stringify(profile);
  const valid = !!(p.age && p.height && p.weight);

  async function handleSave() {
    if (!user || !p || !valid) return;
    setSaving(true);
    try {
      await saveProfile(user.uid, p);
      setProfile(p);
      patchUser({ profile: p });
      showAlert('저장 완료', '변경한 정보가 반영되었습니다.', [
        { text: '확인', onPress: () => router.back() },
      ]);
    } catch {
      showAlert('오류', '저장에 실패했습니다. 잠시 후 다시 시도해주세요.');
    } finally {
      setSaving(false);
    }
  }

  return (
    <Screen>
      <TopBar title="내 정보" meta="PROFILE" onBack={() => router.back()} />
      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <Body>
          <SectionLabel>신체 정보</SectionLabel>
          <View style={s.grid2}>
            <Opt label="남성" on={p.sex === 'male'} onPress={() => update('sex', 'male')} />
            <Opt label="여성" on={p.sex === 'female'} onPress={() => update('sex', 'female')} />
          </View>

          <View style={s.grid3}>
            <Field label="나이" value={p.age} onChange={(v) => update('age', v)} kb="numeric" />
            <Field label="키 (cm)" value={p.height} onChange={(v) => update('height', v)} kb="decimal-pad" />
            <Field label="몸무게 (kg)" value={p.weight} onChange={(v) => update('weight', v)} kb="decimal-pad" />
          </View>

          {st && (
            <View style={s.calcBox}>
              <Text style={s.calcTxt}>
                BMI {st.bmi} · {st.bodyType} · 목표 {st.kcal}kcal · 단백질 {st.protein}g
              </Text>
              <Text style={s.calcSub}>
                {eff?.src === 'trend'
                  ? `최근 체중 기록의 추세값 ${eff.trend}kg 으로 계산했습니다. 위 몸무게는 기준값입니다.`
                  : '저장하면 식단 목표치가 이 값으로 갱신됩니다.'}
              </Text>
            </View>
          )}

          <SectionLabel>목표</SectionLabel>
          <Opt label="근성장" sub="점진적 과부하 · 증량 식단" on={p.goal === 'muscle'} onPress={() => update('goal', 'muscle')} />
          <Opt label="체지방 감량" sub="볼륨 유지 · 감량 식단" on={p.goal === 'cut'} onPress={() => update('goal', 'cut')} />
          <Opt label="운동 습관 만들기" sub="짧은 루틴 · 꾸준함 우선" on={p.goal === 'habit'} onPress={() => update('goal', 'habit')} />

          <SectionLabel>운동 환경</SectionLabel>
          <View style={s.grid2}>
            <Opt label="헬스장" on={p.env === 'gym'} onPress={() => update('env', 'gym')} />
            <Opt label="홈트레이닝" on={p.env === 'home'} onPress={() => update('env', 'home')} />
          </View>

          <Text style={s.label}>주당 운동 일수</Text>
          <View style={s.chipRow}>
            {([2, 3, 4, 5, 6] as const).map((d) => (
              <TouchableOpacity key={d} style={[s.chip, p.days === d && s.chipOn]} onPress={() => update('days', d)}>
                <Text style={[s.chipTxt, p.days === d && s.chipOnTxt]}>주 {d}일</Text>
              </TouchableOpacity>
            ))}
          </View>

          <Text style={s.label}>운동 경력</Text>
          <View style={s.chipRow}>
            {([1, 2, 3] as const).map((lv) => (
              <TouchableOpacity key={lv} style={[s.chip, p.level === lv && s.chipOn]} onPress={() => update('level', lv)}>
                <Text style={[s.chipTxt, p.level === lv && s.chipOnTxt]}>
                  {{ 1: '입문', 2: '중급', 3: '상급' }[lv]}
                </Text>
              </TouchableOpacity>
            ))}
          </View>

          <SectionLabel>식사 환경</SectionLabel>
          <View style={s.chipRow}>
            {([
              ['convenience', '편의점'], ['self', '자취 요리'],
              ['family', '집밥'], ['out', '외식'],
            ] as const).map(([k, label]) => (
              <TouchableOpacity key={k} style={[s.chip, p.food === k && s.chipOn]} onPress={() => update('food', k)}>
                <Text style={[s.chipTxt, p.food === k && s.chipOnTxt]}>{label}</Text>
              </TouchableOpacity>
            ))}
          </View>

          <Text style={s.label}>알레르기 · 제외할 음식</Text>
          <TextInput
            style={s.input}
            placeholder="예: 유제품, 갑각류"
            placeholderTextColor={colors.muted}
            value={p.allergy}
            onChangeText={(v) => update('allergy', v)}
          />

          <PrimaryBtn
            label={changed ? '변경사항 저장' : '변경사항 없음'}
            onPress={handleSave}
            loading={saving}
            disabled={!changed || !valid}
            style={{ marginTop: 22 }}
          />
          <Text style={s.hint}>
            운동 플랜은 자동으로 바뀌지 않습니다. 새 조건에 맞추려면 운동 탭에서 다시 구성하세요.
          </Text>
        </Body>
      </KeyboardAvoidingView>
    </Screen>
  );
}

function Field({
  label, value, onChange, kb,
}: { label: string; value: string; onChange: (v: string) => void; kb: 'numeric' | 'decimal-pad' }) {
  return (
    <View style={{ flex: 1 }}>
      <Text style={s.label}>{label}</Text>
      <TextInput
        style={s.input}
        value={value}
        onChangeText={onChange}
        keyboardType={kb}
        placeholderTextColor={colors.muted}
      />
    </View>
  );
}

function Opt({ label, sub, on, onPress }: { label: string; sub?: string; on: boolean; onPress: () => void }) {
  return (
    <TouchableOpacity style={[s.opt, on && s.optOn]} onPress={onPress}>
      <View style={{ flex: 1 }}>
        <Text style={[s.optTxt, on && s.optTxtOn]}>{label}</Text>
        {sub ? <Text style={s.optSub}>{sub}</Text> : null}
      </View>
      <Text style={[s.optDot, on && s.optDotOn]}>{on ? '●' : '○'}</Text>
    </TouchableOpacity>
  );
}

const s = StyleSheet.create({
  label: { fontSize: 12, color: colors.muted, marginTop: 14, marginBottom: 6 },
  input: {
    backgroundColor: colors.panel2, borderWidth: 1, borderColor: colors.line2,
    borderRadius: 10, paddingHorizontal: 14, paddingVertical: 12, fontSize: 15, color: colors.ink,
  },
  grid2: { flexDirection: 'row', gap: 9 },
  grid3: { flexDirection: 'row', gap: 9 },
  opt: {
    flexDirection: 'row', alignItems: 'center', borderWidth: 1, borderColor: colors.line2,
    borderRadius: 10, padding: 14, marginBottom: 9, flex: 1,
  },
  optOn: { borderColor: colors.ink, backgroundColor: colors.panel2 },
  optTxt: { fontSize: 14.5, color: colors.mid },
  optTxtOn: { color: colors.ink, fontWeight: '600' },
  optSub: { fontSize: 11.5, color: colors.muted, marginTop: 2 },
  optDot: { fontSize: 14, color: colors.muted },
  optDotOn: { color: colors.ink },
  chipRow: { flexDirection: 'row', gap: 7, flexWrap: 'wrap' },
  chip: {
    borderWidth: 1, borderColor: colors.line2, borderRadius: 20,
    paddingVertical: 8, paddingHorizontal: 14,
  },
  chipOn: { backgroundColor: colors.ink, borderColor: colors.ink },
  chipTxt: { fontSize: 13, color: colors.mid },
  chipOnTxt: { color: colors.bg, fontWeight: '600' },
  calcBox: {
    backgroundColor: colors.panel2, borderRadius: 12, padding: 14,
    borderWidth: 1, borderColor: colors.line2, marginTop: 14,
  },
  calcTxt: { fontSize: 13, color: colors.ink, fontWeight: '600' },
  calcSub: { fontSize: 11, color: colors.muted, marginTop: 5 },
  hint: { fontSize: 11.5, color: colors.muted, lineHeight: 18, textAlign: 'center', marginTop: 12 },
});
