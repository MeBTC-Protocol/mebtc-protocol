<script setup lang="ts">
import { formatUnits } from 'ethers'
import Card from '../common/Card.vue'
import { TOKENS } from '../../contracts/addresses'
import OwnedMinersList from '../miner/OwnedMinersList.vue'
import AllowancesDropdown from './AllowancesDropdown.vue'

const props = defineProps<{
  mebtc: bigint
  payToken: bigint
  loading: boolean
  mebtcDecimals: number
  payTokenDecimals: number
  payTokenSymbol: string

  // NEU:
  disabled: boolean
  owned: bigint[]

  allowancesLoading: boolean
  allowancesBusy: boolean
  allowanceMinerText: string
  allowanceManagerText: string
  approveError: string
  approveLastTx: string
  onApproveMiner: () => void
  onApproveManager: () => void
  approveExactMissing: bigint
  approveExactValue: bigint
  onApproveExact: (amount: bigint) => void
  approveManagerExactMissing: bigint
  approveManagerExactValue: bigint
  onApproveManagerExact: (amount: bigint) => void
}>()
</script>

<template>
  <Card title="Balances">
    <div v-if="loading">loading…</div>

    <div v-else style="display:flex;flex-direction:column;gap:8px;">
      <div>
        MeBTC:
        <b>{{ formatUnits(mebtc, mebtcDecimals) }} {{ TOKENS.mebtc.symbol }}</b>
      </div>

      <div>
        {{ payTokenSymbol }}:
        <b>{{ formatUnits(payToken, payTokenDecimals) }} {{ payTokenSymbol }}</b>
      </div>

      <div style="margin-top:6px;">
        <AllowancesDropdown
          :disabled="disabled"
          :loading="allowancesLoading"
          :busy="allowancesBusy"
          :minerText="allowanceMinerText"
          :managerText="allowanceManagerText"
          :payTokenSymbol="payTokenSymbol"
          :payTokenDecimals="payTokenDecimals"
          :error="approveError"
          :lastTx="approveLastTx"
          :onApproveMiner="onApproveMiner"
          :onApproveManager="onApproveManager"
          :approveExactMissing="approveExactMissing"
          :approveExactValue="approveExactValue"
          :onApproveExact="onApproveExact"
          :approveManagerExactMissing="approveManagerExactMissing"
          :approveManagerExactValue="approveManagerExactValue"
          :onApproveManagerExact="onApproveManagerExact"
        />
      </div>

      <div style="margin-top:10px;border-top:1px solid #ddd;padding-top:10px;">
        <div style="font-weight:600;margin-bottom:8px;">owned miners</div>
        <OwnedMinersList :disabled="disabled" :owned="owned" layout="grid-sm" />
      </div>
    </div>
  </Card>
</template>
