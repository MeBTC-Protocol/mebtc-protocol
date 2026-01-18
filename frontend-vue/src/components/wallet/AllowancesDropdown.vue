<script setup lang="ts">
import { formatUnits } from 'ethers'
import Button from '../common/Button.vue'

const props = defineProps<{
  disabled: boolean
  loading: boolean
  busy: boolean
  minerText: string
  managerText: string
  payTokenSymbol: string
  payTokenDecimals: number
  error: string
  lastTx: string
  onApproveMiner: () => void
  onApproveManager: () => void
  approveExactMissing: bigint
  approveExactValue: bigint
  onApproveExact: (amount: bigint) => void
  approveManagerExactMissing: bigint
  approveManagerExactValue: bigint
  onApproveManagerExact: (amount: bigint) => void
}>()

function fmt(v: bigint) {
  return formatUnits(v, props.payTokenDecimals)
}

function needsApprove(minerMissing: bigint, managerMissing: bigint) {
  return minerMissing > 0n || managerMissing > 0n
}
</script>

<template>
  <details class="ui-dropdown" style="width:fit-content;">
    <summary>
      <span>{{ payTokenSymbol }} Allowances</span>
      <span
        v-if="needsApprove(approveExactMissing, approveManagerExactMissing)"
        class="ui-badge"
        style="border-color:#b00;color:#b00;"
      >
        Approve nötig
      </span>
    </summary>
    <div style="margin-top:8px;">
      <div v-if="loading">loading…</div>
      <div v-else>
        <div>allowance minerNFT (buy/upgrade): {{ minerText }}</div>
        <div>allowance manager (claim fee): {{ managerText }}</div>
        <div class="ui-row" style="margin-top:8px;">
          <Button
            :disabled="disabled || busy || approveExactMissing === 0n"
            @click="onApproveExact(approveExactValue)"
            size="sm"
          >
            approve {{ payTokenSymbol }} für MinerNFT exact (missing {{ fmt(approveExactMissing) }} {{ payTokenSymbol }})
          </Button>
          <Button
            :disabled="disabled || busy || approveManagerExactMissing === 0n"
            @click="onApproveManagerExact(approveManagerExactValue)"
            size="sm"
          >
            approve {{ payTokenSymbol }} für Manager exact (missing {{ fmt(approveManagerExactMissing) }} {{ payTokenSymbol }})
          </Button>
          <Button
            :disabled="disabled || busy"
            @click="onApproveMiner"
            size="sm"
          >
            approve {{ payTokenSymbol }} für MinerNFT (max, optional)
          </Button>
          <Button
            :disabled="disabled || busy"
            @click="onApproveManager"
            size="sm"
          >
            approve {{ payTokenSymbol }} für Manager (max, optional)
          </Button>
        </div>
        <div v-if="error" style="margin-top:8px;">approve error: {{ error }}</div>
        <div v-if="lastTx" class="ui-muted" style="margin-top:6px;">approve tx: {{ lastTx }}</div>
      </div>
    </div>
  </details>
</template>
