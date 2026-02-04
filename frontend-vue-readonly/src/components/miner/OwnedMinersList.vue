<script setup lang="ts">
import { computed } from 'vue'
import { useMinerNftMetadata } from '../../composables/useMinerNftMetadata'
import { useMinerNftData } from '../../composables/useMinerNftData'
import { useMinerUpgradeStates } from '../../composables/useMinerUpgradeStates'

const props = defineProps<{
  disabled: boolean
  owned: bigint[]
  stakeTier: number
  hashBonusBps: number
  powerBonusBps: number
  layout?: 'grid-sm' | 'grid-md'
}>()

const ids = computed(() => props.owned ?? [])
const { states } = useMinerNftMetadata(() => ids.value)
const { states: dataStates } = useMinerNftData(() => ids.value)
const { states: upgradeStates } = useMinerUpgradeStates(() => ids.value)

const layoutClass = computed(() => {
  return props.layout === 'grid-md' ? 'miner-grid-md' : 'miner-grid-sm'
})

function nameFor(id: string) {
  const st = states.value[id]
  if (!st) return `#${id}`
  if (st.status === 'loading') return `#${id} (loading…)`
  if (st.status === 'error') return `#${id} (meta error)`
  return st.meta.name || `#${id}`
}

function imgFor(id: string) {
  const st = states.value[id]
  if (!st || st.status !== 'ok') return ''
  return st.meta.image || ''
}

function dataFor(id: string) {
  return dataStates.value[id]
}

function hashFor(id: string) {
  const st = dataStates.value[id]
  return st && st.status === 'ok' ? st.effHash.toString() : ''
}

function powerFor(id: string) {
  const st = dataStates.value[id]
  return st && st.status === 'ok' ? st.effPowerWatt.toString() : ''
}

function hashWithBonusFor(id: string) {
  const st = dataStates.value[id]
  if (!st || st.status !== 'ok') return ''
  const bps = BigInt(Math.max(0, props.hashBonusBps || 0))
  const num = st.effHash * (10_000n + bps)
  return (num / 10_000n).toString()
}

function powerWithBonusFor(id: string) {
  const st = dataStates.value[id]
  if (!st || st.status !== 'ok') return ''
  const bps = BigInt(Math.max(0, props.powerBonusBps || 0))
  const denom = 10_000n
  const adj = bps > 10_000n ? 0n : (denom - bps)
  const num = st.effPowerWatt * adj
  return (num / denom).toString()
}

function displayHash(id: string) {
  return (props.stakeTier ?? 0) > 0 ? hashWithBonusFor(id) : hashFor(id)
}

function displayPower(id: string) {
  return (props.stakeTier ?? 0) > 0 ? powerWithBonusFor(id) : powerFor(id)
}

function bonusInline() {
  return (props.stakeTier ?? 0) > 0 ? ' (staking bonus aktiv)' : ''
}

function errorFor(id: string) {
  const st = dataStates.value[id]
  return st && st.status === 'error' ? st.error : ''
}

</script>

<template>
  <div v-if="disabled" class="ui-muted">
    wallet nicht verbunden / falsches netzwerk
  </div>

  <div v-else-if="owned.length === 0" class="ui-muted">
    keine miner NFTs gefunden (drücke ggf. „rescan“)
  </div>

  <div v-else :class="['miner-grid', layoutClass]">
    <div
      v-for="id in owned"
      :key="id.toString()"
      class="miner-card"
    >
      <div class="miner-title">
        {{ nameFor(id.toString()) }}
      </div>

      <div class="miner-image">
        <img
          v-if="imgFor(id.toString())"
          :src="imgFor(id.toString())"
          alt="miner"
        />
        <div v-else class="ui-muted" style="font-size:11px;">
          no image
        </div>
      </div>

      <div class="miner-meta">
        <div>tokenId: #{{ id.toString() }}</div>
        <div>
          <span v-if="states[id.toString()]?.status === 'loading'">loading metadata…</span>
          <span v-else-if="states[id.toString()]?.status === 'error'">metadata error</span>
        </div>
        <div>
          <span v-if="dataFor(id.toString())?.status === 'loading'">loading stats…</span>
          <span v-else-if="dataFor(id.toString())?.status === 'error'">
            {{ errorFor(id.toString()) }}
          </span>
          <span v-else-if="dataFor(id.toString())?.status === 'ok'">
            hash: {{ displayHash(id.toString()) }} | power: {{ displayPower(id.toString()) }} W{{ bonusInline() }}
          </span>
        </div>
        <div>
          <span v-if="upgradeStates[id.toString()]?.status === 'loading'">loading upgrades…</span>
          <span v-else-if="upgradeStates[id.toString()]?.status === 'error'">
            upgrade error: {{ upgradeStates[id.toString()]?.error }}
          </span>
          <span v-else-if="upgradeStates[id.toString()]?.status === 'ok'">
            upgrade:Power {{ upgradeStates[id.toString()]?.powerActiveSteps }}/{{ upgradeStates[id.toString()]?.maxSteps }}
            <span
              v-if="(upgradeStates[id.toString()]?.powerPendingSteps ?? 0) > 0"
              class="upgrade-pending"
            >
              (+{{ upgradeStates[id.toString()]?.powerPendingSteps }} pending)
            </span>
            |Hash {{ upgradeStates[id.toString()]?.hashActiveSteps }}/{{ upgradeStates[id.toString()]?.maxSteps }}
            <span
              v-if="(upgradeStates[id.toString()]?.hashPendingSteps ?? 0) > 0"
              class="upgrade-pending"
            >
              (+{{ upgradeStates[id.toString()]?.hashPendingSteps }} pending)
            </span>
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
