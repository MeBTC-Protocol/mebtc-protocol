<script setup lang="ts">
import Card from "../common/Card.vue"
import Button from "../common/Button.vue"
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
  payTokenSymbol: string
  payTokenDecimals: number
  setSelected: (next: Record<string, boolean>) => void
  onClaim: () => void
}>()

function toggle(id: bigint, checked: boolean) {
  const key = id.toString()
  props.setSelected({ ...props.selected, [key]: checked })
}
</script>

<template>
  <Card title="Claim">
    <div class="ui-row">
      <Button
        :disabled="disabled || busy"
        @click="() => onClaim().catch(() => {})"
      >
        Claim selected
      </Button>

      <div class="ui-muted">
        fee selected: {{ formatUnits(totalFeeSelected, payTokenDecimals) }} {{ payTokenSymbol }}
      </div>

      <div class="ui-muted">
        allowance manager: {{ allowanceManagerText }} {{ payTokenSymbol }}
      </div>
    </div>

    <div v-if="error" style="margin-top:10px;">error: {{ error }}</div>

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
            <td>#{{ id.toString() }}</td>
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
