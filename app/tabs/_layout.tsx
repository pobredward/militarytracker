import { Tabs } from 'expo-router';
import { Text } from 'react-native';
import { Colors } from '../../src/utils/colors';

function TabIcon({ emoji, label, focused }: { emoji: string; label: string; focused: boolean }) {
  return (
    <Text style={{ fontSize: focused ? 24 : 22, opacity: focused ? 1 : 0.5 }}>{emoji}</Text>
  );
}

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: Colors.primary,
        tabBarInactiveTintColor: Colors.textMuted,
        tabBarStyle: {
          backgroundColor: Colors.white,
          borderTopColor: Colors.border,
          borderTopWidth: 1,
          height: 60,
          paddingBottom: 8,
        },
        tabBarLabelStyle: { fontSize: 11, fontWeight: '600' },
      }}
    >
      <Tabs.Screen
        name="home"
        options={{
          title: '홈',
          tabBarIcon: ({ focused }) => <TabIcon emoji="🏠" label="홈" focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="workout"
        options={{
          title: '운동',
          tabBarIcon: ({ focused }) => <TabIcon emoji="💪" label="운동" focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="community"
        options={{
          title: '커뮤니티',
          tabBarIcon: ({ focused }) => <TabIcon emoji="👥" label="커뮤니티" focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: '프로필',
          tabBarIcon: ({ focused }) => <TabIcon emoji="👤" label="프로필" focused={focused} />,
        }}
      />
    </Tabs>
  );
}
