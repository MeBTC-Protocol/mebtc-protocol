<script setup lang="ts">
import { computed } from 'vue'
import Card from '../common/Card.vue'
import { useMinerNftMetadata } from '../../composables/useMinerNftMetadata'

const props = defineProps<{
  disabled: boolean
  owned: bigint[]
}>()

const ids = computed(() => props.owned ?? [])
const { states } = useMinerNftMetadata(() => ids.value)

function labelFor(id: string) {
  const st = states.value[id]
  if (!st || st.status === 'idle') return 'idle'
  if (st.status === 'loading') return 'loading…'
  if (st.status === 'error') return `error: ${st.error}`
  return st.meta.name || 'Miner'
}

function imgFor(id: string) {
  const st = states.value[id]
  if (!st || st.status !== 'ok') return ''
  return st.meta.image || ''
}
</script>

<template>
  <Card title="owned miners">
    <div v-if="disabled" style="opacity:.8;">
      wallet nicht verbunden / falsches netzwerk
    </div>

    <div v-else-if="owned.length === 0" style="opacity:.8;">
      keine miner NFTs gefunden
    </div>

    <div
      v-else
      style="display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:12px;margin-top:8px;"
    >
      <div
        v-for="id in owned"
        :key="id.toString()"
        style="border:1px solid #ddd;border-radius:14px;padding:10px;"
      >
        <div style="font-weight:600;margin-bottom:6px;">
          #{{ id.toString() }} — {{ labelFor(id.toString()) }}
        </div>

        <div
          style="width:100%;aspect-ratio:1/1;border-radius:12px;overflow:hidden;background:#f2f2f2;display:flex;align-items:center;justify-content:center;"
        >
          <img
            v-if="imgFor(id.toString())"
            :src="imgFor(id.toString())"
            alt="miner"
            style="width:100%;height:100%;object-fit:cover;"
          />
          <div v-else style="opacity:.7;">no image</div>
        </div>

        <div style="margin-top:8px;font-size:12px;opacity:.8;">
          <span v-if="states[id.toString()]?.status === 'loading'">loading metadata…</span>
          <span v-else-if="states[id.toString()]?.status === 'error'">
            {{ (states[id.toString()] as any).error }}
          </span>
        </div>
      </div>
    </div>
  </Card>
</template>
