<script setup lang="ts">
import { computed, ref } from 'vue'
import { formatUnits } from 'ethers'
import Card from '../common/Card.vue'
import { TOKENS } from '../../contracts/addresses'
import OwnedMinersList from '../miner/OwnedMinersList.vue'
import { useMinerNftData } from '../../composables/useMinerNftData'

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

const ids = computed(() => props.owned ?? [])
const { states: dataStates } = useMinerNftData(() => ids.value)

const totalHash = computed(() => {
  let total = 0n
  const withBonus = (props.stakeTier ?? 0) > 0
  const bps = BigInt(Math.max(0, props.hashBonusBps || 0))
  const denom = 10_000n

  for (const id of ids.value) {
    const st = dataStates.value[id.toString()]
    if (!st || st.status !== 'ok') continue
    const value = withBonus ? (st.effHash * (denom + bps)) / denom : st.effHash
    total += value
  }
  return total
})

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
  if (denom === 0n) return `${value.toString()} Hash/s`

  if (unitIndex === 0) return `${value.toString()} ${units[unitIndex]}`

  const whole = value / denom
  const frac = ((value % denom) * 100n) / denom
  const fracText = frac.toString().padStart(2, '0')
  return `${whole.toString()}.${fracText} ${units[unitIndex]}`
}

const totalHashText = computed(() => {
  if (ids.value.length === 0) return '0'

  const statuses = ids.value.map((id) => dataStates.value[id.toString()]?.status)
  const anyOk = statuses.some((s) => s === 'ok')
  const anyLoading = statuses.some((s) => s === 'loading' || s === 'idle')
  const anyError = statuses.some((s) => s === 'error')

  if (!anyOk && anyLoading) return 'loading…'
  if (!anyOk && anyError) return 'error'

  let suffix = ''
  if (anyLoading) suffix = ' (loading…)'
  else if (anyError) suffix = ' (teilweise)'

  return `${formatHashRate(totalHash.value)}${suffix}`
})

const bonusActive = computed(() => (props.stakeTier ?? 0) > 0)
const viewMode = ref<'tiles' | 'list'>('tiles')
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
        <div class="stat-row">
          <span class="stat-label">Miner hashrate total</span>
          <span class="stat-value">
            {{ totalHashText }}
            <span v-if="bonusActive" class="staking-bonus"> (staking bonus aktiv)</span>
          </span>
        </div>
      </div>

      <div class="ui-section">
        <div class="ui-subtitle">Owned miners</div>
        <div class="ui-row ui-muted" style="margin-bottom:8px;">
          <label style="font-size:12px;">
            Ansicht:
            <select v-model="viewMode" class="ui-select" style="width:140px;">
              <option value="tiles">Kacheln</option>
              <option value="list">Liste</option>
            </select>
          </label>
        </div>
        <OwnedMinersList
          :disabled="disabled"
          :owned="owned"
          :stakeTier="stakeTier"
          :hashBonusBps="hashBonusBps"
          :powerBonusBps="powerBonusBps"
          :dataStates="dataStates"
          :view="viewMode"
          layout="grid-sm"
        />
      </div>
    </div>
  </Card>
</template>
