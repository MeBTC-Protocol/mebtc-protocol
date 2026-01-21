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
  lpAllowanceText: string
  lpBalanceText: string
  lpPositionUsdcText: string
  lpPositionMebtcText: string
  lpShareText: string
  onApproveUsdc: () => void
  onApproveMebtc: () => void
  onApproveLp: () => void
  onAddLiquidity: (usdcAmount: string, mebtcAmount: string) => void
  onRemoveLiquidity: (lpAmount: string) => void
}>()

const usdcAmount = ref("")
const mebtcAmount = ref("")
const lpAmount = ref("")
</script>

<template>
  <Card title="Liquidity">
    <div class="ui-row">
      <div class="ui-muted">USDC allowance: {{ usdcAllowanceText }}</div>
      <div class="ui-muted">MeBTC allowance: {{ mebtcAllowanceText }}</div>
      <div class="ui-muted">LP allowance: {{ lpAllowanceText }}</div>
    </div>
    <div class="ui-row">
      <div class="ui-muted">LP balance: {{ lpBalanceText }}</div>
      <div class="ui-muted">
        position (est.): {{ lpPositionUsdcText }} USDC / {{ lpPositionMebtcText }} MeBTC
      </div>
      <div class="ui-muted">pool share: {{ lpShareText }}</div>
    </div>

    <div class="ui-subtitle" style="margin-top:8px;">Add liquidity</div>
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

    <div class="ui-subtitle" style="margin-top:12px;">Remove liquidity</div>
    <div class="ui-row">
      <input
        v-model="lpAmount"
        type="text"
        placeholder="LP amount"
        class="ui-input"
        :disabled="disabled || busy"
      />
      <Button :disabled="disabled || busy" @click="lpAmount = lpBalanceText">
        Max
      </Button>
      <Button :disabled="disabled || busy" @click="() => onApproveLp().catch(() => {})">
        Approve LP
      </Button>
      <Button
        :disabled="disabled || busy"
        @click="() => onRemoveLiquidity(lpAmount).catch(() => {})"
      >
        Remove Liquidity
      </Button>
    </div>

    <div v-if="error" style="margin-top:10px;">error: {{ error }}</div>
    <div v-if="lastTx" class="ui-muted" style="margin-top:10px;">
      tx: {{ lastTx }}
    </div>
  </Card>
</template>
