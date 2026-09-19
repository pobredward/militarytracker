import { useMemo, useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, SectionList } from 'react-native';
import { useRouter } from 'expo-router';
import { colors } from '../../src/utils/colors';
import { Screen, TopBar, EmptyState } from '../../src/components/ui';
import { useAppStore } from '../../src/stores/appStore';
import { exById, PART_LABEL } from '../../src/data/exercises';
import { WorkoutLog } from '../../src/types';
import {
  fmtDateKo, fmtDuration, fmtVolume, fmtSetDetail, totalSets, totalVolume,
} from '../../src/utils/stats';

export default function HistoryScreen() {
  const router = useRouter();
  const { logs } = useAppStore();
  const [openId, setOpenId] = useState<string | null>(null);

  // 월별 그룹
  const sections = useMemo(() => {
    const map = new Map<string, WorkoutLog[]>();
    logs.forEach((l) => {
      const key = l.date.slice(0, 7); // YYYY-MM
      map.set(key, [...(map.get(key) ?? []), l]);
    });
    return [...map.entries()].map(([key, data]) => ({
      title: `${Number(key.slice(5, 7))}월`,
      key,
      data,
    }));
  }, [logs]);

  if (!logs.length) {
    return (
      <Screen>
        <TopBar title="운동 기록" onBack={() => router.back()} />
        <EmptyState text={'아직 완료한 운동이 없습니다.\n첫 운동을 마치면 여기에 쌓입니다.'} />
      </Screen>
    );
  }

  const allSets = totalSets(logs);
  const allVolume = totalVolume(logs);

  return (
    <Screen>
      <TopBar title="운동 기록" meta={`${logs.length}회`} onBack={() => router.back()} />

      <View style={s.summaryRow}>
        <Summary value={`${logs.length}`} label="총 운동" />
        <Summary value={`${allSets}`} label="총 세트" />
        <Summary value={fmtVolume(allVolume)} label="누적 볼륨" />
      </View>

      <SectionList
        sections={sections}
        keyExtractor={(l, i) => l.id ?? `${l.date}-${i}`}
        contentContainerStyle={s.listInner}
        showsVerticalScrollIndicator={false}
        stickySectionHeadersEnabled={false}
        renderSectionHeader={({ section }) => (
          <Text style={s.monthLabel}>{section.title}</Text>
        )}
        renderItem={({ item }) => {
          const id = item.id ?? `${item.date}-${item.createdAt}`;
          const open = openId === id;
          const done = item.exercises.filter((x) => x.sets > 0);
          return (
            <TouchableOpacity
              style={[s.card, open && s.cardOpen]}
              activeOpacity={0.8}
              onPress={() => setOpenId(open ? null : id)}
            >
              <View style={s.cardHead}>
                <View style={{ flex: 1 }}>
                  <Text style={s.date}>{fmtDateKo(item.date)}</Text>
                  <Text style={s.dayName}>{item.dayName || '운동'}</Text>
                </View>
                <View style={s.cardStats}>
                  <Text style={s.statMain}>{item.totalSets}세트</Text>
                  <Text style={s.statSub}>
                    {item.totalVolume > 0 ? fmtVolume(item.totalVolume) : '—'}
                    {item.durationSec > 0 ? ` · ${fmtDuration(item.durationSec)}` : ''}
                  </Text>
                </View>
                <Text style={[s.chev, open && s.chevOpen]}>›</Text>
              </View>

              {open && (
                <View style={s.detail}>
                  {done.length === 0 && <Text style={s.noDetail}>기록된 세트가 없습니다.</Text>}
                  {done.map((x, i) => {
                    const e = exById(x.id);
                    return (
                      <TouchableOpacity
                        key={`${x.id}-${i}`}
                        style={s.exRow}
                        onPress={() => router.push(`/exercise/${x.id}`)}
                      >
                        <View style={{ flex: 1 }}>
                          <Text style={s.exName}>{e?.n ?? x.id}</Text>
                          <Text style={s.exPart}>
                            {e ? PART_LABEL[e.part] : ''} · {x.sets}세트
                          </Text>
                        </View>
                        <Text style={s.exSets} numberOfLines={2}>
                          {x.detail?.length
                            ? x.detail.map(fmtSetDetail).join('  ')
                            : `${x.sets}세트`}
                        </Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              )}
            </TouchableOpacity>
          );
        }}
      />
    </Screen>
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
  summaryRow: { flexDirection: 'row', gap: 8, paddingHorizontal: 16, paddingBottom: 6 },
  summary: {
    flex: 1, backgroundColor: colors.panel2, borderRadius: 14, padding: 14,
    borderWidth: 1, borderColor: colors.line2,
  },
  summaryVal: { fontSize: 17, fontWeight: '800', color: colors.ink },
  summaryLabel: { fontSize: 10, color: colors.muted, marginTop: 4 },

  listInner: { paddingHorizontal: 16, paddingBottom: 40, paddingTop: 10 },
  monthLabel: {
    fontSize: 9.5, fontWeight: '800', color: colors.muted,
    letterSpacing: 2, marginTop: 14, marginBottom: 10,
  },
  card: {
    backgroundColor: colors.panel, borderRadius: 16, padding: 14,
    borderWidth: 1, borderColor: colors.line, marginBottom: 8,
  },
  cardOpen: { borderColor: colors.line2, backgroundColor: colors.panel2 },
  cardHead: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  date: { fontSize: 11, color: colors.muted },
  dayName: { fontSize: 15, fontWeight: '700', color: colors.ink, marginTop: 3 },
  cardStats: { alignItems: 'flex-end' },
  statMain: { fontSize: 14, fontWeight: '700', color: colors.ink },
  statSub: { fontSize: 10.5, color: colors.muted, marginTop: 3 },
  chev: { fontSize: 20, color: colors.muted, marginLeft: 2 },
  chevOpen: { color: colors.ink },

  detail: { marginTop: 14, borderTopWidth: 1, borderTopColor: colors.line, paddingTop: 12, gap: 8 },
  noDetail: { fontSize: 12, color: colors.muted },
  exRow: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  exName: { fontSize: 13.5, fontWeight: '600', color: colors.ink },
  exPart: { fontSize: 10.5, color: colors.muted, marginTop: 2 },
  exSets: { fontSize: 11, color: colors.mid, textAlign: 'right', maxWidth: 140 },
});
