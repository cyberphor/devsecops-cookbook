import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  build: {
    // Disable using URIs for data directives (e.g., img-src, font-src).
    assetsInlineLimit: 0,
  }
});