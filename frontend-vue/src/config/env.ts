function required(name: string): string {
  const v = (import.meta.env as any)[name]
  if (typeof v !== 'string' || v.trim().length === 0) {
    throw new Error(`${name} fehlt oder ist leer (.env)`)
  }
  return v.trim()
}

function optional(name: string, fallback: string): string {
  const v = (import.meta.env as any)[name]
  return typeof v === 'string' && v.trim().length > 0 ? v.trim() : fallback
}

function optionalBool(name: string, fallback: boolean): boolean {
  const v = (import.meta.env as any)[name]
  if (typeof v !== 'string') return fallback
  const normalized = v.trim().toLowerCase()
  if (['1', 'true', 'yes', 'on'].includes(normalized)) return true
  if (['0', 'false', 'no', 'off'].includes(normalized)) return false
  return fallback
}

/**
 * Ethers v6 akzeptiert KEINE relative RPC-URL wie "/fuji".
 * DEV: wir erlauben "/fuji", wandeln aber zur Laufzeit in absolute URL um:
 *   http://localhost:5173/fuji
 */
function normalizeRpcUrl(raw: string): string {
  const v = raw.trim()

  // Already absolute
  if (/^https?:\/\//i.test(v) || /^wss?:\/\//i.test(v)) return v

  // Relative path -> make absolute in browser
  if (v.startsWith('/') && typeof window !== 'undefined' && window.location?.origin) {
    return `${window.location.origin}${v}`
  }

  // Fallback: gib raw zurück (damit der Fehler klar bleibt, statt still zu "raten")
  return v
}

export const ENV = {
  REOWN_PROJECT_ID: required('VITE_REOWN_PROJECT_ID'),
  APP_URL: optional('VITE_APP_URL', 'http://localhost:5173'),

  FUJI_RPC_URL: normalizeRpcUrl(
    optional('VITE_FUJI_RPC_URL', 'https://api.avax-test.network/ext/bc/C/rpc')
  ),
  AVALANCHE_RPC_URL: normalizeRpcUrl(
    optional('VITE_AVALANCHE_RPC_URL', 'https://api.avax.network/ext/bc/C/rpc')
  ),
  TARGET_CHAIN_ID: optional('VITE_TARGET_CHAIN_ID', '43113'),

  MONITORING_INGEST_URL: optional('VITE_MONITORING_INGEST_URL', ''),
  MONITORING_ENV: optional('VITE_MONITORING_ENV', 'development'),
  MONITORING_LOG_TO_CONSOLE: optionalBool('VITE_MONITORING_LOG_TO_CONSOLE', false)
} as const
