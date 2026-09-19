import { Tabs } from 'expo-router';
import { View, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors } from '../../src/utils/colors';
import { useAppStore } from '../../src/stores/appStore';
import SessionPlayer from '../../src/components/SessionPlayer';
import SessionSummary from '../../src/components/SessionSummary';

type IoniconName = React.ComponentProps<typeof Ionicons>['name'];

function TabIcon({ name, focused }: { name: IoniconName; focused: boolean }) {
  return (
    <View style={[ic.wrap, focused && ic.wrapActive]}>
      <Ionicons name={name} size={22} color={focused ? colors.ink : colors.muted} />
    </View>
  );
}

const ic = StyleSheet.create({
  wrap: { width: 40, height: 30, borderRadius: 10, alignItems: 'center', justifyContent: 'center' },
  wrapActive: { backgroundColor: colors.panel2 },
});

export default function TabLayout() {
  // 세션·요약 오버레이는 탭 위에 올린다.
  // 개별 탭 화면에 두면 해당 탭을 떠나는 순간 진행 중인 운동이 사라진다.
  const session = useAppStore((s) => s.session);
  const summary = useAppStore((s) => s.summary);
  const overlay = !!session || !!summary;

  return (
    <View style={{ flex: 1, backgroundColor: colors.bg }}>
      <Tabs
        screenOptions={{
          headerShown: false,
          // 운동 중에는 탭 전환으로 세션을 벗어나지 않도록 탭바를 숨긴다
          tabBarStyle: overlay
            ? { display: 'none' }
            : {
                backgroundColor: colors.bg,
                borderTopColor: colors.line,
                borderTopWidth: 0.5,
                height: 72,
                paddingTop: 6,
                paddingBottom: 14,
              },
          tabBarActiveTintColor: colors.ink,
          tabBarInactiveTintColor: colors.muted,
          tabBarLabelStyle: { fontSize: 10, fontWeight: '600', letterSpacing: 0.2 },
          tabBarShowLabel: true,
        }}
      >
        <Tabs.Screen
          name="home"
          options={{
            title: '홈',
            tabBarIcon: ({ focused }) => <TabIcon name={focused ? 'home' : 'home-outline'} focused={focused} />,
          }}
        />
        <Tabs.Screen
          name="plan"
          options={{
            title: '운동',
            tabBarIcon: ({ focused }) => <TabIcon name={focused ? 'barbell' : 'barbell-outline'} focused={focused} />,
          }}
        />
        <Tabs.Screen
          name="form"
          options={{
            title: '자세',
            tabBarIcon: ({ focused }) => <TabIcon name={focused ? 'body' : 'body-outline'} focused={focused} />,
          }}
        />
        <Tabs.Screen
          name="diet"
          options={{
            title: '식단',
            tabBarIcon: ({ focused }) => <TabIcon name={focused ? 'nutrition' : 'nutrition-outline'} focused={focused} />,
          }}
        />
        <Tabs.Screen
          name="my"
          options={{
            title: 'MY',
            tabBarIcon: ({ focused }) => <TabIcon name={focused ? 'person' : 'person-outline'} focused={focused} />,
          }}
        />
      </Tabs>

      {session && <SessionPlayer />}
      <SessionSummary />
    </View>
  );
}
