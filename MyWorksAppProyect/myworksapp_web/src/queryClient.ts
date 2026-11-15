import { QueryClient } from '@tanstack/react-query';
import { CATALOG_GC_MS, CATALOG_STALE_MS } from '@myworksapp/shared';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: CATALOG_STALE_MS,
      gcTime: CATALOG_GC_MS,
      retry: (failureCount, error) => {
        const status = (error as { status?: number })?.status;
        if (status && status >= 400 && status < 500) return false;
        return failureCount < 1;
      },
      retryDelay: 800,
      refetchOnWindowFocus: false,
      refetchOnReconnect: false,
    },
  },
});

export const queryKeys = {
  activeServices: ['catalog', 'services'] as const,
  serviceByCategory: (category: string) =>
    ['catalog', 'services', 'byCategory', category] as const,
  workersByCategory: (category: string) =>
    ['catalog', 'workers', category] as const,
};
