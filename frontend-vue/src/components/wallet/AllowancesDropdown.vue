<script setup lang="ts">
import { onBeforeUnmount, ref } from 'vue'
import { formatUnits } from 'ethers'
import Button from '../common/Button.vue'
import Card from '../common/Card.vue'

defineProps<{
  disabled: boolean
  loading: boolean
  minerText: string
  managerText: string
  payTokenSymbol: string
  payTokenDecimals: number
  approveExactMissing: bigint
  approveManagerExactMissing: bigint

  routerLoading: boolean
  routerUsdcAllowanceText: string
  routerMebtcAllowanceText: string
  routerLpAllowanceText: string

  mebtcLoading: boolean
  mebtcStakeAllowanceText: string
  mebtcManagerAllowanceText: string
  mebtcUpgradeAllowanceText: string
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

function fmt(v: bigint, decimals: number) {
  return formatUnits(v, decimals)
}

function needsApprove(minerMissing: bigint, managerMissing: bigint) {
  return minerMissing > 0n || managerMissing > 0n
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
      :disabled="disabled"
      @focus="openPopover"
      @click="open = true"
    >
      <span>Approvals</span>
      <span
        v-if="needsApprove(approveExactMissing, approveManagerExactMissing)"
        class="ui-badge"
        style="border-color:#b00;color:#b00;"
      >
        Approve nötig
      </span>
    </Button>
    <div v-if="open" class="hover-popover-panel">
      <Card title="Approvals" class="hover-popover-card">
        <div style="margin-top:4px;">
          <div class="ui-subtitle">Pay token ({{ payTokenSymbol }})</div>
          <div v-if="loading">loading…</div>
          <div v-else>
            <div>allowance minerNFT (buy/upgrade): {{ minerText }}</div>
            <div>allowance manager (claim fee): {{ managerText }}</div>
            <div v-if="needsApprove(approveExactMissing, approveManagerExactMissing)" class="ui-muted" style="margin-top:6px;">
              missing miner: {{ fmt(approveExactMissing, payTokenDecimals) }} {{ payTokenSymbol }} | missing manager: {{ fmt(approveManagerExactMissing, payTokenDecimals) }} {{ payTokenSymbol }}
            </div>
          </div>

          <div class="ui-subtitle" style="margin-top:12px;">Router (Swap/Liquidity)</div>
          <div v-if="routerLoading">loading…</div>
          <div v-else>
            <div>allowance USDC: {{ routerUsdcAllowanceText }}</div>
            <div>allowance MeBTC: {{ routerMebtcAllowanceText }}</div>
            <div>allowance LP: {{ routerLpAllowanceText }}</div>
          </div>

          <div class="ui-subtitle" style="margin-top:12px;">MeBTC (Stake/Claim/Upgrade)</div>
          <div v-if="mebtcLoading">loading…</div>
          <div v-else>
            <div>allowance stakeVault: {{ mebtcStakeAllowanceText }}</div>
            <div>allowance manager (claim): {{ mebtcManagerAllowanceText }}</div>
            <div>allowance miner (upgrade): {{ mebtcUpgradeAllowanceText }}</div>
          </div>
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
}

.hover-popover-panel {
  position: absolute;
  top: calc(100% + 8px);
  right: 0;
  z-index: 80;
  width: min(92vw, 620px);
}

.hover-popover-card {
  max-height: min(78vh, 700px);
  overflow: auto;
}
</style>
