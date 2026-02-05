<script setup lang="ts">
import { computed } from 'vue'
import { useMinerNftMetadata } from '../../composables/useMinerNftMetadata'
import { useMinerNftData } from '../../composables/useMinerNftData'
import type { MinerDataState } from '../../composables/useMinerNftData'
import { useMinerUpgradeStates } from '../../composables/useMinerUpgradeStates'
import ErrorPopupInline from '../common/ErrorPopupInline.vue'

const props = defineProps<{
  disabled: boolean
  owned: bigint[]
  stakeTier: number
  hashBonusBps: number
  powerBonusBps: number
  layout?: 'grid-sm' | 'grid-md'
  view?: 'tiles' | 'list'
  dataStates?: Record<string, MinerDataState>
}>()

const ids = computed(() => props.owned ?? [])
const { states } = useMinerNftMetadata(() => ids.value)
const { states: dataStatesLocal } = useMinerNftData(() => ids.value)
const dataStates = computed(() => props.dataStates ?? dataStatesLocal.value)
const { states: upgradeStates } = useMinerUpgradeStates(() => ids.value)

const layoutClass = computed(() => {
  const view = props.view ?? 'tiles'
  if (view === 'list') return 'miner-list'
  return props.layout === 'grid-md' ? 'miner-grid-md' : 'miner-grid-sm'
})

const grouped = computed(() => {
  const map = new Map<
    string,
    { key: string; label: string; ids: bigint[]; modelId: number | null; repId: string | null }
  >()

  function ensureGroup(key: string, label: string, modelId: number | null) {
    const existing = map.get(key)
    if (existing) return existing
    const group = { key, label, ids: [], modelId, repId: null }
    map.set(key, group)
    return group
  }

  for (const id of ids.value) {
    const key = id.toString()
    const st = upgradeStates.value[key]

    if (st?.status === 'ok') {
      const group = ensureGroup(`model-${st.modelId}`, `Model ${st.modelId}`, st.modelId)
      group.ids.push(id)
      if (!group.repId) group.repId = key
      continue
    }

    if (st?.status === 'loading') {
      const group = ensureGroup('model-loading', 'Model: loading…', null)
      group.ids.push(id)
      if (!group.repId) group.repId = key
      continue
    }

    if (st?.status === 'error') {
      const group = ensureGroup('model-error', 'Model: unbekannt', null)
      group.ids.push(id)
      if (!group.repId) group.repId = key
      continue
    }

    const group = ensureGroup('model-unknown', 'Model: unbekannt', null)
    group.ids.push(id)
    if (!group.repId) group.repId = key
  }

  const list = [...map.values()]
  list.sort((a, b) => {
    if (a.modelId == null && b.modelId == null) return a.label.localeCompare(b.label)
    if (a.modelId == null) return 1
    if (b.modelId == null) return -1
    return a.modelId - b.modelId
  })

  const openAll = list.length <= 1
  return list.map((group, index) => ({
    ...group,
    openByDefault: openAll || index === 0
  }))
})

function nameFor(id: string) {
  const st = states.value[id]
  if (!st) return `#${id}`
  if (st.status === 'loading') return `#${id} (loading…)`
  if (st.status === 'error') return `#${id}`
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

const bonusActive = computed(() => (props.stakeTier ?? 0) > 0)

function errorFor(id: string) {
  const st = dataStates.value[id]
  return st && st.status === 'error' ? st.error : ''
}

function groupName(group: { repId: string | null; label: string }) {
  const repId = group.repId
  if (!repId) return group.label
  const st = states.value[repId]
  if (!st) return group.label
  if (st.status === 'loading') return 'Miner (loading…)'
  if (st.status === 'error') return group.label
  return st.meta.name || group.label
}

function groupImage(group: { repId: string | null }) {
  const repId = group.repId
  if (!repId) return ''
  const st = states.value[repId]
  if (!st || st.status !== 'ok') return ''
  return st.meta.image || ''
}

function groupTypeFor(group: { repId: string | null }) {
  return group.repId ? modelTypeFor(group.repId) : ''
}

function groupThumbClass(group: { repId: string | null }) {
  const type = groupTypeFor(group)
  return type ? `miner-group-thumb model-${type}` : 'miner-group-thumb'
}

function modelIdFor(id: string) {
  const st = upgradeStates.value[id]
  return st && st.status === 'ok' ? st.modelId : null
}

function modelTypeFor(id: string) {
  const metaName = states.value[id]?.status === 'ok' ? states.value[id].meta.name ?? '' : ''
  const normalized = metaName.toLowerCase()

  if (normalized.includes('rigminer') || normalized.includes('rig miner')) return 'rig'
  if (normalized.includes('basicminer') || normalized.includes('basic miner')) return 'basic'
  if (normalized.includes('meminer') || normalized.includes('me miner')) return 'me'
  if (normalized.includes('prominer') || normalized.includes('pro miner')) return 'pro'
  if (normalized.includes('primeminer') || normalized.includes('prime miner')) return 'prime'
  if (normalized.includes('apexminer') || normalized.includes('apex miner')) return 'apex'

  const modelId = modelIdFor(id)
  if (modelId === 1) return 'rig'
  if (modelId === 2) return 'basic'
  if (modelId === 3) return 'me'
  if (modelId === 4) return 'pro'
  if (modelId === 5) return 'prime'
  if (modelId === 6) return 'apex'
  return ''
}

function minerCardClass(id: string) {
  const type = modelTypeFor(id)
  return type ? `miner-card model-${type}` : 'miner-card'
}
</script>

<template>
  <div v-if="disabled" class="ui-muted">
    wallet nicht verbunden / falsches netzwerk
  </div>

  <div v-else-if="owned.length === 0" class="ui-muted">
    keine miner NFTs gefunden (drücke ggf. „rescan“)
  </div>

  <div v-else class="miner-group-list">
    <details
      v-for="group in grouped"
      :key="group.key"
      class="miner-group"
      :open="group.openByDefault"
    >
      <summary class="miner-group-summary">
        <span class="miner-group-left">
          <span :class="groupThumbClass(group)">
            <img
              v-if="groupImage(group)"
              :src="groupImage(group)"
              alt="miner"
            />
            <span v-else class="ui-muted" style="font-size:10px;">no image</span>
          </span>
          <span class="miner-group-title">{{ groupName(group) }}</span>
        </span>
        <span class="miner-group-count">{{ group.ids.length }}</span>
      </summary>

      <div :class="['miner-grid', layoutClass]">
        <div
          v-for="id in group.ids"
          :key="id.toString()"
          :class="minerCardClass(id.toString())"
          :data-model-id="modelIdFor(id.toString()) ?? ''"
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
            <div>
              tokenId:
              <span class="token-id-number">#{{ id.toString() }}</span>
            </div>
            <div>
              <span v-if="states[id.toString()]?.status === 'loading'">loading metadata…</span>
              <ErrorPopupInline
                v-else-if="states[id.toString()]?.status === 'error'"
                :error="states[id.toString()]?.error ?? ''"
                context="Miner Metadata"
              />
            </div>
            <div>
              <span v-if="dataFor(id.toString())?.status === 'loading'">loading stats…</span>
              <ErrorPopupInline
                v-else-if="dataFor(id.toString())?.status === 'error'"
                :error="errorFor(id.toString())"
                context="Miner Stats"
              />
              <span v-else-if="dataFor(id.toString())?.status === 'ok'">
                hash: {{ displayHash(id.toString()) }} | power: {{ displayPower(id.toString()) }} W
                <span v-if="bonusActive" class="staking-bonus"> (staking bonus aktiv)</span>
              </span>
            </div>
            <div>
              <span v-if="upgradeStates[id.toString()]?.status === 'loading'">loading upgrades…</span>
              <ErrorPopupInline
                v-else-if="upgradeStates[id.toString()]?.status === 'error'"
                :error="upgradeStates[id.toString()]?.error ?? ''"
                context="Upgrade Status"
              />
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
    </details>
  </div>
</template>
