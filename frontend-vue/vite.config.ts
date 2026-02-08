import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [
    vue({
      template: {
        compilerOptions: {
          isCustomElement: (tag) => tag.startsWith('appkit-')
        }
      }
    })
  ],

  // DEV only: Fuji RPC über Vite Proxy (same-origin)
  server: {
    proxy: {
      '/fuji': {
        // ✅ target darf NICHT schon /ext/bc/C/rpc enthalten
        target: 'https://api.avax-test.network',
        changeOrigin: true,
        secure: true,

        // ✅ rewrite setzt den Pfad genau 1x
        rewrite: (path) => path.replace(/^\/fuji/, '/ext/bc/C/rpc')
      }
    }
  },

  build: {
    // Reduce noise for large vendor bundles (walletconnect/viem/etc.).
    chunkSizeWarningLimit: 2500,
    rollupOptions: {
      onwarn(warning, warn) {
        const msg = String((warning as any)?.message ?? '')
        if (
          (warning as any)?.code === 'INVALID_ANNOTATION' &&
          msg.includes('/*#__PURE__*/')
        ) {
          return
        }
        warn(warning)
      }
    }
  }
})
