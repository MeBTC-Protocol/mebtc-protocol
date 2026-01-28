<script setup lang="ts">
import { formatUnits } from 'ethers'

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

function fmt(v: bigint, decimals: number) {
  return formatUnits(v, decimals)
}

function needsApprove(minerMissing: bigint, managerMissing: bigint) {
  return minerMissing > 0n || managerMissing > 0n
}
</script>

<template>
  <details class="ui-dropdown" style="width:fit-content;">
    <summary>
      <span>Approvals</span>
      <span
        v-if="needsApprove(approveExactMissing, approveManagerExactMissing)"
        class="ui-badge"
        style="border-color:#b00;color:#b00;"
      >
        Approve nötig
      </span>
    </summary>
    <div style="margin-top:8px;">
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
  </details>
</template>
