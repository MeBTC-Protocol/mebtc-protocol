<script setup lang="ts">
import { computed } from 'vue'
import { useMinerNftMetadata } from '../../composables/useMinerNftMetadata'
import { useMinerNftData } from '../../composables/useMinerNftData'
import { useMinerUpgradeStates } from '../../composables/useMinerUpgradeStates'

const props = defineProps<{
  disabled: boolean
  owned: bigint[]
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

function errorFor(id: string) {
  const st = dataStates.value[id]
  return st && st.status === 'error' ? st.error : ''
}

function upgradeLabelFor(id: string) {
  const st = upgradeStates.value[id]
  if (!st || st.status === 'idle') return ''
  if (st.status === 'loading') return 'loading upgrades…'
  if (st.status === 'error') return `upgrade error: ${st.error}`
  const powerPending = st.powerPendingSteps > 0 ? ` (+${st.powerPendingSteps} pending)` : ''
  const hashPending = st.hashPendingSteps > 0 ? ` (+${st.hashPendingSteps} pending)` : ''
  return `upgrade:Power ${st.powerActiveSteps}/${st.maxSteps}${powerPending} |Hash ${st.hashActiveSteps}/${st.maxSteps}${hashPending}`
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
            hash: {{ hashFor(id.toString()) }} | power: {{ powerFor(id.toString()) }} W
          </span>
        </div>
        <div>{{ upgradeLabelFor(id.toString()) }}</div>
      </div>
    </div>
  </div>
</template>
