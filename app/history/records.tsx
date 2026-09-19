import { useMemo, useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, FlatList } from 'react-native';
import { useRouter } from 'expo-router';
import { colors } from '../../src/utils/colors';
import { Screen, TopBar, EmptyState } from '../../src/components/ui';
import { useAppStore } from '../../src/stores/appStore';
import { EX, Part, PART_LABEL, PART_ORDER } from '../../src/data/exercises';
import { personalBest, e1rm, fmtDateKo } from '../../src/utils/stats';
import { WorkoutLog, SetDetail } from '../../src/types';

interface RecordRow {
  id: string;
  name: string;
  part: Part;
  best: SetDetail;
  est1rm: number;
  date: string;
}

/** 이 기록을 세운 날짜를 역추적 */
function dateOfBest(logs: WorkoutLog[], exId: string, best: SetDetail): string {
  for (const l of logs) {
    const hit = l.exercises.find((x) => x.id === exId);
    if (hit?.best && hit.best.w === best.w && hit.best.r === best.r) return l.date;
  }
  return logs.find((l) => l.exercises.some((x) => x.id === exId))?.date ?? '';
}

export default function RecordsScreen() {
  const router = useRouter();
  const { logs } = useAppStore();
  const [part, setPart] = useState<Part | '전체'>('전체');

  const rows = useMemo<RecordRow[]>(() => {
    const done = new Set(logs.flatMap((l) => l.exercises.map((x) => x.id)));
    return EX.filter((e) => done.has(e.id))
      .map((e) => {
        const best = personalBest(logs, e.id);
        if (!best) return null;
        return {
          id: e.id,
          name: e.n,
          part: e.part,
          best,
          est1rm: Math.round(e1rm(best.w, best.r)),
          date: dateOfBest(logs, e.id, best),
        };
      })
      .filter((r): r is RecordRow => r !== null)
      .sort((a, b) => b.est1rm - a.est1rm);
  }, [logs]);

  const filtered = part === '전체' ? rows : rows.filter((r) => r.part === part);
  const parts = PART_ORDER.filter((p) => rows.some((r) => r.part === p));

  if (!rows.length) {
    return (
      <Screen>
        <TopBar title="개인 기록" onBack={() => router.back()} />
        <EmptyState
          text={'아직 기록이 없습니다.\n무게와 횟수를 입력해 운동을 완료하면\n종목별 최고 기록이 쌓입니다.'}
        />
      </Screen>
    );
  }

  return (
    <Screen>
      <TopBar title="개인 기록" meta={`${rows.length}종목`} onBack={() => router.back()} />

      <FlatList
        data={['전체' as const, ...parts]}
        keyExtractor={(p) => String(p)}
        horizontal
        showsHorizontalScrollIndicator={false}
        style={s.pillScroll}
        contentContainerStyle={s.pillContent}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={[s.pill, part === item && s.pillOn]}
            onPress={() => setPart(item)}
          >
            <Text style={[s.pillTxt, part === item && s.pillTxtOn]}>
              {item === '전체' ? '전체' : PART_LABEL[item]}
            </Text>
          </TouchableOpacity>
        )}
      />

      <FlatList
        data={filtered}
        keyExtractor={(r) => r.id}
        contentContainerStyle={s.listInner}
        showsVerticalScrollIndicator={false}
        initialNumToRender={14}
        ListHeaderComponent={
          <Text style={s.lead}>
            추정 1RM(Epley 공식) 순으로 정렬했습니다. 실제 1회 최대 중량과는 차이가 있을 수 있습니다.
          </Text>
        }
        renderItem={({ item }) => (
          <TouchableOpacity
            style={s.row}
            activeOpacity={0.75}
            onPress={() => router.push(`/exercise/${item.id}`)}
          >
            <View style={{ flex: 1 }}>
              <Text style={s.name}>{item.name}</Text>
              <Text style={s.meta}>
                {PART_LABEL[item.part]}
                {item.date ? ` · ${fmtDateKo(item.date)}` : ''}
              </Text>
            </View>
            <View style={s.right}>
              <Text style={s.best}>{item.best.w}kg × {item.best.r}</Text>
              <Text style={s.est}>추정 1RM {item.est1rm}kg</Text>
            </View>
          </TouchableOpacity>
        )}
      />
    </Screen>
  );
}

const s = StyleSheet.create({
  pillScroll: { flexGrow: 0 },
  pillContent: { paddingHorizontal: 16, paddingBottom: 12, gap: 8 },
  pill: {
    backgroundColor: colors.panel2, borderRadius: 20,
    paddingHorizontal: 15, paddingVertical: 8,
    borderWidth: 1, borderColor: colors.line,
  },
  pillOn: { backgroundColor: colors.ink, borderColor: colors.ink },
  pillTxt: { fontSize: 12.5, fontWeight: '600', color: colors.muted },
  pillTxtOn: { color: colors.bg },

  listInner: { paddingHorizontal: 16, paddingBottom: 40 },
  lead: { fontSize: 11.5, color: colors.muted, lineHeight: 18, marginBottom: 14 },
  row: {
    flexDirection: 'row', alignItems: 'center', gap: 12,
    backgroundColor: colors.panel, borderRadius: 14, padding: 14,
    borderWidth: 1, borderColor: colors.line, marginBottom: 8,
  },
  name: { fontSize: 14.5, fontWeight: '600', color: colors.ink },
  meta: { fontSize: 11, color: colors.muted, marginTop: 3 },
  right: { alignItems: 'flex-end' },
  best: { fontSize: 15, fontWeight: '800', color: colors.ink },
  est: { fontSize: 10.5, color: colors.mid, marginTop: 3 },
});
