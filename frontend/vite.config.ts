// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Hinweis: Fast Refresh ist AUS (fastRefresh: false), damit keine Inline-Skripte nötig sind.
// Wenn du später wieder Fast Refresh willst, musst du deine CSP anpassen (Hash/Nonce).

export default defineConfig({
  plugins: [
    react({
      fastRefresh: false,
      // Optional: klassische React-Refresh-Overlay-Logs aus
      // jsxImportSource: undefined,
      // babel: undefined,
    }),
  ],
  server: {
    port: 5173,
    strictPort: true,
    open: false,
    // Wenn du eine sehr strikte CSP per Dev-Proxy-Header setzt, NICHT hier überschreiben.
    // headers: { 'Content-Security-Policy': "script-src 'self' ..." }
  },
  preview: {
    port: 4173,
    strictPort: true,
  },
  // Häufig hilfreich: klare Targets, damit keine exotischen Transformationspfade Inline-Code erzeugen
  build: {
    target: 'es2020',
    sourcemap: true,
    outDir: 'dist',
  },
  esbuild: {
    target: 'es2020',
  },
})

