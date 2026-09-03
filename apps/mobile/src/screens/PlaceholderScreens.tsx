import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

function SimpleScreen({ title }: { title: string }) {
  return (
    <View style={styles.center}>
      <Text style={styles.text}>{title} Screen</Text>
    </View>
  );
}

export const OnboardingScreen = () => <SimpleScreen title="Onboarding" />;
export const ReceiveScreen = () => <SimpleScreen title="Receive Payments (Fiat & Crypto)" />;
export const HistoryScreen = () => <SimpleScreen title="Transaction History" />;
export const ConvertScreen = () => <SimpleScreen title="Convert Crypto ↔ Fiat" />;
export const WithdrawScreen = () => <SimpleScreen title="Withdraw Funds" />;
export const SettingsScreen = () => <SimpleScreen title="Settings" />;

const styles = StyleSheet.create({
  center: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#F8F9FA' },
  text: { fontSize: 18, fontWeight: '600', color: '#444' },
});
