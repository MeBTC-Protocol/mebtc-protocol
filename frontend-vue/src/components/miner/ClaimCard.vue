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
    <div style="display:flex;gap:12px;flex-wrap:wrap;align-items:center;">
      <Button
        :disabled="disabled || busy"
        @click="() => onClaim().catch(() => {})"
      >
        Claim selected
      </Button>

      <div style="opacity:.8;">
        fee selected: {{ formatUnits(totalFeeSelected, TOKENS.usdc.decimals) }} {{ TOKENS.usdc.symbol }}
      </div>

      <div style="opacity:.8;">
        allowance manager: {{ allowanceManagerText }} {{ TOKENS.usdc.symbol }}
      </div>
    </div>

    <div v-if="error" style="margin-top:10px;">error: {{ error }}</div>

    <div v-if="lastApproveTx" style="margin-top:10px;opacity:.8;">
      approve tx: {{ lastApproveTx }}
    </div>

    <div v-if="lastTx" style="margin-top:10px;opacity:.8;">
      claim tx: {{ lastTx }}
    </div>

    <table style="width:100%;border-collapse:collapse;margin-top:12px;">
      <thead>
        <tr>
          <th style="text-align:left;border-bottom:1px solid #999;padding:8px 6px;opacity:.8;">select</th>
          <th style="text-align:left;border-bottom:1px solid #999;padding:8px 6px;opacity:.8;">tokenId</th>
          <th style="text-align:left;border-bottom:1px solid #999;padding:8px 6px;opacity:.8;">reward</th>
          <th style="text-align:left;border-bottom:1px solid #999;padding:8px 6px;opacity:.8;">fee (usdc)</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="id in owned" :key="id.toString()">
          <td style="border-bottom:1px solid #ddd;padding:8px 6px;">
            <input
              type="checkbox"
              :checked="!!selected[id.toString()]"
              @change="toggle(id, ($event.target as HTMLInputElement).checked)"
            />
          </td>
          <td style="border-bottom:1px solid #ddd;padding:8px 6px;">#{{ id.toString() }}</td>
          <td style="border-bottom:1px solid #ddd;padding:8px 6px;">
            <span v-if="previewMap.get(id.toString())">
              {{ formatUnits(previewMap.get(id.toString())!.reward, TOKENS.mebtc.decimals) }}
            </span>
            <span v-else>-</span>
          </td>
          <td style="border-bottom:1px solid #ddd;padding:8px 6px;">
            <span v-if="previewMap.get(id.toString())">
              {{ formatUnits(previewMap.get(id.toString())!.fee, TOKENS.usdc.decimals) }}
            </span>
            <span v-else>-</span>
          </td>
        </tr>
      </tbody>
    </table>
  </Card>
</template>
