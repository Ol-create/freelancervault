import { useQuery } from '@tanstack/react-query';
import { apiClient } from './client';

export function useHealthCheck() {
  return useQuery({
    queryKey: ['healthCheck'],
    queryFn: async () => {
      const response = await apiClient.get<{ status: string }>('/health');
      return response.data;
    },
    retry: 2,
  });
}
