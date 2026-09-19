import { useEffect, useMemo, useRef, useState } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, StyleSheet, ScrollView, FlatList,
  Vibration, Platform, ActivityIndicator,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { colors } from '../utils/colors';
import { showAlert } from '../utils/alert';
import { useAppStore } from '../stores/appStore';
import { useAuthStore } from '../stores/authStore';
import { exById, exFilter, Exercise, PART_LABEL } from '../data/exercises';
import { saveWorkoutLog } from '../services/workoutService';
import { useCountdown, useElapsed } from '../hooks/useCountdown';
import { fmtClock, fmtSetDetail, lastSetsOf, prIdsIn } from '../utils/stats';
import ExerciseMedia from './ExerciseMedia';

export default function SessionPlayer() {
  const insets = useSafeAreaInsets();
  const { user } = useAuthStore();
  const {
    session, profile, logs, setVal, toggleSet, addSet, removeSet, goToEx, moveEx,
    stopRest, startRest, buildLog, closeSession, clearSession, addLog, setSummary,
    swapExercise, appendExercise, queuePending, dropPending,
  } = useAppStore();

  const rest = useCountdown(session?.restEndsAt ?? null);
  const elapsed = useElapsed(session?.startedAt ?? null);
  const [picker, setPicker] = useState<'swap' | 'add' | null>(null);
  const [saving, setSaving] = useState(false);
  const wasResting = useRef(false);

  // 휴식이 끝나는 순간 진동으로 알린다
  useEffect(() => {
    if (rest > 0) {
      wasResting.current = true;
      return;
    }
    if (wasResting.current) {
      wasResting.current = false;
      if (Platform.OS !== 'web') Vibration.vibrate([0, 220, 120, 220]);
    }
  }, [rest]);

  if (!session) return null;

  const cur = session.data[session.exIdx];
  const e = cur ? exById(cur.id) : undefined;
  if (!cur) return null;

  const isLast = session.exIdx === session.data.length - 1;
  const doneAll = session.data.every((x) => x.sets.every((t) => t.done));
  const completedSets = cur.sets.filter((t) => t.done).length;
  const anyRecorded = session.data.some((x) => x.sets.some((t) => t.done));
  const last = lastSetsOf(logs, cur.id);

  async function handleFinish() {
    if (!user || saving) return;
    const log = buildLog(user.uid);
    if (!log) return;

    // 기록이 하나도 없으면 로그를 남기지 않고 그냥 닫는다
    if (log.totalSets === 0) {
      showAlert('운동 취소', '기록된 세트가 없습니다. 이 운동을 저장하지 않고 닫을까요?', [
        { text: '계속하기', style: 'cancel' },
        { text: '저장 없이 닫기', style: 'destructive', onPress: () => clearSession() },
      ]);
      return;
    }

    setSaving(true);
    const prIds = prIdsIn(log, logs);
    let saved = true;
    try {
      addLog(await saveWorkoutLog(log));
    } catch {
      // 서버 저장 실패 — 기기에 보관해두고 다음 실행에서 재시도한다
      saved = false;
      queuePending(log);
      addLog({ ...log, id: `local-${log.createdAt}` });
    }
    setSaving(false);
    closeSession();
    setSummary({
      dayName: log.dayName,
      totalSets: log.totalSets,
      totalVolume: log.totalVolume,
      durationSec: log.durationSec,
      exercises: log.exercises,
      prIds: [...new Set(prIds)],
      saved,
    });
  }

  function handleClose() {
    if (!anyRecorded) {
      showAlert('운동 종료', '기록된 세트가 없습니다. 저장하지 않고 닫을까요?', [
        { text: '계속하기', style: 'cancel' },
        { text: '닫기', style: 'destructive', onPress: () => clearSession() },
      ]);
      return;
    }
    showAlert('운동 종료', '완료한 세트는 저장됩니다.', [
      { text: '취소', style: 'cancel' },
      { text: '종료', style: 'destructive', onPress: handleFinish },
    ]);
  }

  return (
    <View style={s.root}>
      <View style={[s.header, { paddingTop: insets.top + 12 }]}>
        <TouchableOpacity style={s.closeBtn} onPress={handleClose} disabled={saving}>
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

      <View style={s.mediaArea}>
        <ExerciseMedia exId={cur.id} autoPlay rounded={24} dim={0.25} style={s.media} />
        <View style={s.mediaMeta}>
          <Text style={s.exName}>{e?.n ?? ''}</Text>
          <Text style={s.exPart}>{e ? `${PART_LABEL[e.part]} · ${e.g} · 권장 ${e.r}` : ''}</Text>
        </View>

        <View style={s.lastRow}>
          {last ? (
            <Text style={s.lastTxt} numberOfLines={1}>
              지난 기록 <Text style={s.lastDate}>{last.date.slice(5)}</Text>{'  '}
              <Text style={s.lastSets}>{last.detail.map(fmtSetDetail).join('  ')}</Text>
            </Text>
          ) : (
            <Text style={s.lastEmpty}>이 종목의 첫 기록입니다</Text>
          )}
        </View>
      </View>

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
        <TouchableOpacity style={[s.filmCell, s.filmAdd]} onPress={() => setPicker('add')}>
          <Text style={s.filmAddTxt}>＋</Text>
          <Text style={s.filmAddLabel}>종목 추가</Text>
        </TouchableOpacity>
      </ScrollView>

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

        <View style={s.sheetHead}>
          <Text style={s.sheetTitle}>세트 기록 · 길게 눌러 삭제</Text>
          <TouchableOpacity onPress={() => setPicker('swap')} hitSlop={8}>
            <Text style={s.swapLink}>종목 교체</Text>
          </TouchableOpacity>
        </View>

        <ScrollView style={s.setsScroll} contentContainerStyle={s.setsContainer}>
          {cur.sets.map((st, si) => {
            const ref = last?.detail[si];
            return (
              <View key={si} style={[s.setRow, st.done && s.setRowDone]}>
                <Text style={s.setNum}>{si + 1}</Text>
                <TextInput
                  style={[s.setInput, st.done && s.setInputDone]}
                  placeholder={ref && ref.w > 0 ? String(ref.w) : 'kg'}
                  placeholderTextColor={colors.muted}
                  keyboardType="decimal-pad"
                  value={st.w}
                  onChangeText={(v) => setVal(si, 'w', v)}
                />
                <Text style={s.setX}>×</Text>
                <TextInput
                  style={[s.setInput, st.done && s.setInputDone]}
                  placeholder={ref ? String(ref.r) : '회'}
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
            );
          })}
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
            <TouchableOpacity style={[s.navBtn, s.navSolid]} onPress={handleFinish} disabled={saving}>
              {saving ? (
                <ActivityIndicator color={colors.bg} />
              ) : (
                <Text style={s.navSolidTxt}>{doneAll ? '운동 완료 ✓' : '저장하고 종료'}</Text>
              )}
            </TouchableOpacity>
          ) : (
            <TouchableOpacity style={[s.navBtn, s.navSolid]} onPress={() => moveEx(1)}>
              <Text style={s.navSolidTxt}>다음 →</Text>
            </TouchableOpacity>
          )}
        </View>
      </View>

      {picker && (
        <ExercisePicker
          mode={picker}
          currentId={cur.id}
          usedIds={session.data.map((x) => x.id)}
          place={profile?.env ?? 'gym'}
          onClose={() => setPicker(null)}
          onPick={(id) => {
            if (picker === 'swap') swapExercise(id);
            else appendExercise(id);
            setPicker(null);
          }}
        />
      )}
    </View>
  );
}

// ─── 종목 선택 시트 ─────────────────────────────────────────────────────────
function ExercisePicker({
  mode, currentId, usedIds, place, onClose, onPick,
}: {
  mode: 'swap' | 'add';
  currentId: string;
  usedIds: string[];
  place: 'gym' | 'home';
  onClose: () => void;
  onPick: (id: string) => void;
}) {
  const insets = useSafeAreaInsets();
  const cur = exById(currentId);
  const [sameOnly, setSameOnly] = useState(mode === 'swap');
  const [q, setQ] = useState('');

  const list = useMemo(() => {
    const keyword = q.trim();
    return exFilter({ place, ...(sameOnly && cur ? { part: cur.part } : {}) })
      // 이미 세션에 들어있는 종목은 제외 — 중복되면 기록이 뭉개진다
      .filter((x) => (mode === 'swap' ? x.id !== currentId : true) && !usedIds.includes(x.id))
      .filter((x) => !keyword || x.n.includes(keyword) || x.g.includes(keyword));
  }, [place, sameOnly, cur, q, usedIds, mode, currentId]);

  return (
    <View style={[p.root, { paddingTop: insets.top + 16 }]}>
      <View style={p.head}>
        <View style={{ flex: 1 }}>
          <Text style={p.title}>{mode === 'swap' ? '종목 교체' : '종목 추가'}</Text>
          <Text style={p.sub}>
            {mode === 'swap' && cur ? `${cur.n} → 다른 종목으로` : '세션 맨 뒤에 추가됩니다'}
          </Text>
        </View>
        <TouchableOpacity style={p.close} onPress={onClose}>
          <Text style={p.closeTxt}>✕</Text>
        </TouchableOpacity>
      </View>

      <TextInput
        style={p.search}
        placeholder="종목 검색"
        placeholderTextColor={colors.muted}
        value={q}
        onChangeText={setQ}
        autoCorrect={false}
      />

      {cur && (
        <View style={p.filterRow}>
          <TouchableOpacity style={[p.chip, sameOnly && p.chipOn]} onPress={() => setSameOnly(true)}>
            <Text style={[p.chipTxt, sameOnly && p.chipTxtOn]}>
              같은 부위 ({PART_LABEL[cur.part]})
            </Text>
          </TouchableOpacity>
          <TouchableOpacity style={[p.chip, !sameOnly && p.chipOn]} onPress={() => setSameOnly(false)}>
            <Text style={[p.chipTxt, !sameOnly && p.chipTxtOn]}>전체</Text>
          </TouchableOpacity>
        </View>
      )}

      <FlatList
        data={list}
        keyExtractor={(x) => x.id}
        contentContainerStyle={p.listInner}
        showsVerticalScrollIndicator={false}
        initialNumToRender={12}
        maxToRenderPerBatch={12}
        windowSize={7}
        keyboardShouldPersistTaps="handled"
        ListEmptyComponent={<Text style={p.empty}>조건에 맞는 종목이 없습니다.</Text>}
        renderItem={({ item }) => <PickerRow ex={item} onPick={() => onPick(item.id)} />}
      />
    </View>
  );
}

function PickerRow({ ex, onPick }: { ex: Exercise; onPick: () => void }) {
  return (
    <TouchableOpacity style={p.row} activeOpacity={0.75} onPress={onPick}>
      <ExerciseMedia exId={ex.id} rounded={10} style={p.thumb} dim={0.3} />
      <View style={{ flex: 1 }}>
        <Text style={p.name}>{ex.n}</Text>
        <Text style={p.meta}>{PART_LABEL[ex.part]} · {ex.g} · {ex.s}세트 {ex.r}</Text>
      </View>
      <Text style={p.pick}>선택</Text>
    </TouchableOpacity>
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

  mediaArea: { flex: 1, paddingHorizontal: 20, justifyContent: 'center', gap: 12 },
  media: { width: '100%', aspectRatio: 1, maxHeight: 260, alignSelf: 'center' },
  mediaMeta: { alignItems: 'center' },
  exName: { fontSize: 21, fontWeight: '800', color: colors.ink, textAlign: 'center', letterSpacing: -0.3 },
  exPart: { fontSize: 12, color: colors.muted, marginTop: 4, textAlign: 'center' },
  lastRow: {
    backgroundColor: colors.panel2, borderRadius: 12, paddingHorizontal: 14, paddingVertical: 10,
    borderWidth: 1, borderColor: colors.line,
  },
  lastTxt: { fontSize: 12, color: colors.muted, textAlign: 'center' },
  lastDate: { color: colors.mid },
  lastSets: { color: colors.ink, fontWeight: '700' },
  lastEmpty: { fontSize: 12, color: colors.muted, textAlign: 'center' },

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
  filmAdd: { borderStyle: 'dashed', justifyContent: 'center' },
  filmAddTxt: { fontSize: 17, color: colors.muted, marginBottom: 2 },
  filmAddLabel: { fontSize: 9.5, color: colors.muted },

  sheet: {
    backgroundColor: colors.panel, borderTopWidth: 1, borderTopColor: colors.line2,
    borderTopLeftRadius: 24, borderTopRightRadius: 24,
    paddingHorizontal: 16, paddingTop: 8, paddingBottom: 34, maxHeight: '52%',
  },
  grab: {
    width: 40, height: 4, borderRadius: 2,
    backgroundColor: colors.line2, alignSelf: 'center', marginBottom: 12,
  },
  sheetHead: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 },
  sheetTitle: { fontSize: 10.5, fontWeight: '700', color: colors.muted, letterSpacing: 0.8 },
  swapLink: { fontSize: 12, color: colors.mid, fontWeight: '600' },

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

const p = StyleSheet.create({
  root: {
    position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
    backgroundColor: colors.bg, zIndex: 60,
  },
  head: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 20, gap: 12 },
  title: { fontSize: 20, fontWeight: '800', color: colors.ink },
  sub: { fontSize: 12, color: colors.muted, marginTop: 3 },
  close: {
    width: 36, height: 36, borderRadius: 18,
    backgroundColor: colors.panel2, alignItems: 'center', justifyContent: 'center',
  },
  closeTxt: { fontSize: 15, color: colors.mid },
  search: {
    marginHorizontal: 20, marginTop: 14,
    backgroundColor: colors.panel2, borderWidth: 1, borderColor: colors.line2,
    borderRadius: 12, paddingHorizontal: 14, paddingVertical: 11,
    fontSize: 14, color: colors.ink,
  },
  filterRow: { flexDirection: 'row', gap: 8, paddingHorizontal: 20, marginTop: 12 },
  chip: {
    backgroundColor: colors.panel2, borderRadius: 20,
    paddingHorizontal: 14, paddingVertical: 8,
    borderWidth: 1, borderColor: colors.line,
  },
  chipOn: { backgroundColor: colors.ink, borderColor: colors.ink },
  chipTxt: { fontSize: 12, fontWeight: '600', color: colors.muted },
  chipTxtOn: { color: colors.bg },
  listInner: { paddingHorizontal: 20, paddingTop: 14, paddingBottom: 40 },
  empty: { color: colors.muted, fontSize: 13, textAlign: 'center', marginTop: 30 },
  row: {
    flexDirection: 'row', alignItems: 'center', gap: 12,
    backgroundColor: colors.panel, borderRadius: 14, padding: 10,
    borderWidth: 1, borderColor: colors.line, marginBottom: 8,
  },
  thumb: { width: 48, height: 48 },
  name: { fontSize: 14, fontWeight: '600', color: colors.ink },
  meta: { fontSize: 10.5, color: colors.muted, marginTop: 2 },
  pick: { fontSize: 12, color: colors.mid, fontWeight: '700' },
});
