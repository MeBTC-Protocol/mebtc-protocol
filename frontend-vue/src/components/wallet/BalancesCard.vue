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

    <div v-else class="ui-stack">
      <div class="stat-list">
        <div class="stat-row">
          <span class="stat-label">MeBTC</span>
          <span class="stat-value">{{ formatUnits(mebtc, mebtcDecimals) }} {{ TOKENS.mebtc.symbol }}</span>
        </div>
        <div class="stat-row">
          <span class="stat-label">{{ payTokenSymbol }}</span>
          <span class="stat-value">{{ formatUnits(payToken, payTokenDecimals) }} {{ payTokenSymbol }}</span>
        </div>
      </div>

      <div>
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

      <div class="ui-section">
        <div class="ui-subtitle">Owned miners</div>
        <OwnedMinersList :disabled="disabled" :owned="owned" layout="grid-sm" />
      </div>
    </div>
  </Card>
</template>
