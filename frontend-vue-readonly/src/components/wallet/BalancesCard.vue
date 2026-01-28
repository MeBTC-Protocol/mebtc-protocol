<script setup lang="ts">
import { formatUnits } from 'ethers'
import Card from '../common/Card.vue'
import { TOKENS } from '../../contracts/addresses'
import OwnedMinersList from '../miner/OwnedMinersList.vue'

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
  stakeTier: number
  hashBonusBps: number
  powerBonusBps: number
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

      <div class="ui-section">
        <div class="ui-subtitle">Owned miners</div>
        <OwnedMinersList
          :disabled="disabled"
          :owned="owned"
          :stakeTier="stakeTier"
          :hashBonusBps="hashBonusBps"
          :powerBonusBps="powerBonusBps"
          layout="grid-sm"
        />
      </div>
    </div>
  </Card>
</template>
