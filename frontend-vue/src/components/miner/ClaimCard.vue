<script setup lang="ts">
import { computed, ref } from "vue"
import Card from "../common/Card.vue"
import Button from "../common/Button.vue"
import ErrorPopupInline from "../common/ErrorPopupInline.vue"
import { formatUnits } from "ethers"
import { TOKENS } from "../../contracts/addresses"

const props = defineProps<{
  disabled: boolean
  owned: bigint[]
  previewMap: Map<string, { reward: bigint; fee: bigint }>
  selected: Record<string, boolean>
  busy: boolean
  error: string
  lastTx: string
  lastApproveTx: string
  totalFeeSelected: bigint
  allowanceManagerText: string
  mebtcAllowanceText: string
  payTokenSymbol: string
  payTokenDecimals: number
  maxIdsPerTx: number
  claimQueueStatus: {
    running: boolean
    total: number
    processed: number
    currentBatchSize: number
    remaining: number
    note: string
  }
  setSelected: (next: Record<string, boolean>) => void
  onClaim: (mebtcShareBps: number) => void
}>()

const mebtcSharePercent = ref<number>(0)
const mebtcShareBps = computed(() => {
  const p = Math.max(0, Math.min(30, Math.floor(mebtcSharePercent.value || 0)))
  return p * 100
})


function toggle(id: bigint, checked: boolean) {
  const key = id.toString()
  props.setSelected({ ...props.selected, [key]: checked })
}

function safeCall(fn: () => Promise<unknown> | unknown) {
  Promise.resolve(fn()).catch(() => {})
}
</script>

<template>
  <Card title="Claim">
    <div class="ui-row">
      <Button
        :disabled="disabled || busy"
        @click="() => safeCall(() => onClaim(mebtcShareBps))"
      >
        Claim selected
      </Button>

      <div class="ui-muted">
        max {{ maxIdsPerTx }} IDs pro Tx (auto-queue)
      </div>

      <div class="ui-muted">
        fee selected: {{ formatUnits(totalFeeSelected, payTokenDecimals) }} {{ payTokenSymbol }}
      </div>

      <div class="ui-muted">
        allowance manager: {{ allowanceManagerText }} {{ payTokenSymbol }}
      </div>
    </div>

    <div class="ui-muted" style="margin-top:6px;font-size:12px;">
      Peak-Phase: Claims werden in einer Warteschlange mit max. {{ maxIdsPerTx }} IDs pro Tx verarbeitet.
    </div>
    <div
      v-if="claimQueueStatus.total > 0"
      class="ui-muted"
      style="margin-top:4px;font-size:12px;"
    >
      queue: {{ claimQueueStatus.processed }}/{{ claimQueueStatus.total }} verarbeitet
      <span v-if="claimQueueStatus.running && claimQueueStatus.currentBatchSize > 0">
        | aktueller batch: {{ claimQueueStatus.currentBatchSize }}
      </span>
      <span v-if="claimQueueStatus.note">
        | {{ claimQueueStatus.note }}
      </span>
    </div>

    <div class="ui-row" style="margin-top:6px;">
      <label class="ui-muted" style="font-size:12px;">
        MeBTC Anteil:
        <select v-model.number="mebtcSharePercent" class="ui-select" style="width:90px;">
          <option :value="0">0%</option>
          <option :value="10">10%</option>
          <option :value="20">20%</option>
          <option :value="30">30%</option>
        </select>
      </label>
      <div class="ui-muted">
        allowance MeBTC: {{ mebtcAllowanceText }} MeBTC
      </div>
    </div>

    <ErrorPopupInline :error="error" context="Claim" />

    <div v-if="lastApproveTx" class="ui-muted" style="margin-top:10px;">
      approve tx: {{ lastApproveTx }}
    </div>

    <div v-if="lastTx" class="ui-muted" style="margin-top:10px;">
      claim tx: {{ lastTx }}
    </div>

    <div class="ui-section">
      <table class="ui-table">
        <thead>
          <tr>
            <th>select</th>
            <th>tokenId</th>
            <th>reward</th>
            <th>fee</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="id in owned" :key="id.toString()">
            <td>
              <input
                type="checkbox"
                :checked="!!selected[id.toString()]"
                @change="toggle(id, ($event.target as HTMLInputElement).checked)"
              />
            </td>
            <td><span class="token-id-number">#{{ id.toString() }}</span></td>
            <td>
              <span v-if="previewMap.get(id.toString())">
                {{ formatUnits(previewMap.get(id.toString())!.reward, TOKENS.mebtc.decimals) }}
              </span>
              <span v-else>-</span>
            </td>
            <td>
              <span v-if="previewMap.get(id.toString())">
                {{ formatUnits(previewMap.get(id.toString())!.fee, payTokenDecimals) }}
              </span>
              <span v-else>-</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </Card>
</template>
