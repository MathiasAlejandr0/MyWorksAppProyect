import { QueryClient } from '@tanstack/react-query';
import { CATALOG_GC_MS } from '@myworksapp/shared';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      gcTime: CATALOG_GC_MS,
      retry: (failureCount, error) => {
        const status = (error as { status?: number })?.status;
        if (status && status >= 400 && status < 500) return false;
        return failureCount < 1;
      },
      retryDelay: 800,
      refetchOnWindowFocus: true,
      refetchOnReconnect: true,
    },
  },
});

export const queryKeys = {
  adminMetrics: ['admin', 'metrics'] as const,
  adminWorkers: ['admin', 'workers'] as const,
  openDisputes: ['admin', 'disputes', 'open'] as const,
};
