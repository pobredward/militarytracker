import {
  View, Text, TextInput, TouchableOpacity, StyleSheet, Alert, ScrollView,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { colors } from '../utils/colors';
import { useAppStore } from '../stores/appStore';
import { useAuthStore } from '../stores/authStore';
import { exById, PART_LABEL } from '../data/exercises';
import { saveWorkoutLog } from '../services/workoutService';
import { useCountdown, useElapsed } from '../hooks/useCountdown';
import { fmtClock } from '../utils/stats';
import ExerciseMedia from './ExerciseMedia';

export default function SessionPlayer() {
  const insets = useSafeAreaInsets();
  const { user } = useAuthStore();
  const {
    session, setVal, toggleSet, addSet, removeSet, goToEx, moveEx,
    stopRest, startRest, finishSession, addLog,
  } = useAppStore();

  const rest = useCountdown(session?.restEndsAt ?? null);
  const elapsed = useElapsed(session?.startedAt ?? null);

  if (!session) return null;

  const cur = session.data[session.exIdx];
  const e = exById(cur.id);
  const isLast = session.exIdx === session.data.length - 1;
  const doneAll = session.data.every((x) => x.sets.every((t) => t.done));
  const completedSets = cur.sets.filter((t) => t.done).length;

  async function handleFinish() {
    if (!user) return;
    const log = finishSession(user.uid);
    if (!log) return;
    try {
      const saved = await saveWorkoutLog(log);
      addLog(saved);
    } catch {
      addLog({ ...log, id: `local-${Date.now()}` });
      Alert.alert('오프라인 저장', '서버 저장에 실패해 기기에만 기록했습니다.');
    }
  }

  function handleClose() {
    Alert.alert('운동 종료', '완료한 세트는 저장됩니다.', [
      { text: '취소', style: 'cancel' },
      { text: '종료', style: 'destructive', onPress: handleFinish },
    ]);
  }

  return (
    <View style={s.root}>
      {/* Header */}
      <View style={[s.header, { paddingTop: insets.top + 12 }]}>
        <TouchableOpacity style={s.closeBtn} onPress={handleClose}>
          <Text style={s.closeTxt}>✕</Text>
        </TouchableOpacity>
        <View style={s.headerCenter}>
          <Text style={s.headerDay}>{session.dayName}</Text>
          <Text style={s.headerProgress}>
            {session.exIdx + 1} / {session.data.length} · {fmtClock(elapsed)}
          </Text>
        </View>
        <View style={s.headerRight}>
          {rest > 0 ? (
            <Text style={s.restTimer}>{fmtClock(rest)}</Text>
          ) : (
            <Text style={s.setsProgress}>{completedSets}/{cur.sets.length}</Text>
          )}
        </View>
      </View>

      {/* Media */}
      <View style={s.mediaArea}>
        <ExerciseMedia
          exId={cur.id}
          autoPlay
          rounded={24}
          dim={0.25}
          style={s.media}
        />
        <View style={s.mediaMeta}>
          <Text style={s.exName}>{e?.n ?? ''}</Text>
          <Text style={s.exPart}>
            {e ? `${PART_LABEL[e.part]} · ${e.g} · 권장 ${e.r}` : ''}
          </Text>
        </View>
      </View>

      {/* Filmstrip */}
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        style={s.filmScroll}
        contentContainerStyle={s.filmContent}
      >
        {session.data.map((ex, i) => {
          const info = exById(ex.id);
          const done = ex.sets.every((t) => t.done);
          const active = i === session.exIdx;
          return (
            <TouchableOpacity
              key={`${ex.id}-${i}`}
              style={[s.filmCell, active && s.filmCellActive, done && s.filmCellDone]}
              onPress={() => goToEx(i)}
            >
              <Text style={[s.filmNum, active && s.filmNumActive]}>{i + 1}</Text>
              <Text style={[s.filmName, active && s.filmNameActive]} numberOfLines={2}>
                {info?.n ?? ''}
              </Text>
              {done && <Text style={s.filmCheck}>✓</Text>}
            </TouchableOpacity>
          );
        })}
      </ScrollView>

      {/* Bottom sheet */}
      <View style={s.sheet}>
        <View style={s.grab} />

        {rest > 0 && (
          <View style={s.restBox}>
            <Text style={s.restLabel}>휴식</Text>
            <Text style={s.restTime}>{fmtClock(rest)}</Text>
            <View style={s.restBtns}>
              <TouchableOpacity style={s.skipBtn} onPress={() => startRest(rest + 30)}>
                <Text style={s.skipTxt}>+30초</Text>
              </TouchableOpacity>
              <TouchableOpacity style={s.skipBtn} onPress={stopRest}>
                <Text style={s.skipTxt}>건너뛰기</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}

        <ScrollView style={s.setsScroll} contentContainerStyle={s.setsContainer}>
          {cur.sets.map((st, si) => (
            <View key={si} style={[s.setRow, st.done && s.setRowDone]}>
              <Text style={s.setNum}>{si + 1}</Text>
              <TextInput
                style={[s.setInput, st.done && s.setInputDone]}
                placeholder="kg"
                placeholderTextColor={colors.muted}
                keyboardType="decimal-pad"
                value={st.w}
                onChangeText={(v) => setVal(si, 'w', v)}
              />
              <Text style={s.setX}>×</Text>
              <TextInput
                style={[s.setInput, st.done && s.setInputDone]}
                placeholder="회"
                placeholderTextColor={colors.muted}
                keyboardType="numeric"
                value={st.r}
                onChangeText={(v) => setVal(si, 'r', v)}
              />
              <TouchableOpacity
                style={[s.ck, st.done && s.ckDone]}
                onPress={() => toggleSet(si)}
                onLongPress={() => removeSet(si)}
              >
                <Text style={[s.ckTxt, st.done && s.ckTxtDone]}>{st.done ? '✓' : '○'}</Text>
              </TouchableOpacity>
            </View>
          ))}
          <TouchableOpacity style={s.addSet} onPress={addSet}>
            <Text style={s.addSetTxt}>+ 세트 추가</Text>
          </TouchableOpacity>
        </ScrollView>

        <View style={s.navRow}>
          <TouchableOpacity
            style={[s.navBtn, s.navGhost, session.exIdx === 0 && s.navOff]}
            disabled={session.exIdx === 0}
            onPress={() => moveEx(-1)}
          >
            <Text style={s.navGhostTxt}>← 이전</Text>
          </TouchableOpacity>
          {isLast ? (
            <TouchableOpacity style={[s.navBtn, s.navSolid]} onPress={handleFinish}>
              <Text style={s.navSolidTxt}>{doneAll ? '운동 완료 ✓' : '저장하고 종료'}</Text>
            </TouchableOpacity>
          ) : (
            <TouchableOpacity style={[s.navBtn, s.navSolid]} onPress={() => moveEx(1)}>
              <Text style={s.navSolidTxt}>다음 →</Text>
            </TouchableOpacity>
          )}
        </View>
      </View>
    </View>
  );
}

const s = StyleSheet.create({
  root: {
    position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
    backgroundColor: '#0E0E10', zIndex: 40, flexDirection: 'column',
  },
  header: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingHorizontal: 16, paddingBottom: 12,
  },
  closeBtn: {
    width: 36, height: 36, borderRadius: 18,
    backgroundColor: colors.panel2, alignItems: 'center', justifyContent: 'center',
  },
  closeTxt: { fontSize: 16, color: colors.mid },
  headerCenter: { alignItems: 'center', flex: 1 },
  headerDay: { fontSize: 13, fontWeight: '700', color: colors.ink },
  headerProgress: { fontSize: 11, color: colors.muted, marginTop: 2 },
  headerRight: { width: 62, alignItems: 'flex-end' },
  restTimer: { fontSize: 18, fontWeight: '800', color: colors.ink },
  setsProgress: { fontSize: 14, fontWeight: '700', color: colors.mid },

  mediaArea: { flex: 1, paddingHorizontal: 20, justifyContent: 'center', gap: 14 },
  media: { width: '100%', aspectRatio: 1, maxHeight: 300, alignSelf: 'center' },
  mediaMeta: { alignItems: 'center' },
  exName: { fontSize: 22, fontWeight: '800', color: colors.ink, textAlign: 'center', letterSpacing: -0.3 },
  exPart: { fontSize: 12, color: colors.muted, marginTop: 4, textAlign: 'center' },

  filmScroll: { flexGrow: 0 },
  filmContent: { paddingHorizontal: 16, paddingVertical: 10, gap: 8 },
  filmCell: {
    width: 80, borderRadius: 12, padding: 10,
    backgroundColor: colors.panel2, borderWidth: 1, borderColor: colors.line,
    alignItems: 'center',
  },
  filmCellActive: { borderColor: colors.ink, backgroundColor: colors.panel3 },
  filmCellDone: { opacity: 0.5 },
  filmNum: { fontSize: 9.5, fontWeight: '700', color: colors.muted, letterSpacing: 0.5, marginBottom: 4 },
  filmNumActive: { color: colors.ink },
  filmName: { fontSize: 10, color: colors.muted, textAlign: 'center', lineHeight: 13 },
  filmNameActive: { color: colors.ink },
  filmCheck: { fontSize: 11, color: colors.mid, marginTop: 4 },

  sheet: {
    backgroundColor: colors.panel, borderTopWidth: 1, borderTopColor: colors.line2,
    borderTopLeftRadius: 24, borderTopRightRadius: 24,
    paddingHorizontal: 16, paddingTop: 8, paddingBottom: 34, maxHeight: '52%',
  },
  grab: {
    width: 40, height: 4, borderRadius: 2,
    backgroundColor: colors.line2, alignSelf: 'center', marginBottom: 12,
  },
  restBox: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    backgroundColor: colors.panel2, borderWidth: 1, borderColor: colors.line2,
    borderRadius: 14, paddingHorizontal: 16, paddingVertical: 12, marginBottom: 12,
  },
  restLabel: { fontSize: 12, color: colors.muted },
  restTime: { fontSize: 24, fontWeight: '800', color: colors.ink },
  restBtns: { flexDirection: 'row', gap: 6 },
  skipBtn: {
    borderWidth: 1, borderColor: colors.line2, borderRadius: 20,
    paddingHorizontal: 11, paddingVertical: 6,
  },
  skipTxt: { fontSize: 11.5, color: colors.mid },

  setsScroll: { flexGrow: 0 },
  setsContainer: { gap: 8, paddingBottom: 8 },
  setRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  setRowDone: { opacity: 0.45 },
  setNum: { fontSize: 11, color: colors.muted, width: 16, textAlign: 'right', flexShrink: 0 },
  setInput: {
    flex: 1, backgroundColor: colors.panel2,
    borderWidth: 1, borderColor: colors.line2,
    borderRadius: 10, paddingHorizontal: 8, paddingVertical: 10,
    fontSize: 16, color: colors.ink, textAlign: 'center', fontWeight: '600',
  },
  setInputDone: { borderColor: colors.line, color: colors.muted },
  setX: { fontSize: 12, color: colors.muted },
  ck: {
    width: 44, height: 44, borderRadius: 10,
    borderWidth: 1, borderColor: colors.line2,
    backgroundColor: colors.panel3,
    alignItems: 'center', justifyContent: 'center',
  },
  ckDone: { backgroundColor: colors.ink, borderColor: colors.ink },
  ckTxt: { fontSize: 16, color: colors.muted },
  ckTxtDone: { color: colors.bg, fontWeight: '700' },
  addSet: { paddingVertical: 10, alignItems: 'center' },
  addSetTxt: { fontSize: 12.5, color: colors.muted, fontWeight: '600' },

  navRow: { flexDirection: 'row', gap: 10, marginTop: 4 },
  navBtn: { flex: 1, borderRadius: 14, paddingVertical: 14, alignItems: 'center' },
  navGhost: { borderWidth: 1, borderColor: colors.line2 },
  navGhostTxt: { color: colors.mid, fontSize: 14, fontWeight: '700' },
  navSolid: { backgroundColor: colors.ink },
  navSolidTxt: { color: colors.bg, fontSize: 14, fontWeight: '700' },
  navOff: { opacity: 0.3 },
});
