import { memo, useCallback, useMemo, useState } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, StyleSheet, FlatList,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { colors } from '../../src/utils/colors';
import {
  EX, Exercise, Part, PART_LABEL, PART_ORDER, EQUIP_LABEL, LEVEL_LABEL,
} from '../../src/data/exercises';
import { formByExId, FORM_COUNT } from '../../src/data/formCheck';
import { hasVideo, VIDEO_COUNT } from '../../src/data/media';
import ExerciseMedia from '../../src/components/ExerciseMedia';

type Filter = Part | '전체' | '영상';

const FILTERS: { key: Filter; label: string }[] = [
  { key: '전체', label: '전체' },
  { key: '영상', label: '영상 있음' },
  ...PART_ORDER.map((p) => ({ key: p as Filter, label: PART_LABEL[p] })),
];

export default function FormScreen() {
  const router = useRouter();
  const [filter, setFilter] = useState<Filter>('전체');
  const [q, setQ] = useState('');

  const list = useMemo(() => {
    const keyword = q.trim();
    return EX.filter((e) => {
      if (filter === '영상' && !hasVideo(e.id)) return false;
      if (filter !== '전체' && filter !== '영상' && e.part !== filter) return false;
      if (keyword && !(e.n.includes(keyword) || e.g.includes(keyword))) return false;
      return true;
    });
  }, [filter, q]);

  const open = useCallback((id: string) => router.push(`/exercise/${id}`), [router]);

  // 인라인 엘리먼트로 두면 검색어를 칠 때마다 헤더가 리마운트된다
  const Header = useCallback(
    () => (
      <Text style={s.descTxt}>
        {list.length}개 종목 · 전 종목에 자주 하는 실수와 교정 포인트가 있습니다.
      </Text>
    ),
    [list.length]
  );

  return (
    <SafeAreaView style={s.root} edges={['top']}>
      <View style={s.topbar}>
        <Text style={s.title}>자세 체크</Text>
        <Text style={s.meta}>자세 {FORM_COUNT} · 영상 {VIDEO_COUNT}</Text>
      </View>

      <View style={s.searchWrap}>
        <TextInput
          style={s.search}
          placeholder="종목 검색 (예: 벤치, 광배)"
          placeholderTextColor={colors.muted}
          value={q}
          onChangeText={setQ}
          autoCorrect={false}
          returnKeyType="search"
        />
        {q.length > 0 && (
          <TouchableOpacity style={s.clear} onPress={() => setQ('')} hitSlop={10}>
            <Text style={s.clearTxt}>✕</Text>
          </TouchableOpacity>
        )}
      </View>

      <FlatList
        data={FILTERS}
        keyExtractor={(f) => String(f.key)}
        horizontal
        showsHorizontalScrollIndicator={false}
        style={s.pillScroll}
        contentContainerStyle={s.pillContent}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={[s.pill, filter === item.key && s.pillActive]}
            onPress={() => setFilter(item.key)}
          >
            <Text style={[s.pillTxt, filter === item.key && s.pillTxtActive]}>{item.label}</Text>
          </TouchableOpacity>
        )}
      />

      <FlatList
        data={list}
        keyExtractor={(e) => e.id}
        numColumns={2}
        columnWrapperStyle={s.row}
        contentContainerStyle={s.listInner}
        showsVerticalScrollIndicator={false}
        initialNumToRender={12}
        maxToRenderPerBatch={8}
        windowSize={7}
        // removeClippedSubviews 는 numColumns 와 함께 쓰면 안드로이드에서
        // 빠르게 스크롤할 때 셀이 빈 칸으로 남는 문제가 있어 쓰지 않는다
        ListHeaderComponent={Header}
        ListEmptyComponent={<Text style={s.empty}>검색 결과가 없습니다.</Text>}
        renderItem={({ item }) => <Card ex={item} onPress={open} />}
      />
    </SafeAreaView>
  );
}

const Card = memo(function Card({ ex, onPress }: { ex: Exercise; onPress: (id: string) => void }) {
  const form = formByExId(ex.id);
  const video = hasVideo(ex.id);

  return (
    <TouchableOpacity style={s.card} activeOpacity={0.75} onPress={() => onPress(ex.id)}>
      {/* 그리드에서는 포스터만 — 영상 플레이어를 180개 만들지 않는다 */}
      <ExerciseMedia exId={ex.id} rounded={16} style={s.thumb} dim={0.4} />

      <View style={s.badgeRow}>
        {video && <View style={s.vBadge}><Text style={s.vBadgeTxt}>▶ 영상</Text></View>}
        {form && (
          <>
            <View style={s.errBadge}><Text style={s.errBadgeTxt}>✕ {form.w.length}</Text></View>
            <View style={s.okBadge}><Text style={s.okBadgeTxt}>✓ {form.c.length}</Text></View>
          </>
        )}
      </View>

      <Text style={s.name} numberOfLines={1}>{ex.n}</Text>
      <Text style={s.sub} numberOfLines={1}>{PART_LABEL[ex.part]} · {ex.g}</Text>
      <Text style={s.meta2} numberOfLines={1}>
        {ex.eq.map((q) => EQUIP_LABEL[q]).join('/')} · {LEVEL_LABEL[ex.lv]}
      </Text>
    </TouchableOpacity>
  );
});

const s = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.bg },
  topbar: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
    paddingHorizontal: 20, paddingTop: 14, paddingBottom: 8,
  },
  title: { fontSize: 22, fontWeight: '800', color: colors.ink, letterSpacing: -0.3 },
  meta: { fontSize: 10, color: colors.muted, letterSpacing: 0.8 },

  searchWrap: { paddingHorizontal: 16, paddingBottom: 10, justifyContent: 'center' },
  search: {
    backgroundColor: colors.panel2, borderWidth: 1, borderColor: colors.line2,
    borderRadius: 12, paddingHorizontal: 14, paddingVertical: 11,
    fontSize: 14, color: colors.ink,
  },
  clear: { position: 'absolute', right: 28, padding: 6 },
  clearTxt: { color: colors.muted, fontSize: 13 },

  pillScroll: { flexGrow: 0 },
  pillContent: { paddingHorizontal: 16, paddingBottom: 12, gap: 8 },
  pill: {
    backgroundColor: colors.panel2, borderRadius: 20,
    paddingHorizontal: 15, paddingVertical: 8,
    borderWidth: 1, borderColor: colors.line,
  },
  pillActive: { backgroundColor: colors.ink, borderColor: colors.ink },
  pillTxt: { fontSize: 12.5, fontWeight: '600', color: colors.muted },
  pillTxtActive: { color: colors.bg },

  listInner: { paddingHorizontal: 16, paddingBottom: 40 },
  row: { gap: 10, marginBottom: 16 },
  descTxt: { fontSize: 12.5, color: colors.muted, lineHeight: 19, marginBottom: 14 },
  empty: { color: colors.muted, fontSize: 14, textAlign: 'center', marginTop: 40 },

  card: { flex: 1 },
  thumb: { width: '100%', aspectRatio: 1 },
  badgeRow: { flexDirection: 'row', gap: 4, marginTop: 8, flexWrap: 'wrap' },
  vBadge: {
    backgroundColor: 'rgba(244,244,245,0.14)', borderRadius: 5,
    paddingHorizontal: 6, paddingVertical: 2,
    borderWidth: 0.5, borderColor: 'rgba(244,244,245,0.25)',
  },
  vBadgeTxt: { fontSize: 8.5, color: colors.ink, fontWeight: '700' },
  okBadge: {
    backgroundColor: 'rgba(168,197,160,0.18)', borderRadius: 5,
    paddingHorizontal: 6, paddingVertical: 2,
    borderWidth: 0.5, borderColor: 'rgba(168,197,160,0.35)',
  },
  okBadgeTxt: { fontSize: 8.5, color: colors.good, fontWeight: '700' },
  errBadge: {
    backgroundColor: 'rgba(228,88,88,0.18)', borderRadius: 5,
    paddingHorizontal: 6, paddingVertical: 2,
    borderWidth: 0.5, borderColor: 'rgba(228,88,88,0.35)',
  },
  errBadgeTxt: { fontSize: 8.5, color: colors.wrong, fontWeight: '700' },
  name: { fontSize: 13, fontWeight: '700', color: colors.ink, marginTop: 7 },
  sub: { fontSize: 10.5, color: colors.mid, marginTop: 2 },
  meta2: { fontSize: 10, color: colors.muted, marginTop: 2 },
});
