import { QueryClient } from '@tanstack/react-query';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

export const queryKeys = {
  adminMetrics: ['admin', 'metrics'] as const,
  adminWorkers: ['admin', 'workers'] as const,
  openDisputes: ['admin', 'disputes', 'open'] as const,
};
