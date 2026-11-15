import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@myworksapp/shared': path.resolve(__dirname, '../shared/src'),
    },
  },
  server: {
    proxy: {
      '/api/photon': {
        target: 'https://photon.komoot.io',
        changeOrigin: true,
        rewrite: (pathname) => pathname.replace(/^\/api\/photon/, '/api'),
      },
    },
  },
  build: {
    rollupOptions: {
      output: {
        // El mapa (MapLibre + Leaflet, ~1,2 MB) solo se pide al abrir la
        // búsqueda. React, Supabase y React Query van en chunks propios para
        // descargarse en paralelo y quedar en caché entre despliegues.
        manualChunks(id) {
          if (
            id.includes('node_modules/leaflet') ||
            id.includes('node_modules/maplibre-gl') ||
            id.includes('node_modules/@maplibre/')
          ) {
            return 'map';
          }
          if (/node_modules\/(react|react-dom|scheduler)\//.test(id)) return 'vendor-react';
          if (id.includes('node_modules/@supabase/')) return 'vendor-supabase';
          if (id.includes('node_modules/@tanstack/')) return 'vendor-query';
        },
      },
    },
  },
});
