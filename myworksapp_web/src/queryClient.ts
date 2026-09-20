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
  serviceByCategory: (category: string) =>
    ['services', 'byCategory', category] as const,
  workersByCategory: (category: string) =>
    ['workers', 'byCategory', category] as const,
};
