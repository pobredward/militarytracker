import {
  View, Text, ScrollView, TouchableOpacity, StyleSheet, ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { colors } from '../../src/utils/colors';
import { useAppStore } from '../../src/stores/appStore';
import { calcBodyStats, FOOD_LABEL } from '../../src/utils/body';
import { generateDiet } from '../../src/services/aiService';

export default function DietScreen() {
  const { profile, diet, dietLoading, setDiet, setDietLoading } = useAppStore();
  const st = calcBodyStats(profile);

  async function genDiet() {
    if (!profile || dietLoading) return;
    setDietLoading(true);
    try {
      setDiet(await generateDiet(profile));
    } finally {
      setDietLoading(false);
    }
  }

  if (!st || !profile) {
    return (
      <SafeAreaView style={s.root} edges={['top']}>
        <View style={s.empty}>
          <Text style={s.emptyTxt}>신체 정보를 불러오는 중입니다.{'\n'}온보딩을 완료하지 않았다면 먼저 진행해주세요.</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={s.root} edges={['top']}>
      <View style={s.topbar}>
        <Text style={s.title}>식단</Text>
        <Text style={s.meta}>{st.tagline}</Text>
      </View>

      <ScrollView style={s.scroll} contentContainerStyle={s.scrollInner} showsVerticalScrollIndicator={false}>
        <Text style={s.sectionLabel}>DAILY TARGET</Text>
        <View style={s.macroRow}>
          <MacroCard value={`${st.kcal}`} unit="kcal" label="목표 칼로리" />
          <MacroCard value={`${st.protein}`} unit="g" label="단백질" />
          <MacroCard value={`${st.carb}`} unit="g" label="탄수화물" />
          <MacroCard value={`${st.fat}`} unit="g" label="지방" />
        </View>
        <Text style={s.tdeeTxt}>
          유지 칼로리(TDEE) 약 {st.tdee}kcal · Mifflin-St Jeor + 활동계수 1.5 · BMI {st.bmi} ({st.bodyType})
        </Text>

        <View style={s.sectionRow}>
          <Text style={s.sectionLabel}>하루 식단</Text>
          <Text style={s.sectionSub}>
            {FOOD_LABEL[profile.food]} 기준{diet?.src === 'AI' ? ' · AI 구성' : ''}
          </Text>
        </View>

        {diet ? (
          <>
            {diet.meals.map((m, i) => (
              <View key={i} style={s.mealCard}>
                <View style={s.mealTimeWrap}><Text style={s.mealTime}>{m.t}</Text></View>
                <View style={s.mealBody}>
                  <Text style={s.mealMenu}>{m.m}</Text>
                  <Text style={s.mealKcal}>{m.k}</Text>
                </View>
              </View>
            ))}
            {diet.tip ? (
              <View style={s.tipCard}><Text style={s.tipTxt}>💡 {diet.tip}</Text></View>
            ) : null}
          </>
        ) : (
          <View style={s.emptyMeal}>
            <Text style={s.emptyMealTxt}>
              체형 · 목표 · 식사 환경에 맞는{'\n'}하루 식단을 구성합니다.
            </Text>
          </View>
        )}

        <TouchableOpacity
          style={[s.genBtn, diet && s.genGhost, dietLoading && s.genOff]}
          onPress={genDiet}
          disabled={dietLoading}
        >
          {dietLoading ? (
            <ActivityIndicator color={diet ? colors.mid : colors.bg} />
          ) : (
            <Text style={[s.genTxt, diet && s.genTxtGhost]}>{diet ? '다시 구성' : '식단 생성'}</Text>
          )}
        </TouchableOpacity>

        <Text style={s.notice}>일반적 영양 가이드이며 의학적 조언이 아닙니다.</Text>
      </ScrollView>
    </SafeAreaView>
  );
}

function MacroCard({ value, unit, label }: { value: string; unit: string; label: string }) {
  return (
    <View style={s.mbox}>
      <Text style={s.mboxVal}>{value}<Text style={s.mboxUnit}>{unit}</Text></Text>
      <Text style={s.mboxLabel}>{label}</Text>
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
  empty: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 24 },
  emptyTxt: { color: colors.muted, fontSize: 14, textAlign: 'center', lineHeight: 22 },

  sectionLabel: {
    fontSize: 9.5, fontWeight: '800', color: colors.muted,
    letterSpacing: 2, marginBottom: 12, marginTop: 8,
  },
  sectionRow: { flexDirection: 'row', alignItems: 'baseline', gap: 8, marginTop: 8 },
  sectionSub: { fontSize: 11, color: colors.muted },

  macroRow: { flexDirection: 'row', gap: 8, marginBottom: 10 },
  mbox: {
    flex: 1, backgroundColor: colors.panel, borderRadius: 16, padding: 14,
    borderWidth: 1, borderColor: colors.line,
  },
  mboxVal: { fontSize: 20, fontWeight: '800', color: colors.ink, letterSpacing: -0.5 },
  mboxUnit: { fontSize: 12, fontWeight: '600', color: colors.mid },
  mboxLabel: { fontSize: 10, color: colors.muted, marginTop: 4 },
  tdeeTxt: { fontSize: 11, color: colors.muted, lineHeight: 17, marginBottom: 6 },

  mealCard: {
    flexDirection: 'row', gap: 14,
    backgroundColor: colors.panel, borderRadius: 16, padding: 16,
    borderWidth: 1, borderColor: colors.line, marginBottom: 10,
  },
  mealTimeWrap: {
    backgroundColor: colors.panel3, borderRadius: 10,
    paddingHorizontal: 10, paddingVertical: 6, alignSelf: 'flex-start',
  },
  mealTime: { fontSize: 11, fontWeight: '700', color: colors.mid },
  mealBody: { flex: 1 },
  mealMenu: { fontSize: 14, fontWeight: '600', color: colors.ink, lineHeight: 20, marginBottom: 4 },
  mealKcal: { fontSize: 11.5, color: colors.muted },

  tipCard: {
    backgroundColor: colors.panel2, borderRadius: 14, padding: 14,
    borderWidth: 1, borderColor: colors.line, marginBottom: 14,
  },
  tipTxt: { fontSize: 13, color: colors.mid, lineHeight: 20 },

  emptyMeal: {
    backgroundColor: colors.panel, borderRadius: 16, padding: 28,
    borderWidth: 1, borderColor: colors.line, alignItems: 'center', marginBottom: 14,
  },
  emptyMealTxt: { color: colors.muted, fontSize: 14, textAlign: 'center', lineHeight: 22 },

  genBtn: { backgroundColor: colors.ink, borderRadius: 14, paddingVertical: 15, alignItems: 'center', marginBottom: 12 },
  genGhost: { backgroundColor: 'transparent', borderWidth: 1, borderColor: colors.line2 },
  genOff: { opacity: 0.4 },
  genTxt: { color: colors.bg, fontSize: 15, fontWeight: '700' },
  genTxtGhost: { color: colors.mid },
  notice: { fontSize: 10.5, color: colors.muted, lineHeight: 16, textAlign: 'center' },
});
