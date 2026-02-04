<script setup lang="ts">
import { formatUnits } from 'ethers'
import { TOKENS } from '../../contracts/addresses'
import ErrorPopupInline from '../common/ErrorPopupInline.vue'

defineProps<{
  totalMined: bigint
  totalStaked: bigint
  feeVaultMebtc: bigint
  demandVaultUsdc: bigint
  poolMebtc: bigint
  poolUsdc: bigint
  totalEffectiveHash: bigint
  soldMiners: bigint
  mebtcDecimals: number
  firstMinerCreatedAt: bigint | null
  blockTime: number | null
  nextSlotInSeconds: number | null
  loading: boolean
  error: string
}>()

function formatTs(ts: bigint | null) {
  if (!ts) return '-'
  const ms = Number(ts) * 1000
  if (!Number.isFinite(ms) || ms <= 0) return '-'
  return new Date(ms)
    .toISOString()
    .replace('T', ' ')
    .replace('.000', '')
    .replace('Z', ' UTC')
}

function formatWhole(amount: bigint, decimals: number) {
  const s = formatUnits(amount, decimals)
  const i = s.indexOf('.')
  return i === -1 ? s : s.slice(0, i)
}

function formatRemaining(seconds: number | null) {
  if (seconds === null) return '-'
  if (!Number.isFinite(seconds) || seconds < 0) return '-'
  const mins = Math.floor(seconds / 60)
  const secs = Math.floor(seconds % 60)
  return `${mins}m ${secs.toString().padStart(2, '0')}s`
}

function formatHashRate(value: bigint) {
  const units = ['Hash/s', 'kH/s', 'MH/s', 'GH/s', 'TH/s', 'PH/s', 'EH/s']
  const base = 1_000n

  let unitIndex = 0
  let scaled = value
  while (scaled >= base && unitIndex < units.length - 1) {
    scaled = scaled / base
    unitIndex++
  }

  const denom = base ** BigInt(unitIndex)
  if (unitIndex === 0) return `${value.toString()} ${units[unitIndex]}`

  const whole = value / denom
  const frac = ((value % denom) * 100n) / denom
  const fracText = frac.toString().padStart(2, '0')
  return `${whole.toString()}.${fracText} ${units[unitIndex]}`
}
</script>

<template>
  <div style="min-width:220px;">
    <details class="ui-dropdown">
      <summary>
        <span class="ui-row">
          <svg
            viewBox="0 0 24 24"
            width="14"
            height="14"
            aria-hidden="true"
            style="display:block"
          >
            <path
              d="M9.2 3.5 4.6 8.1l2.3 2.3 2-2L13 12.5l-2 2 2.3 2.3 4.6-4.6a2 2 0 0 0 0-2.8L12 3.5a2 2 0 0 0-2.8 0Z"
              fill="currentColor"
            />
            <path
              d="M3 18.5 7.5 14l2 2-4.5 4.5a1.4 1.4 0 0 1-2-2Z"
              fill="currentColor"
            />
          </svg>
          <span>Mining stats</span>
        </span>
      </summary>
      <div style="margin-top:8px;">
        <div v-if="loading" style="font-size:11px;">loading…</div>
        <div v-else class="ui-meta">
          <div>Start Miner #1: {{ formatTs(firstMinerCreatedAt) }}</div>
          <div>
            Rewards gesamt:
            <b>{{ formatWhole(totalMined, mebtcDecimals) }} {{ TOKENS.mebtc.symbol }}</b>
          </div>
          <div>Blockzeit: {{ blockTime === null ? '-' : blockTime }}</div>
          <div>Nächster Block in: {{ formatRemaining(nextSlotInSeconds) }}</div>
          <div>Miner aktiv: {{ soldMiners.toString() }}</div>
          <div>Miner verkauft: {{ soldMiners.toString() }}</div>
          <div>Hashrate gesamt: {{ formatHashRate(totalEffectiveHash) }}</div>
          <div>
            MeBTC gestakt:
            <b>{{ formatUnits(totalStaked, mebtcDecimals) }}</b>
          </div>
          <div>
            FeeVault MeBTC:
            <b>{{ formatUnits(feeVaultMebtc, mebtcDecimals) }}</b>
          </div>
          <div>
            DemandVault USDC:
            <b>{{ formatUnits(demandVaultUsdc, TOKENS.usdc.decimals) }}</b>
          </div>
          <div>
            Pool MeBTC:
            <b>{{ formatUnits(poolMebtc, mebtcDecimals) }}</b>
          </div>
          <div>
            Pool USDC:
            <b>{{ formatUnits(poolUsdc, TOKENS.usdc.decimals) }}</b>
          </div>
          <ErrorPopupInline :error="error" context="Mining Stats" />
        </div>
      </div>
    </details>
  </div>
</template>
