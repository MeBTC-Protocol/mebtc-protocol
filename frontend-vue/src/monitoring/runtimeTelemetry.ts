import { ENV } from '../config/env'

type BaseEvent = {
  ts: string
  source: 'frontend-vue'
  env: string
  event: string
}

export type ClaimMode = 'usdc' | 'mixed'

export type ClaimResultStatus = 'success' | 'revert' | 'rpc_error' | 'user_rejected' | 'other_error'

export type ClaimReasonClass =
  | 'none'
  | 'slot'
  | 'allowance'
  | 'balance'
  | 'rpc'
  | 'user_rejected'
  | 'other'

const lastUiErrorEmissionAt = new Map<string, number>()

function nowIso(): string {
  return new Date().toISOString()
}

function shorten(raw: string, maxLen = 400): string {
  const compact = raw.replace(/\s+/g, ' ').trim()
  if (compact.length <= maxLen) return compact
  return compact.slice(0, maxLen)
}

function extractErrorMessage(err: unknown): string {
  if (!err) return ''
  if (typeof err === 'string') return err
  if (typeof err === 'object') {
    const anyErr = err as Record<string, unknown>
    const parts = [
      anyErr.shortMessage,
      anyErr.message,
      anyErr.reason,
      anyErr.code,
      (anyErr.cause as Record<string, unknown> | undefined)?.shortMessage,
      (anyErr.cause as Record<string, unknown> | undefined)?.message
    ]
    return parts
      .map(p => (typeof p === 'string' ? p : ''))
      .filter(Boolean)
      .join(' | ')
  }
  return String(err)
}

function emit(payload: BaseEvent & Record<string, unknown>) {
  const body = JSON.stringify(payload)
  if (ENV.MONITORING_LOG_TO_CONSOLE) {
    console.info('[monitoring]', body)
  }

  const url = ENV.MONITORING_INGEST_URL
  if (!url) return

  if (typeof navigator !== 'undefined' && typeof navigator.sendBeacon === 'function') {
    const ok = navigator.sendBeacon(url, new Blob([body], { type: 'application/json' }))
    if (ok) return
  }

  if (typeof fetch === 'function') {
    void fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body,
      keepalive: true
    }).catch(() => {})
  }
}

export function isRpcErrorMessage(raw: string): boolean {
  const text = raw.toLowerCase()
  return [
    'rpc',
    'timeout',
    'timed out',
    'failed to fetch',
    'network error',
    'network changed',
    'temporarily unavailable',
    '429',
    '502',
    '503',
    '504',
    'json-rpc',
    'could not connect',
    'connection refused'
  ].some(needle => text.includes(needle))
}

function classifyClaimReasonFromText(text: string): ClaimReasonClass {
  if (
    text.includes('slot') ||
    text.includes('too early') ||
    text.includes('claimonlyafterglobalslot')
  ) {
    return 'slot'
  }
  if (text.includes('allowance') || text.includes('insufficient approval')) {
    return 'allowance'
  }
  if (
    text.includes('insufficient balance') ||
    text.includes('exceeds balance') ||
    text.includes('insufficient funds')
  ) {
    return 'balance'
  }
  return 'other'
}

export function classifyClaimFailure(raw: string): {
  status: ClaimResultStatus
  reasonClass: ClaimReasonClass
} {
  const text = raw.toLowerCase()

  if (
    text.includes('user rejected') ||
    text.includes('action_rejected') ||
    text.includes('denied transaction')
  ) {
    return { status: 'user_rejected', reasonClass: 'user_rejected' }
  }

  if (isRpcErrorMessage(text)) {
    return { status: 'rpc_error', reasonClass: 'rpc' }
  }

  if (text.includes('revert') || text.includes('execution reverted') || text.includes('custom error')) {
    return { status: 'revert', reasonClass: classifyClaimReasonFromText(text) }
  }

  return { status: 'other_error', reasonClass: classifyClaimReasonFromText(text) }
}

export function emitUiRpcError(context: string, rawError: unknown) {
  const message = shorten(extractErrorMessage(rawError))
  if (!message || !isRpcErrorMessage(message)) return

  const dedupeKey = `${context}|${message}`
  const now = Date.now()
  const last = lastUiErrorEmissionAt.get(dedupeKey) ?? 0
  if (now - last < 15_000) return
  lastUiErrorEmissionAt.set(dedupeKey, now)

  emit({
    ts: nowIso(),
    source: 'frontend-vue',
    env: ENV.MONITORING_ENV,
    event: 'ui.rpc_error',
    context,
    message
  })
}

export function emitClaimAttempt(params: { mode: ClaimMode; tokenCount: number; mebtcShareBps: number }) {
  emit({
    ts: nowIso(),
    source: 'frontend-vue',
    env: ENV.MONITORING_ENV,
    event: 'claim.attempt',
    mode: params.mode,
    token_count: params.tokenCount,
    mebtc_share_bps: params.mebtcShareBps
  })
}

export function emitClaimSuccess(params: { mode: ClaimMode; tokenCount: number; mebtcShareBps: number }) {
  emit({
    ts: nowIso(),
    source: 'frontend-vue',
    env: ENV.MONITORING_ENV,
    event: 'claim.result',
    status: 'success',
    reason_class: 'none',
    mode: params.mode,
    token_count: params.tokenCount,
    mebtc_share_bps: params.mebtcShareBps
  })
}

export function emitClaimFailure(params: {
  mode: ClaimMode
  tokenCount: number
  mebtcShareBps: number
  rawError: unknown
}) {
  const raw = shorten(extractErrorMessage(params.rawError))
  const classification = classifyClaimFailure(raw)
  emit({
    ts: nowIso(),
    source: 'frontend-vue',
    env: ENV.MONITORING_ENV,
    event: 'claim.result',
    status: classification.status,
    reason_class: classification.reasonClass,
    mode: params.mode,
    token_count: params.tokenCount,
    mebtc_share_bps: params.mebtcShareBps,
    error: raw
  })
}

let globalHandlersInstalled = false

export function installGlobalRuntimeMonitoring() {
  if (globalHandlersInstalled || typeof window === 'undefined') return
  globalHandlersInstalled = true

  window.addEventListener('error', (event) => {
    const raw = extractErrorMessage(event.error ?? event.message)
    emitUiRpcError('window.error', raw)
  })

  window.addEventListener('unhandledrejection', (event) => {
    const raw = extractErrorMessage(event.reason)
    emitUiRpcError('window.unhandledrejection', raw)
  })
}
