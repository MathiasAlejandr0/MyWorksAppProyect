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
  clearScreen: false,
  server: {
    port: 3001,
    strictPort: true,
  },
  envPrefix: ['VITE_', 'TAURI_'],
  build: process.env.TAURI_ENV_PLATFORM
    ? {
        target: process.env.TAURI_ENV_PLATFORM === 'windows' ? 'chrome105' : 'safari13',
        minify: !process.env.TAURI_ENV_DEBUG ? 'esbuild' : false,
        sourcemap: !!process.env.TAURI_ENV_DEBUG,
      }
    : undefined,
});
