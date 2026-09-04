import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { HomeScreen } from '../screens/HomeScreen';
import { PlaceholderScreen } from '../screens/PlaceholderScreens';
import { useAppStore } from '../state/useAppStore';
import { colors } from '../theme/colors';

const Stack = createNativeStackNavigator();
const Tab = createBottomTabNavigator();

function MainTabs() {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarStyle: {
          backgroundColor: colors.surface,
          borderTopColor: colors.border,
          height: 60,
          paddingBottom: 8,
          paddingTop: 8,
        },
        tabBarActiveTintColor: colors.accent,
        tabBarInactiveTintColor: colors.textSecondary,
      }}
    >
      <Tab.Screen 
        name="HomeTab" 
        component={HomeScreen} 
        options={{ title: 'Home' }}
      />
      <Tab.Screen 
        name="WalletTab" 
        component={() => <PlaceholderScreen title="Wallet & Receive" />} 
        options={{ title: 'Wallet' }}
      />
      <Tab.Screen 
        name="ConvertTab" 
        component={() => <PlaceholderScreen title="Convert & Withdraw" />} 
        options={{ title: 'Convert' }}
      />
      <Tab.Screen 
        name="SettingsTab" 
        component={() => <PlaceholderScreen title="Settings & Profile" />} 
        options={{ title: 'Settings' }}
      />
    </Tab.Navigator>
  );
}

export function AppNavigator() {
  const isAuthenticated = useAppStore((state) => state.isAuthenticated);

  return (
    <NavigationContainer>
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        {!isAuthenticated ? (
          <Stack.Screen 
            name="Onboarding" 
            component={() => <PlaceholderScreen title="Onboarding & KYC" />} 
          />
        ) : (
          <Stack.Screen name="MainApp" component={MainTabs} />
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
}
