import { Tabs } from 'expo-router';
import { View, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors } from '../../src/utils/colors';

type IoniconName = React.ComponentProps<typeof Ionicons>['name'];

function TabIcon({
  name,
  focused,
}: {
  name: IoniconName;
  focused: boolean;
}) {
  return (
    <View style={[ic.wrap, focused && ic.wrapActive]}>
      <Ionicons
        name={name}
        size={22}
        color={focused ? colors.ink : colors.muted}
      />
    </View>
  );
}

const ic = StyleSheet.create({
  wrap: {
    width: 40,
    height: 30,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  wrapActive: { backgroundColor: colors.panel2 },
});

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarStyle: {
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
          tabBarIcon: ({ focused }) => (
            <TabIcon name={focused ? 'home' : 'home-outline'} focused={focused} />
          ),
        }}
      />
      <Tabs.Screen
        name="plan"
        options={{
          title: '운동',
          tabBarIcon: ({ focused }) => (
            <TabIcon name={focused ? 'barbell' : 'barbell-outline'} focused={focused} />
          ),
        }}
      />
      <Tabs.Screen
        name="form"
        options={{
          title: '자세',
          tabBarIcon: ({ focused }) => (
            <TabIcon name={focused ? 'body' : 'body-outline'} focused={focused} />
          ),
        }}
      />
      <Tabs.Screen
        name="diet"
        options={{
          title: '식단',
          tabBarIcon: ({ focused }) => (
            <TabIcon name={focused ? 'nutrition' : 'nutrition-outline'} focused={focused} />
          ),
        }}
      />
      <Tabs.Screen
        name="my"
        options={{
          title: 'MY',
          tabBarIcon: ({ focused }) => (
            <TabIcon name={focused ? 'person' : 'person-outline'} focused={focused} />
          ),
        }}
      />
    </Tabs>
  );
}
