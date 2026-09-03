import React, { useEffect } from 'react';
import { View, Text, StyleSheet, Button, ActivityIndicator } from 'react-native';
import { useHealthCheck } from '../api/useHealthCheck';
import { useWallet } from '../wallet/useWallet';

export function HomeScreen() {
  const { data: health, isLoading: healthLoading, isError: healthError } = useHealthCheck();
  const { address, loading: walletLoading, error: walletError, checkWalletStatus } = useWallet();

  useEffect(() => {
    checkWalletStatus();
  }, [checkWalletStatus]);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>FreelancerVault</Text>

      <View style={styles.card}>
        <Text style={styles.subtitle}>Backend Connection:</Text>
        {healthLoading ? (
          <ActivityIndicator color="#000" />
        ) : healthError ? (
          <Text style={styles.error}>Disconnected</Text>
        ) : (
          <Text style={styles.success}>Connected ({health?.status})</Text>
        )}
      </View>

      <View style={styles.card}>
        <Text style={styles.subtitle}>Embedded Wallet Status:</Text>
        {walletLoading ? (
          <ActivityIndicator color="#000" />
        ) : address ? (
          <Text style={styles.success}>Address: {address}</Text>
        ) : (
          <Text style={styles.warning}>
            {walletError ? `SDK Status: ${walletError}` : 'No Wallet Provisioned'}
          </Text>
        )}
        <View style={styles.buttonSpacer}>
          <Button title="Check Wallet Status" onPress={checkWalletStatus} />
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20, justifyContent: 'center', backgroundColor: '#F8F9FA' },
  title: { fontSize: 26, fontWeight: 'bold', marginBottom: 24, textAlign: 'center', color: '#111' },
  card: { backgroundColor: '#FFF', padding: 18, borderRadius: 12, marginBottom: 16, elevation: 2 },
  subtitle: { fontSize: 16, fontWeight: '600', marginBottom: 8, color: '#333' },
  success: { color: '#2E7D32', fontWeight: 'bold', fontSize: 14 },
  error: { color: '#C62828', fontWeight: 'bold', fontSize: 14 },
  warning: { color: '#EF6C00', marginBottom: 12, fontSize: 14 },
  buttonSpacer: { marginTop: 8 },
});
