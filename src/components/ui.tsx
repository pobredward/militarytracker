import { ReactNode } from 'react';
import {
  View, Text, StyleSheet, TouchableOpacity, ActivityIndicator,
  ScrollView, StyleProp, ViewStyle, TextStyle,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { colors } from '../utils/colors';

export function Screen({ children }: { children: ReactNode }) {
  return (
    <SafeAreaView style={s.screen} edges={['top']}>
      {children}
    </SafeAreaView>
  );
}

export function TopBar({
  title, meta, onBack, right,
}: { title: string; meta?: string; onBack?: () => void; right?: ReactNode }) {
  return (
    <View style={s.topbar}>
      {onBack ? (
        <TouchableOpacity onPress={onBack} hitSlop={12} style={s.backWrap}>
          <Text style={s.back}>←</Text>
          <Text style={s.backTitle} numberOfLines={1}>{title}</Text>
        </TouchableOpacity>
      ) : (
        <Text style={s.title}>{title}</Text>
      )}
      {right ?? (meta ? <Text style={s.meta}>{meta}</Text> : null)}
    </View>
  );
}

export function Body({ children, style }: { children: ReactNode; style?: StyleProp<ViewStyle> }) {
  return (
    <ScrollView style={s.scroll} contentContainerStyle={[s.scrollInner, style]} showsVerticalScrollIndicator={false}>
      {children}
    </ScrollView>
  );
}

export function Card({ children, style }: { children: ReactNode; style?: StyleProp<ViewStyle> }) {
  return <View style={[s.card, style]}>{children}</View>;
}

export function SectionLabel({ children, style }: { children: ReactNode; style?: StyleProp<TextStyle> }) {
  return <Text style={[s.sectionLabel, style]}>{children}</Text>;
}

export function PrimaryBtn({
  label, onPress, loading, disabled, style,
}: { label: string; onPress: () => void; loading?: boolean; disabled?: boolean; style?: StyleProp<ViewStyle> }) {
  const off = loading || disabled;
  return (
    <TouchableOpacity style={[s.primary, off && s.off, style]} onPress={onPress} disabled={off}>
      {loading ? <ActivityIndicator color={colors.bg} /> : <Text style={s.primaryTxt}>{label}</Text>}
    </TouchableOpacity>
  );
}

export function GhostBtn({
  label, onPress, loading, disabled, style,
}: { label: string; onPress: () => void; loading?: boolean; disabled?: boolean; style?: StyleProp<ViewStyle> }) {
  const off = loading || disabled;
  return (
    <TouchableOpacity style={[s.ghost, off && s.off, style]} onPress={onPress} disabled={off}>
      {loading ? <ActivityIndicator color={colors.mid} /> : <Text style={s.ghostTxt}>{label}</Text>}
    </TouchableOpacity>
  );
}

export function EmptyState({ text }: { text: string }) {
  return (
    <View style={s.empty}>
      <Text style={s.emptyTxt}>{text}</Text>
    </View>
  );
}

export function Notice({ children }: { children: ReactNode }) {
  return <Text style={s.notice}>{children}</Text>;
}

const s = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.bg },
  topbar: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
    paddingHorizontal: 20, paddingTop: 14, paddingBottom: 8, gap: 12,
  },
  title: { fontSize: 22, fontWeight: '800', color: colors.ink, letterSpacing: -0.3, flexShrink: 1 },
  backWrap: { flexDirection: 'row', alignItems: 'center', gap: 8, flexShrink: 1 },
  back: { fontSize: 20, color: colors.ink, fontWeight: '600' },
  backTitle: { fontSize: 17, fontWeight: '700', color: colors.ink, flexShrink: 1 },
  meta: { fontSize: 10, color: colors.muted, letterSpacing: 1, flexShrink: 0 },
  scroll: { flex: 1 },
  scrollInner: { paddingHorizontal: 16, paddingBottom: 40 },
  card: {
    backgroundColor: colors.panel, borderRadius: 18, padding: 18,
    borderWidth: 1, borderColor: colors.line, marginBottom: 12,
  },
  sectionLabel: {
    fontSize: 9.5, fontWeight: '800', color: colors.muted,
    letterSpacing: 2, marginBottom: 10, marginTop: 8,
  },
  pill: {
    backgroundColor: colors.panel2, borderRadius: 14,
    paddingHorizontal: 16, paddingVertical: 9,
    borderWidth: 1, borderColor: colors.line, alignItems: 'center', minWidth: 72,
  },
  pillOn: { backgroundColor: colors.ink, borderColor: colors.ink },
  pillTxt: { fontSize: 12.5, fontWeight: '700', color: colors.muted },
  pillTxtOn: { color: colors.bg },
  pillSub: { fontSize: 10, color: colors.muted, marginTop: 2 },
  pillSubOn: { color: 'rgba(9,9,10,0.62)' },
  primary: {
    backgroundColor: colors.ink, borderRadius: 14,
    paddingVertical: 15, alignItems: 'center',
  },
  primaryTxt: { color: colors.bg, fontSize: 15, fontWeight: '700' },
  ghost: {
    borderWidth: 1, borderColor: colors.line2, borderRadius: 14,
    paddingVertical: 14, alignItems: 'center',
  },
  ghostTxt: { color: colors.mid, fontSize: 14, fontWeight: '600' },
  off: { opacity: 0.4 },
  empty: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 28 },
  emptyTxt: { color: colors.muted, fontSize: 14, textAlign: 'center', lineHeight: 22 },
  notice: { fontSize: 10.5, color: colors.muted, lineHeight: 16, textAlign: 'center', marginTop: 4 },
});
