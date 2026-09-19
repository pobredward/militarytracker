import { useRef, useState } from 'react';
import {
  View, Text, ScrollView, TouchableOpacity, StyleSheet,
  TextInput, } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { colors } from '../../src/utils/colors';
import { showAlert } from '../../src/utils/alert';
import { useAppStore } from '../../src/stores/appStore';
import { useAuthStore } from '../../src/stores/authStore';
import { PART_LABEL, PART_ORDER, exById } from '../../src/data/exercises';
import { saveWeight } from '../../src/services/workoutService';
import { logout, deleteAccount, saveProfile } from '../../src/services/authService';
import { askCoach, AIUnavailable } from '../../src/services/aiService';
import { calcBodyStats, effectiveWeight, GOAL_LABEL } from '../../src/utils/body';
import { setsByPart, weakestPart, totalSets, totalVolume, currentStreakDays, fmtDuration, fmtVolume } from '../../src/utils/stats';

export default function MyScreen() {
  const router = useRouter();
  const { user, patchUser } = useAuthStore();
  const {
    profile, plan, logs, weights, chat, chatBusy,
    addChat, setChatBusy, addWeight, resetAll, setProfile,
  } = useAppStore();
  const [weightInput, setWeightInput] = useState('');
  const [chatInput, setChatInput] = useState('');
  const scrollRef = useRef<ScrollView>(null);

  const st = calcBodyStats(profile, weights);
  const eff = effectiveWeight(profile, weights);
  const vol = setsByPart(logs, { weekOnly: true });
  const maxVol = Math.max(4, ...PART_ORDER.map((p) => vol[p]));
  const weakest = weakestPart(vol);
  const weekSets = totalSets(logs, { weekOnly: true });
  const weekVolume = totalVolume(logs, { weekOnly: true });
  const streakDays = currentStreakDays(logs);
  const avgDuration = logs.length
    ? Math.round(logs.reduce((a, l) => a + l.durationSec, 0) / logs.length)
    : 0;

  async function handleSaveWeight() {
    const kg = parseFloat(weightInput);
    if (!user) return;
    if (!kg || kg <= 0 || kg > 400) {
      showAlert('입력 확인', '체중을 숫자로 입력해주세요. (예: 72.5)');
      return;
    }
    try {
      addWeight(await saveWeight(user.uid, kg));
      setWeightInput('');
    } catch {
      showAlert('오류', '체중 저장에 실패했습니다.');
    }
  }

  async function applyTrendWeight() {
    if (!user || !profile || !eff?.trend) return;
    const next = { ...profile, weight: String(eff.trend) };
    try {
      await saveProfile(user.uid, next);
      setProfile(next);
      patchUser({ profile: next });
      showAlert('기준 체중 갱신', `${eff.trend}kg 로 갱신했습니다.`);
    } catch {
      showAlert('오류', '저장에 실패했습니다.');
    }
  }

  function coachContext(): string {
    const planTxt = plan
      ? plan.days.map((d) => `${d.name}: ${d.ids.map((id) => exById(id)?.n ?? '').join(', ')}`).join(' / ')
      : '없음';
    const logTxt = logs.length
      ? logs.slice(0, 3).map((l) => `${l.date} ${l.dayName} ${l.totalSets}세트`).join('; ')
      : '기록 없음';
    const body = st
      ? `BMI ${st.bmi} (${st.bodyType}), 목표 칼로리 ${st.kcal}kcal, 단백질 ${st.protein}g`
      : '신체 정보 없음';
    return [
      `사용자: ${profile?.sex === 'male' ? '남' : '여'} ${profile?.age ?? '-'}세, ${profile?.height ?? '-'}cm/${profile?.weight ?? '-'}kg, ${body}`,
      `목표: ${profile ? GOAL_LABEL[profile.goal] : '-'}`,
      `현재 플랜: ${planTxt}`,
      `최근 기록: ${logTxt}`,
      `이번 주 부위별 세트: ${PART_ORDER.map((p) => `${PART_LABEL[p]} ${vol[p]}`).join(', ')}`,
    ].join('\n');
  }

  async function handleChat() {
    if (!chatInput.trim() || chatBusy) return;
    const text = chatInput.trim();
    setChatInput('');
    addChat({ role: 'user', content: text });
    setChatBusy(true);
    try {
      const reply = await askCoach([...chat, { role: 'user', content: text }], coachContext());
      addChat({ role: 'assistant', content: reply });
    } catch (e) {
      addChat({
        role: 'assistant',
        content: e instanceof AIUnavailable
          ? 'AI 코치 서버에 연결하지 못했습니다. 잠시 후 다시 시도해주세요.'
          : '오류가 발생했습니다. 다시 시도해주세요.',
      });
    } finally {
      setChatBusy(false);
      setTimeout(() => scrollRef.current?.scrollToEnd({ animated: true }), 100);
    }
  }

  async function handleLogout() {
    await logout();
    resetAll();
    router.replace('/auth/login');
  }

  function confirmDelete() {
    showAlert(
      '계정 삭제',
      '운동 기록·체중·플랜이 모두 삭제되며 되돌릴 수 없습니다. 진행할까요?',
      [
        { text: '취소', style: 'cancel' },
        {
          text: '삭제',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteAccount();
              resetAll();
              router.replace('/auth/login');
            } catch (e) {
              const code = (e as { code?: string })?.code;
              showAlert(
                '삭제 실패',
                code === 'auth/requires-recent-login'
                  ? '보안을 위해 다시 로그인한 뒤 삭제해주세요.'
                  : '계정 삭제에 실패했습니다. 잠시 후 다시 시도해주세요.'
              );
            }
          },
        },
      ]
    );
  }

  return (
    <SafeAreaView style={s.root} edges={['top']}>
      <View style={s.topbar}>
        <Text style={s.title}>MY</Text>
        <Text style={s.meta}>{user?.role === 'admin' ? 'ADMIN' : 'REPORT · COACH'}</Text>
      </View>

      <ScrollView ref={scrollRef} style={s.scroll} contentContainerStyle={s.scrollInner} showsVerticalScrollIndicator={false}>
        {/* Summary */}
        <View style={s.summaryRow}>
          <Summary value={`${weekSets}`} label="이번 주 세트" />
          <Summary value={fmtVolume(weekVolume)} label="주간 볼륨" />
          <Summary value={`${streakDays}일`} label="연속 기록" />
        </View>

        {/* 빠른 진입 */}
        <View style={s.menuRow}>
          <TouchableOpacity style={s.menuBtn} onPress={() => router.push('/history')}>
            <Text style={s.menuTitle}>운동 기록</Text>
            <Text style={s.menuSub}>{logs.length}회 누적</Text>
          </TouchableOpacity>
          <TouchableOpacity style={s.menuBtn} onPress={() => router.push('/profile/edit')}>
            <Text style={s.menuTitle}>내 정보</Text>
            <Text style={s.menuSub}>
              {profile ? `${profile.height}cm · ${profile.weight}kg` : '설정 필요'}
            </Text>
          </TouchableOpacity>
        </View>

        {/* Volume chart */}
        <Text style={s.sectionLabel}>주간 부위별 세트 수</Text>
        <View style={s.card}>
          {weekSets > 0 ? (
            <>
              <View style={s.barsRow}>
                {PART_ORDER.map((p) => {
                  const val = vol[p];
                  const heightPct = Math.max(Math.round((val / maxVol) * 100), 3);
                  const isTop = val === maxVol && val > 0;
                  return (
                    <View key={p} style={s.barCol}>
                      {val > 0 && <Text style={s.barValTxt}>{val}</Text>}
                      <View style={s.barTrack}>
                        <View style={[s.barFill, { height: `${heightPct}%` }, isTop && s.barFillHi]} />
                      </View>
                      <Text style={s.barLabel}>{PART_LABEL[p]}</Text>
                    </View>
                  );
                })}
              </View>
              {weakest && (
                <View style={s.weakRow}>
                  <Text style={s.weakTxt}>
                    <Text style={s.weakPart}>{PART_LABEL[weakest]}</Text> 볼륨이 가장 적습니다. 다음 주 1종목 추가를 권장합니다.
                  </Text>
                </View>
              )}
              {avgDuration > 0 && (
                <Text style={s.subMeta}>평균 운동 시간 {fmtDuration(avgDuration)}</Text>
              )}
            </>
          ) : (
            <Text style={s.emptyTxt}>이번 주 운동을 완료하면 부위별 볼륨이 집계됩니다.</Text>
          )}
        </View>

        {/* Weight */}
        <Text style={s.sectionLabel}>체중 기록</Text>
        <View style={s.card}>
          {weights.length ? (
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={s.weightHistory}>
              {weights.slice(0, 10).reverse().map((w, i) => (
                <View key={w.id ?? i} style={s.weightChip}>
                  <Text style={s.weightChipDate}>{w.date.slice(5)}</Text>
                  <Text style={s.weightChipVal}>{w.kg}<Text style={s.weightChipUnit}>kg</Text></Text>
                </View>
              ))}
            </ScrollView>
          ) : (
            <Text style={s.emptyTxt}>아직 기록이 없습니다.</Text>
          )}
          {eff?.trend != null && (
            <View style={s.trendRow}>
              <Text style={s.trendTxt}>
                최근 추세 <Text style={s.trendHi}>{eff.trend}kg</Text>
                {'  ·  '}기준 {eff.baseline}kg
                {eff.drift !== 0 ? `  (${eff.drift > 0 ? '+' : ''}${eff.drift})` : ''}
              </Text>
              {eff.shouldUpdate && (
                <TouchableOpacity style={s.trendBtn} onPress={applyTrendWeight}>
                  <Text style={s.trendBtnTxt}>기준 갱신</Text>
                </TouchableOpacity>
              )}
            </View>
          )}
          <View style={s.weightRow}>
            <TextInput
              style={s.weightInput}
              placeholder="오늘 체중 (kg)"
              placeholderTextColor={colors.muted}
              keyboardType="decimal-pad"
              value={weightInput}
              onChangeText={setWeightInput}
            />
            <TouchableOpacity style={s.weightBtn} onPress={handleSaveWeight}>
              <Text style={s.weightBtnTxt}>기록</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* AI Coach */}
        <Text style={s.sectionLabel}>AI 코치</Text>
        <View style={s.card}>
          <View style={s.chatBox}>
            {chat.length === 0 && (
              <View style={s.msgA}>
                <Text style={s.msgATxt}>
                  안녕하세요, AI 코치입니다.{'\n'}루틴 조정, 대체 운동, 식단 등 무엇이든 물어보세요.
                </Text>
              </View>
            )}
            {chat.map((m, i) =>
              m.role === 'user' ? (
                <View key={i} style={s.msgU}><Text style={s.msgUTxt}>{m.content}</Text></View>
              ) : (
                <View key={i} style={s.msgA}><Text style={s.msgATxt}>{m.content}</Text></View>
              )
            )}
            {chatBusy && <View style={s.msgA}><Text style={s.msgATxt}>…</Text></View>}
          </View>
          <View style={s.chatInRow}>
            <TextInput
              style={s.chatInput}
              placeholder="코치에게 질문하기"
              placeholderTextColor={colors.muted}
              value={chatInput}
              onChangeText={setChatInput}
              onSubmitEditing={handleChat}
              returnKeyType="send"
            />
            <TouchableOpacity style={s.chatSend} onPress={handleChat}>
              <Text style={s.chatSendTxt}>↑</Text>
            </TouchableOpacity>
          </View>
        </View>

        <Text style={s.notice}>통증·부상·질환 관련 판단은 의료 전문가와 상의하세요.</Text>

        <TouchableOpacity style={s.logoutBtn} onPress={handleLogout}>
          <Text style={s.logoutTxt}>로그아웃</Text>
        </TouchableOpacity>
        <TouchableOpacity style={s.deleteBtn} onPress={confirmDelete}>
          <Text style={s.deleteTxt}>계정 삭제</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

function Summary({ value, label }: { value: string; label: string }) {
  return (
    <View style={s.summary}>
      <Text style={s.summaryVal}>{value}</Text>
      <Text style={s.summaryLabel}>{label}</Text>
    </View>
  );
}

const s = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.bg },
  topbar: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
    paddingHorizontal: 20, paddingTop: 14, paddingBottom: 8,
  },
  title: { fontSize: 22, fontWeight: '800', color: colors.ink, letterSpacing: -0.3 },
  meta: { fontSize: 10, color: colors.muted, letterSpacing: 1 },
  scroll: { flex: 1 },
  scrollInner: { paddingHorizontal: 16, paddingBottom: 36 },

  summaryRow: { flexDirection: 'row', gap: 8, marginTop: 8 },
  menuRow: { flexDirection: 'row', gap: 8, marginTop: 10 },
  menuBtn: {
    flex: 1, backgroundColor: colors.panel, borderRadius: 14, padding: 14,
    borderWidth: 1, borderColor: colors.line,
  },
  menuTitle: { fontSize: 14, fontWeight: '700', color: colors.ink },
  menuSub: { fontSize: 10.5, color: colors.muted, marginTop: 4 },
  summary: {
    flex: 1, backgroundColor: colors.panel2, borderRadius: 14, padding: 14,
    borderWidth: 1, borderColor: colors.line2,
  },
  summaryVal: { fontSize: 18, fontWeight: '800', color: colors.ink },
  summaryLabel: { fontSize: 10, color: colors.muted, marginTop: 4 },

  sectionLabel: {
    fontSize: 9.5, fontWeight: '800', color: colors.muted,
    letterSpacing: 2, marginBottom: 10, marginTop: 18,
  },
  card: {
    backgroundColor: colors.panel, borderRadius: 18, padding: 18,
    borderWidth: 1, borderColor: colors.line, marginBottom: 4,
  },
  emptyTxt: { color: colors.muted, fontSize: 13, lineHeight: 20 },

  barsRow: { flexDirection: 'row', gap: 6, height: 104, alignItems: 'flex-end', marginBottom: 14 },
  barCol: { flex: 1, alignItems: 'center' },
  barValTxt: { fontSize: 8.5, color: colors.muted, marginBottom: 3 },
  barTrack: { width: '100%', height: 80, justifyContent: 'flex-end' },
  barFill: { width: '100%', backgroundColor: colors.panel3, borderRadius: 4 },
  barFillHi: { backgroundColor: colors.mid },
  barLabel: { fontSize: 9, color: colors.muted, marginTop: 5, textAlign: 'center' },
  weakRow: { borderTopWidth: 1, borderTopColor: colors.line, paddingTop: 12 },
  weakTxt: { fontSize: 12.5, color: colors.mid, lineHeight: 18 },
  weakPart: { color: colors.ink, fontWeight: '700' },
  subMeta: { fontSize: 11, color: colors.muted, marginTop: 10 },

  weightHistory: { marginBottom: 14 },
  weightChip: {
    backgroundColor: colors.panel2, borderRadius: 12,
    paddingHorizontal: 12, paddingVertical: 10,
    marginRight: 8, alignItems: 'center',
    borderWidth: 1, borderColor: colors.line,
  },
  weightChipDate: { fontSize: 10, color: colors.muted, marginBottom: 3 },
  weightChipVal: { fontSize: 16, fontWeight: '700', color: colors.ink },
  weightChipUnit: { fontSize: 11, fontWeight: '400', color: colors.mid },
  weightRow: { flexDirection: 'row', gap: 8 },
  trendRow: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    gap: 10, marginBottom: 12,
  },
  trendTxt: { fontSize: 11.5, color: colors.muted, flex: 1 },
  trendHi: { color: colors.ink, fontWeight: '700' },
  trendBtn: {
    backgroundColor: colors.panel3, borderRadius: 8,
    paddingHorizontal: 10, paddingVertical: 6,
    borderWidth: 1, borderColor: colors.line2,
  },
  trendBtnTxt: { fontSize: 11, color: colors.ink, fontWeight: '700' },
  weightInput: {
    flex: 1, backgroundColor: colors.panel2,
    borderWidth: 1, borderColor: colors.line2,
    borderRadius: 12, paddingHorizontal: 14, paddingVertical: 11,
    fontSize: 14, color: colors.ink,
  },
  weightBtn: {
    backgroundColor: colors.ink, borderRadius: 12,
    paddingHorizontal: 18, paddingVertical: 11, alignItems: 'center',
  },
  weightBtnTxt: { color: colors.bg, fontSize: 13, fontWeight: '700' },

  chatBox: { gap: 10, marginBottom: 12 },
  msgU: {
    alignSelf: 'flex-end', backgroundColor: colors.ink,
    borderRadius: 16, borderBottomRightRadius: 4,
    paddingHorizontal: 14, paddingVertical: 10, maxWidth: '82%',
  },
  msgUTxt: { color: colors.bg, fontSize: 14, fontWeight: '500', lineHeight: 20 },
  msgA: {
    alignSelf: 'flex-start', backgroundColor: colors.panel2,
    borderWidth: 1, borderColor: colors.line,
    borderRadius: 16, borderBottomLeftRadius: 4,
    paddingHorizontal: 14, paddingVertical: 10, maxWidth: '82%',
  },
  msgATxt: { color: colors.ink, fontSize: 14, lineHeight: 22 },
  chatInRow: { flexDirection: 'row', gap: 8 },
  chatInput: {
    flex: 1, backgroundColor: colors.panel2,
    borderWidth: 1, borderColor: colors.line2,
    borderRadius: 12, paddingHorizontal: 14, paddingVertical: 12,
    fontSize: 14, color: colors.ink,
  },
  chatSend: {
    width: 48, backgroundColor: colors.ink,
    borderRadius: 12, alignItems: 'center', justifyContent: 'center',
  },
  chatSendTxt: { color: colors.bg, fontSize: 20, fontWeight: '700' },

  notice: { fontSize: 10.5, color: colors.muted, lineHeight: 16, textAlign: 'center', marginTop: 18, marginBottom: 16 },
  logoutBtn: {
    borderWidth: 1, borderColor: colors.line2,
    borderRadius: 14, paddingVertical: 14, alignItems: 'center',
  },
  logoutTxt: { color: colors.muted, fontSize: 14, fontWeight: '600' },
  deleteBtn: { paddingVertical: 16, alignItems: 'center' },
  deleteTxt: { color: colors.wrong, fontSize: 12.5, fontWeight: '600' },
});
