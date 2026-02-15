<script setup lang="ts">
import { onBeforeUnmount, ref } from 'vue'
import { formatUnits } from 'ethers'
import { TOKENS } from '../../contracts/addresses'
import Button from '../common/Button.vue'
import Card from '../common/Card.vue'
import ErrorPopupInline from '../common/ErrorPopupInline.vue'
import { formatHashRateFromGh } from '../../utils/hashrate'

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

const open = ref(false)
let closeTimer: number | null = null

function cancelClose() {
  if (closeTimer !== null) {
    window.clearTimeout(closeTimer)
    closeTimer = null
  }
}

function openPopover() {
  cancelClose()
  open.value = true
}

function scheduleClose() {
  cancelClose()
  closeTimer = window.setTimeout(() => {
    open.value = false
    closeTimer = null
  }, 120)
}

onBeforeUnmount(() => {
  cancelClose()
})

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

function pow10(decimals: number) {
  let v = 1n
  for (let i = 0; i < decimals; i++) v *= 10n
  return v
}

function formatWhole(amount: bigint, decimals: number) {
  if (decimals <= 0) return amount.toString()
  const scale = pow10(decimals)
  const rounded = (amount + scale / 2n) / scale
  return rounded.toString()
}

function formatRemaining(seconds: number | null) {
  if (seconds === null) return '-'
  if (!Number.isFinite(seconds) || seconds < 0) return '-'
  const mins = Math.floor(seconds / 60)
  const secs = Math.floor(seconds % 60)
  return `${mins}m ${secs.toString().padStart(2, '0')}s`
}

</script>

<template>
  <div
    class="hover-popover-wrap"
    @mouseenter="openPopover"
    @mouseleave="scheduleClose"
    @focusin="openPopover"
    @focusout="scheduleClose"
  >
    <Button
      size="sm"
      variant="ghost"
      @click="open = true"
    >
      <span class="ui-row">
        <img src="/Pickaxe.png" alt="" aria-hidden="true" class="mining-stats-icon" />
        <span>Mining stats</span>
      </span>
    </Button>

    <div v-if="open" class="hover-popover-panel">
      <Card title="Mining stats" class="hover-popover-card">
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
            <div>Hashrate gesamt: {{ formatHashRateFromGh(totalEffectiveHash) }}</div>
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
          </div>
          <ErrorPopupInline :error="error" context="Mining Stats" />
        </div>

        <div class="ui-row" style="margin-top:14px;">
          <Button size="sm" @click="open = false">Schließen</Button>
        </div>
      </Card>
    </div>
  </div>
</template>

<style scoped>
.hover-popover-wrap {
  position: relative;
  width: fit-content;
  min-width: 220px;
}

.hover-popover-panel {
  position: absolute;
  top: calc(100% + 8px);
  right: 0;
  z-index: 80;
  width: min(92vw, 560px);
}

.hover-popover-card {
  max-height: min(78vh, 700px);
  overflow: auto;
}

.mining-stats-icon {
  width: 14px;
  height: 14px;
  object-fit: contain;
  display: block;
}
</style>
