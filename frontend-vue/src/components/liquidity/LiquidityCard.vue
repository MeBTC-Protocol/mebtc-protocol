<script setup lang="ts">
import { ref } from "vue"
import Card from "../common/Card.vue"
import Button from "../common/Button.vue"

const props = defineProps<{
  disabled: boolean
  busy: boolean
  error: string
  lastTx: string
  usdcAllowanceText: string
  mebtcAllowanceText: string
  onApproveUsdc: () => void
  onApproveMebtc: () => void
  onAddLiquidity: (usdcAmount: string, mebtcAmount: string) => void
}>()

const usdcAmount = ref("")
const mebtcAmount = ref("")
</script>

<template>
  <Card title="Liquidity">
    <div class="ui-row">
      <div class="ui-muted">USDC allowance: {{ usdcAllowanceText }}</div>
      <div class="ui-muted">MeBTC allowance: {{ mebtcAllowanceText }}</div>
    </div>

    <div class="ui-row">
      <input
        v-model="usdcAmount"
        type="text"
        placeholder="USDC amount"
        class="ui-input"
        :disabled="disabled || busy"
      />
      <input
        v-model="mebtcAmount"
        type="text"
        placeholder="MeBTC amount"
        class="ui-input"
        :disabled="disabled || busy"
      />
    </div>

    <div class="ui-row">
      <Button :disabled="disabled || busy" @click="() => onApproveUsdc().catch(() => {})">
        Approve USDC
      </Button>
      <Button :disabled="disabled || busy" @click="() => onApproveMebtc().catch(() => {})">
        Approve MeBTC
      </Button>
      <Button
        :disabled="disabled || busy"
        @click="() => onAddLiquidity(usdcAmount, mebtcAmount).catch(() => {})"
      >
        Add Liquidity
      </Button>
    </div>

    <div v-if="error" style="margin-top:10px;">error: {{ error }}</div>
    <div v-if="lastTx" class="ui-muted" style="margin-top:10px;">
      tx: {{ lastTx }}
    </div>
  </Card>
</template>
