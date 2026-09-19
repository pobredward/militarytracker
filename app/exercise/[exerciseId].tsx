import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { colors } from '../../src/utils/colors';
import { Screen, TopBar, Body, SectionLabel, EmptyState, Notice } from '../../src/components/ui';
import ExerciseMedia from '../../src/components/ExerciseMedia';
import { exById, exByPart, EQUIP_LABEL, LEVEL_LABEL, PART_LABEL, PPL_LABEL } from '../../src/data/exercises';
import { formByExId } from '../../src/data/formCheck';
import { hasVideo } from '../../src/data/media';
import { rirFor, RISK_NOTE, ROM_NOTE } from '../../src/data/coaching';
import { useAppStore } from '../../src/stores/appStore';
import { lastRecordOf } from '../../src/utils/stats';

export default function ExerciseDetailScreen() {
  const { exerciseId } = useLocalSearchParams<{ exerciseId: string }>();
  const router = useRouter();
  const { logs } = useAppStore();

  const e = exById(String(exerciseId));
  if (!e) {
    return (
      <Screen>
        <TopBar title="종목" onBack={() => router.back()} />
        <EmptyState text="종목을 찾을 수 없습니다." />
      </Screen>
    );
  }

  const form = formByExId(e.id);
  const last = lastRecordOf(logs, e.id);
  const related = exByPart(e.part).filter((x) => x.id !== e.id).slice(0, 6);
  const rir = rirFor(e);
  const risk = RISK_NOTE[e.id];

  return (
    <Screen>
      <TopBar title={e.n} meta={PART_LABEL[e.part]} onBack={() => router.back()} />
      <Body style={{ paddingHorizontal: 0 }}>
        <ExerciseMedia
          exId={e.id}
          autoPlay
          rounded={0}
          dim={0.2}
          badge={hasVideo(e.id) ? '▶ LOOP' : undefined}
          style={s.hero}
        />

        <View style={s.pad}>
          <View style={s.tagRow}>
            <View style={s.tagDark}><Text style={s.tagDarkTxt}>{PPL_LABEL[e.ppl]}</Text></View>
            {e.eq.map((q) => (
              <View key={q} style={s.tag}><Text style={s.tagTxt}>{EQUIP_LABEL[q]}</Text></View>
            ))}
            <View style={s.tag}><Text style={s.tagTxt}>{LEVEL_LABEL[e.lv]}</Text></View>
            <View style={s.tag}><Text style={s.tagTxt}>{e.pl.includes('home') ? '홈트 가능' : '헬스장'}</Text></View>
          </View>

          <Text style={s.target}>{e.g}</Text>

          <View style={s.specRow}>
            <Spec value={`${e.s}`} unit="세트" label="권장 볼륨" />
            <Spec value={e.r} unit="" label="반복 수" />
            <Spec value={`${e.rest}`} unit="초" label="세트간 휴식" />
          </View>

          {/* 강도 — 실패까지 남길 반복 수 */}
          <View style={s.rirBox}>
            <View style={s.rirHead}>
              <Text style={s.rirLabel}>강도</Text>
              <Text style={s.rirRange}>{rir.range}</Text>
            </View>
            <Text style={s.rirNote}>{rir.note}</Text>
          </View>

          {/* 주의가 필요한 종목만 표시 */}
          {risk ? (
            <View style={s.riskBox}>
              <Text style={s.riskTitle}>⚠  주의</Text>
              <Text style={s.riskTxt}>{risk}</Text>
            </View>
          ) : null}

          {last && (
            <View style={s.lastBox}>
              <Text style={s.lastTxt}>
                최근 기록 · <Text style={s.lastHi}>{last.sets}세트</Text>
                {last.volume > 0 ? <Text style={s.lastHi}>  총 {last.volume.toLocaleString('ko-KR')}kg</Text> : null}
              </Text>
            </View>
          )}

          {form ? (
            <>
              <SectionLabel>자주 하는 실수</SectionLabel>
              {form.w.map((w, i) => (
                <Point key={i} text={w} mode="w" />
              ))}
              <SectionLabel>올바른 수행</SectionLabel>
              {form.c.map((c, i) => (
                <Point key={i} text={c} mode="c" />
              ))}
            </>
          ) : (
            <>
              <SectionLabel>수행 원칙</SectionLabel>
              <Text style={s.emptyForm}>{ROM_NOTE}</Text>
              <Text style={[s.emptyForm, { marginTop: 10 }]}>
                이 종목의 상세 교정 포인트는 준비 중입니다. 공통 원칙은 척추 중립 유지, 반동 없이,
                내리는 구간을 통제하는 것입니다.
              </Text>
            </>
          )}

          {related.length > 0 && (
            <>
              <SectionLabel>같은 부위 다른 종목</SectionLabel>
              <View style={s.relGrid}>
                {related.map((r) => (
                  <TouchableOpacity
                    key={r.id}
                    style={s.relCard}
                    activeOpacity={0.75}
                    onPress={() => router.push(`/exercise/${r.id}`)}
                  >
                    <ExerciseMedia exId={r.id} rounded={12} style={s.relThumb} dim={0.35} />
                    <Text style={s.relName} numberOfLines={2}>{r.n}</Text>
                  </TouchableOpacity>
                ))}
              </View>
            </>
          )}

          <Notice>통증이 발생하면 즉시 중단하고 전문가와 상담하세요.</Notice>
        </View>
      </Body>
    </Screen>
  );
}

function Spec({ value, unit, label }: { value: string; unit: string; label: string }) {
  return (
    <View style={s.spec}>
      <Text style={s.specVal}>
        {value}
        <Text style={s.specUnit}>{unit}</Text>
      </Text>
      <Text style={s.specLabel}>{label}</Text>
    </View>
  );
}

function Point({ text, mode }: { text: string; mode: 'w' | 'c' }) {
  return (
    <View style={s.pointRow}>
      <View style={[s.pointIcon, mode === 'w' ? s.pIconW : s.pIconC]}>
        <Text style={[s.pointIconTxt, mode === 'w' ? s.pTxtW : s.pTxtC]}>
          {mode === 'w' ? '✕' : '✓'}
        </Text>
      </View>
      <Text style={s.pointTxt}>{text}</Text>
    </View>
  );
}

const s = StyleSheet.create({
  hero: { width: '100%', aspectRatio: 1 },
  pad: { paddingHorizontal: 16, paddingTop: 16 },
  tagRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 6 },
  tag: { backgroundColor: colors.panel3, borderRadius: 7, paddingHorizontal: 8, paddingVertical: 4 },
  tagTxt: { fontSize: 10, color: colors.muted, fontWeight: '600' },
  tagDark: { backgroundColor: colors.ink, borderRadius: 7, paddingHorizontal: 8, paddingVertical: 4 },
  tagDarkTxt: { fontSize: 10, color: colors.bg, fontWeight: '800' },
  target: { fontSize: 14, color: colors.mid, marginTop: 12 },

  specRow: { flexDirection: 'row', gap: 8, marginTop: 14 },
  spec: {
    flex: 1, backgroundColor: colors.panel, borderRadius: 14, padding: 14,
    borderWidth: 1, borderColor: colors.line,
  },
  specVal: { fontSize: 18, fontWeight: '800', color: colors.ink },
  specUnit: { fontSize: 11, fontWeight: '600', color: colors.mid },
  specLabel: { fontSize: 10, color: colors.muted, marginTop: 4 },

  rirBox: {
    backgroundColor: colors.panel2, borderRadius: 14, padding: 14,
    borderWidth: 1, borderColor: colors.line2, marginTop: 10,
  },
  rirHead: { flexDirection: 'row', alignItems: 'baseline', gap: 8, marginBottom: 6 },
  rirLabel: { fontSize: 10, fontWeight: '800', color: colors.muted, letterSpacing: 1.5 },
  rirRange: { fontSize: 15, fontWeight: '800', color: colors.ink },
  rirNote: { fontSize: 12.5, color: colors.mid, lineHeight: 19 },

  riskBox: {
    backgroundColor: 'rgba(228,88,88,0.08)', borderRadius: 14, padding: 14,
    borderWidth: 1, borderColor: 'rgba(228,88,88,0.3)', marginTop: 10,
  },
  riskTitle: { fontSize: 11, fontWeight: '800', color: colors.wrong, letterSpacing: 0.5, marginBottom: 6 },
  riskTxt: { fontSize: 13, color: colors.ink, lineHeight: 20 },

  lastBox: {
    backgroundColor: colors.panel2, borderRadius: 12, padding: 12,
    borderWidth: 1, borderColor: colors.line, marginTop: 10,
  },
  lastTxt: { fontSize: 12, color: colors.muted },
  lastHi: { color: colors.ink, fontWeight: '700' },

  pointRow: { flexDirection: 'row', alignItems: 'flex-start', gap: 12, marginBottom: 12 },
  pointIcon: {
    width: 22, height: 22, borderRadius: 11,
    alignItems: 'center', justifyContent: 'center', flexShrink: 0, marginTop: 1,
  },
  pIconW: { backgroundColor: 'rgba(228,88,88,0.15)' },
  pIconC: { backgroundColor: 'rgba(168,197,160,0.16)' },
  pointIconTxt: { fontSize: 11, fontWeight: '700' },
  pTxtW: { color: colors.wrong },
  pTxtC: { color: colors.good },
  pointTxt: { fontSize: 14, color: colors.ink, lineHeight: 21, flex: 1 },
  emptyForm: { fontSize: 13, color: colors.muted, lineHeight: 21 },

  relGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  relCard: { width: '31%' },
  relThumb: { width: '100%', aspectRatio: 1, marginBottom: 6 },
  relName: { fontSize: 11, color: colors.mid, lineHeight: 15 },
});
