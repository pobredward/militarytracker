import { useState } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, StyleSheet, ActivityIndicator, Platform,
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { colors } from '../src/utils/colors';
import { Screen, TopBar, Body, SectionLabel, PrimaryBtn } from '../src/components/ui';
import { showAlert } from '../src/utils/alert';
import { useAuthStore } from '../src/stores/authStore';
import { useEntitlement } from '../src/hooks/useEntitlement';
import {
  PRO_FEATURES, FEATURE_LABEL, FEATURE_DESC, FREE_HIGHLIGHTS,
  PRODUCTS, TRIAL_DAYS, PRO_NAME, Feature,
} from '../src/config/entitlements';
import {
  purchase, restore, startTrial, redeemPromo, canPurchase,
  BillingUnavailable, PromoError,
} from '../src/services/billingService';
import { SUB_STATUS_LABEL } from '../src/utils/subscription';
import type { Subscription } from '../src/types';

type Busy = null | 'buy' | 'trial' | 'promo' | 'restore';

export default function SubscribeScreen() {
  const router = useRouter();
  const { f } = useLocalSearchParams<{ f?: string }>();
  const { patchUser } = useAuthStore();
  const { sub, pro, left } = useEntitlement();

  const focus = PRO_FEATURES.includes(f as Feature) ? (f as Feature) : null;
  const [picked, setPicked] = useState(PRODUCTS.find((p) => p.best)?.id ?? PRODUCTS[0].id);
  const [code, setCode] = useState('');
  const [busy, setBusy] = useState<Busy>(null);

  const trialAvailable = TRIAL_DAYS > 0 && !sub.trialUsed && !pro;

  function fail(e: unknown, fallback: string) {
    const m = e instanceof BillingUnavailable || e instanceof PromoError ? e.message : fallback;
    showAlert('안내', m);
  }

  async function run(kind: Busy, fn: () => Promise<Subscription | null>, done: string) {
    if (busy) return;
    setBusy(kind);
    try {
      const next = await fn();
      if (next) {
        patchUser({ sub: next });
        showAlert('완료', done, [{ text: '확인', onPress: () => router.back() }]);
      }
    } catch (e) {
      fail(e, '처리하지 못했습니다. 잠시 후 다시 시도해주세요.');
    } finally {
      setBusy(null);
    }
  }

  return (
    <Screen>
      <TopBar title={PRO_NAME} meta="SUBSCRIPTION" onBack={() => router.back()} />
      <Body>
        {pro ? (
          <View style={s.activeBox}>
            <Text style={s.activeLabel}>{SUB_STATUS_LABEL[sub.status]}</Text>
            <Text style={s.activeTxt}>
              {left !== null ? `${left}일 남았습니다.` : '이용 기간에 제한이 없습니다.'}
            </Text>
            {sub.status === 'canceled' && (
              <Text style={s.activeSub}>해지가 예약되어 있어도 남은 기간은 그대로 사용합니다.</Text>
            )}
          </View>
        ) : (
          <Text style={s.lead}>
            {focus
              ? `${FEATURE_LABEL[focus]}은 구독 기능입니다.`
              : '기록은 계속 무료입니다. 개인화만 구독으로 열립니다.'}
          </Text>
        )}

        <SectionLabel>구독하면 열리는 기능</SectionLabel>
        {PRO_FEATURES.map((k) => (
          <View key={k} style={[s.row, focus === k && s.rowFocus]}>
            <View style={[s.dot, focus === k && s.dotFocus]} />
            <View style={{ flex: 1 }}>
              <Text style={s.rowTitle}>{FEATURE_LABEL[k]}</Text>
              <Text style={s.rowSub}>{FEATURE_DESC[k]}</Text>
            </View>
          </View>
        ))}

        <SectionLabel>구독하지 않아도 그대로</SectionLabel>
        <View style={s.freeBox}>
          {FREE_HIGHLIGHTS.map((t) => (
            <Text key={t} style={s.freeTxt}>· {t}</Text>
          ))}
        </View>

        {!pro && (
          <>
            <SectionLabel>플랜 선택</SectionLabel>
            {PRODUCTS.map((p) => {
              const on = picked === p.id;
              return (
                <TouchableOpacity
                  key={p.id}
                  style={[s.plan, on && s.planOn]}
                  activeOpacity={0.8}
                  onPress={() => setPicked(p.id)}
                >
                  <View style={{ flex: 1 }}>
                    <View style={s.planHead}>
                      <Text style={[s.planLabel, on && s.planLabelOn]}>{p.label}</Text>
                      {p.best && <View style={s.bestTag}><Text style={s.bestTxt}>추천</Text></View>}
                    </View>
                    {p.note ? <Text style={s.planNote}>{p.note}</Text> : null}
                  </View>
                  <Text style={[s.planPrice, on && s.planPriceOn]}>
                    {p.price}<Text style={s.planPeriod}>{p.period}</Text>
                  </Text>
                </TouchableOpacity>
              );
            })}

            <PrimaryBtn
              label={canPurchase() ? '구독 시작' : '스토어 결제 준비 중'}
              loading={busy === 'buy'}
              disabled={!!busy}
              onPress={() => run('buy', () => purchase(picked), '구독이 시작되었습니다.')}
              style={{ marginTop: 6 }}
            />

            {trialAvailable && (
              <TouchableOpacity
                style={s.trialBtn}
                disabled={!!busy}
                onPress={() => run('trial', startTrial, `${TRIAL_DAYS}일 무료 체험이 시작되었습니다.`)}
              >
                {busy === 'trial'
                  ? <ActivityIndicator color={colors.ink} />
                  : <Text style={s.trialTxt}>{TRIAL_DAYS}일 무료로 먼저 써보기</Text>}
              </TouchableOpacity>
            )}

            <SectionLabel>코드가 있다면</SectionLabel>
            <View style={s.codeRow}>
              <TextInput
                style={s.codeInput}
                placeholder="프로모션 코드"
                placeholderTextColor={colors.muted}
                value={code}
                onChangeText={setCode}
                autoCapitalize="characters"
                autoCorrect={false}
              />
              <TouchableOpacity
                style={s.codeBtn}
                disabled={!!busy}
                onPress={() => run('promo', () => redeemPromo(code), '코드가 등록되었습니다.')}
              >
                {busy === 'promo'
                  ? <ActivityIndicator color={colors.bg} />
                  : <Text style={s.codeBtnTxt}>등록</Text>}
              </TouchableOpacity>
            </View>
          </>
        )}

        <TouchableOpacity
          style={s.restoreBtn}
          disabled={!!busy}
          onPress={() => run('restore', restore, '구독 정보를 불러왔습니다.')}
        >
          <Text style={s.restoreTxt}>구매 복원</Text>
        </TouchableOpacity>

        <Text style={s.notice}>
          {Platform.OS === 'web'
            ? '웹에서는 미리보기만 제공합니다. 구독은 앱에서 진행해주세요.'
            : '구독은 기간 만료 24시간 전까지 해지하지 않으면 자동으로 갱신됩니다. 해지는 기기의 구독 관리 화면에서 언제든 할 수 있습니다.'}
        </Text>
      </Body>
    </Screen>
  );
}

const s = StyleSheet.create({
  lead: { fontSize: 14, color: colors.ink, lineHeight: 22, marginTop: 4, marginBottom: 4 },

  activeBox: {
    backgroundColor: 'rgba(168,197,160,0.09)', borderRadius: 16, padding: 16,
    borderWidth: 1, borderColor: 'rgba(168,197,160,0.3)', marginTop: 6,
  },
  activeLabel: { fontSize: 9.5, fontWeight: '800', color: colors.good, letterSpacing: 1.5 },
  activeTxt: { fontSize: 15, fontWeight: '700', color: colors.ink, marginTop: 6 },
  activeSub: { fontSize: 11.5, color: colors.muted, marginTop: 6, lineHeight: 18 },

  row: {
    flexDirection: 'row', gap: 12, alignItems: 'flex-start',
    backgroundColor: colors.panel, borderRadius: 14, padding: 14,
    borderWidth: 1, borderColor: colors.line, marginBottom: 8,
  },
  rowFocus: { borderColor: colors.line2, backgroundColor: colors.panel2 },
  dot: {
    width: 7, height: 7, borderRadius: 4, marginTop: 5,
    backgroundColor: colors.muted, flexShrink: 0,
  },
  dotFocus: { backgroundColor: colors.ink },
  rowTitle: { fontSize: 14, fontWeight: '700', color: colors.ink },
  rowSub: { fontSize: 11.5, color: colors.muted, marginTop: 4, lineHeight: 18 },

  freeBox: {
    backgroundColor: colors.panel2, borderRadius: 14, padding: 14,
    borderWidth: 1, borderColor: colors.line, gap: 6,
  },
  freeTxt: { fontSize: 12.5, color: colors.mid, lineHeight: 19 },

  plan: {
    flexDirection: 'row', alignItems: 'center', gap: 12,
    backgroundColor: colors.panel, borderRadius: 16, padding: 16,
    borderWidth: 1, borderColor: colors.line, marginBottom: 8,
  },
  planOn: { borderColor: colors.ink, backgroundColor: colors.panel2 },
  planHead: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  planLabel: { fontSize: 15, fontWeight: '700', color: colors.mid },
  planLabelOn: { color: colors.ink },
  planNote: { fontSize: 11, color: colors.muted, marginTop: 4 },
  planPrice: { fontSize: 17, fontWeight: '800', color: colors.mid, letterSpacing: -0.3 },
  planPriceOn: { color: colors.ink },
  planPeriod: { fontSize: 11, fontWeight: '600', color: colors.muted },
  bestTag: { backgroundColor: colors.panel3, borderRadius: 6, paddingHorizontal: 6, paddingVertical: 2 },
  bestTxt: { fontSize: 9, fontWeight: '800', color: colors.mid },

  trialBtn: {
    borderWidth: 1, borderColor: colors.line2, borderRadius: 14,
    paddingVertical: 14, alignItems: 'center', marginTop: 10,
  },
  trialTxt: { fontSize: 14, fontWeight: '700', color: colors.ink },

  codeRow: { flexDirection: 'row', gap: 8 },
  codeInput: {
    flex: 1, backgroundColor: colors.panel2, borderWidth: 1, borderColor: colors.line2,
    borderRadius: 12, paddingHorizontal: 14, paddingVertical: 12, fontSize: 14, color: colors.ink,
  },
  codeBtn: {
    backgroundColor: colors.ink, borderRadius: 12, paddingHorizontal: 20,
    alignItems: 'center', justifyContent: 'center', minWidth: 72,
  },
  codeBtnTxt: { fontSize: 14, fontWeight: '700', color: colors.bg },

  restoreBtn: { alignItems: 'center', paddingVertical: 14, marginTop: 6 },
  restoreTxt: { fontSize: 12.5, color: colors.mid, fontWeight: '600' },

  notice: { fontSize: 10.5, color: colors.muted, lineHeight: 17, textAlign: 'center', marginTop: 2 },
});
