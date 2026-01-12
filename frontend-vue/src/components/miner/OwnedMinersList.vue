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

const layoutStyle = computed(() => {
  const min = props.layout === 'grid-sm' ? 160 : 220
  return `display:grid;grid-template-columns:repeat(auto-fill,minmax(${min}px,1fr));gap:10px;`
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
  <div v-if="disabled" style="opacity:.8;">
    wallet nicht verbunden / falsches netzwerk
  </div>

  <div v-else-if="owned.length === 0" style="opacity:.8;">
    keine miner NFTs gefunden (drücke ggf. „rescan“)
  </div>

  <div v-else :style="layoutStyle">
    <div
      v-for="id in owned"
      :key="id.toString()"
      style="border:1px solid #111;border-radius:12px;padding:8px;background:#ffb347;box-shadow:0 0 8px rgba(0,0,0,0.6);"
    >
      <div style="font-size:12px;font-weight:600;margin-bottom:6px;">
        {{ nameFor(id.toString()) }}
      </div>

      <div
        style="width:100%;aspect-ratio:1/1;border-radius:10px;overflow:hidden;background:#f2f2f2;display:flex;align-items:center;justify-content:center;"
      >
        <img
          v-if="imgFor(id.toString())"
          :src="imgFor(id.toString())"
          alt="miner"
          style="width:100%;height:100%;object-fit:cover;"
        />
        <div v-else style="opacity:.7;font-size:12px;">
          no image
        </div>
      </div>

      <div style="margin-top:6px;font-size:12px;opacity:.8;">
        tokenId: #{{ id.toString() }}
      </div>

      <div style="margin-top:4px;font-size:11px;opacity:.7;">
        <span v-if="states[id.toString()]?.status === 'loading'">loading metadata…</span>
        <span v-else-if="states[id.toString()]?.status === 'error'">metadata error</span>
      </div>

      <div style="margin-top:4px;font-size:11px;opacity:.7;">
        <span v-if="dataFor(id.toString())?.status === 'loading'">loading stats…</span>
        <span v-else-if="dataFor(id.toString())?.status === 'error'">
          {{ errorFor(id.toString()) }}
        </span>
        <span v-else-if="dataFor(id.toString())?.status === 'ok'">
          hash: {{ hashFor(id.toString()) }} | power: {{ powerFor(id.toString()) }} W
        </span>
      </div>

      <div style="margin-top:4px;font-size:11px;opacity:.7;">
        {{ upgradeLabelFor(id.toString()) }}
      </div>
    </div>
  </div>
</template>
