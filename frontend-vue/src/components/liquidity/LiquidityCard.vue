<script setup lang="ts">
import { ref, watch } from "vue"
import { formatUnits, parseUnits } from "ethers"
import { TOKENS } from "../../contracts/addresses"
import Card from "../common/Card.vue"
import Button from "../common/Button.vue"
import ErrorPopupInline from "../common/ErrorPopupInline.vue"

const props = defineProps<{
  disabled: boolean
  busy: boolean
  error: string
  lastTx: string
  lpBalanceText: string
  lpPositionUsdcText: string
  lpPositionMebtcText: string
  lpShareText: string
  poolUsdc: bigint
  poolMebtc: bigint
  onAddLiquidity: (usdcAmount: string, mebtcAmount: string) => void
  onRemoveLiquidity: (lpAmount: string) => void
}>()

const usdcAmount = ref("")
const mebtcAmount = ref("")
const lpAmount = ref("")
const lastEdited = ref<"usdc" | "mebtc" | null>(null)
const internalUpdate = ref(false)

function trimZeros(value: string) {
  if (!value.includes(".")) return value
  const trimmed = value.replace(/0+$/, "").replace(/\.$/, "")
  return trimmed === "" ? "0" : trimmed
}

function setUsdcAmount(value: string) {
  internalUpdate.value = true
  usdcAmount.value = value
  internalUpdate.value = false
}

function setMebtcAmount(value: string) {
  internalUpdate.value = true
  mebtcAmount.value = value
  internalUpdate.value = false
}

function updateFromUsdc() {
  const input = usdcAmount.value.trim()
  if (!input) {
    setMebtcAmount("")
    return
  }
  if (props.poolUsdc <= 0n || props.poolMebtc <= 0n) return
  try {
    const usdc = parseUnits(input, TOKENS.usdc.decimals)
    const mebtc = (usdc * props.poolMebtc) / props.poolUsdc
    setMebtcAmount(trimZeros(formatUnits(mebtc, TOKENS.mebtc.decimals)))
  } catch {}
}

function updateFromMebtc() {
  const input = mebtcAmount.value.trim()
  if (!input) {
    setUsdcAmount("")
    return
  }
  if (props.poolUsdc <= 0n || props.poolMebtc <= 0n) return
  try {
    const mebtc = parseUnits(input, TOKENS.mebtc.decimals)
    const usdc = (mebtc * props.poolUsdc) / props.poolMebtc
    setUsdcAmount(trimZeros(formatUnits(usdc, TOKENS.usdc.decimals)))
  } catch {}
}

function safeCall(fn: () => Promise<unknown> | unknown) {
  Promise.resolve(fn()).catch(() => {})
}

watch([usdcAmount, () => props.poolUsdc, () => props.poolMebtc], () => {
  if (internalUpdate.value || lastEdited.value !== "usdc") return
  updateFromUsdc()
}, { flush: "sync" })

watch([mebtcAmount, () => props.poolUsdc, () => props.poolMebtc], () => {
  if (internalUpdate.value || lastEdited.value !== "mebtc") return
  updateFromMebtc()
}, { flush: "sync" })

function onUsdcInput() {
  lastEdited.value = "usdc"
}

function onMebtcInput() {
  lastEdited.value = "mebtc"
}
</script>

<template>
  <Card title="Liquidity">
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
        @input="onUsdcInput"
      />
      <input
        v-model="mebtcAmount"
        type="text"
        placeholder="MeBTC amount"
        class="ui-input"
        :disabled="disabled || busy"
        @input="onMebtcInput"
      />
    </div>

    <div class="ui-row">
      <Button
        :disabled="disabled || busy"
        @click="() => safeCall(() => onAddLiquidity(usdcAmount, mebtcAmount))"
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
      <Button
        :disabled="disabled || busy"
        @click="() => safeCall(() => onRemoveLiquidity(lpAmount))"
      >
        Remove Liquidity
      </Button>
    </div>

    <ErrorPopupInline :error="error" context="Liquidity" />
    <div v-if="lastTx" class="ui-muted" style="margin-top:10px;">
      tx: {{ lastTx }}
    </div>
  </Card>
</template>
