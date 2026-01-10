<script setup lang="ts">
import { computed } from 'vue'
import { formatUnits } from 'ethers'
import Card from '../common/Card.vue'
import { TOKENS } from '../../contracts/addresses'
import { useMinerNftMetadata } from '../../composables/useMinerNftMetadata'

const props = defineProps<{
  mebtc: bigint
  usdc: bigint
  loading: boolean
  mebtcDecimals: number
  usdcDecimals: number

  // NEU:
  disabled: boolean
  owned: bigint[]
}>()

const ids = computed(() => props.owned ?? [])
const { states } = useMinerNftMetadata(() => ids.value)

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
</script>

<template>
  <Card title="balances">
    <div v-if="loading">loading…</div>

    <div v-else style="display:flex;flex-direction:column;gap:8px;">
      <div>
        mebtc:
        <b>{{ formatUnits(mebtc, mebtcDecimals) }} {{ TOKENS.mebtc.symbol }}</b>
      </div>

      <div>
        usdc:
        <b>{{ formatUnits(usdc, usdcDecimals) }} {{ TOKENS.usdc.symbol }}</b>
      </div>

      <div style="margin-top:10px;border-top:1px solid #ddd;padding-top:10px;">
        <div style="font-weight:600;margin-bottom:8px;">owned miners</div>

        <div v-if="disabled" style="opacity:.8;">
          wallet nicht verbunden / falsches netzwerk
        </div>

        <div v-else-if="owned.length === 0" style="opacity:.8;">
          keine miner NFTs gefunden (drücke ggf. „rescan“)
        </div>

        <div
          v-else
          style="display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:10px;"
        >
          <div
            v-for="id in owned"
            :key="id.toString()"
            style="border:1px solid #ddd;border-radius:12px;padding:8px;"
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
          </div>
        </div>
      </div>
    </div>
  </Card>
</template>


