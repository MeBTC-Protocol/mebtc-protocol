<script setup lang="ts">
import { computed, ref } from 'vue'
import { formatUnits, parseUnits } from 'ethers'
import { TOKENS } from '../../contracts/addresses'
import Card from '../common/Card.vue'
import Button from '../common/Button.vue'
import ErrorPopupInline from '../common/ErrorPopupInline.vue'

type Direction = 'buy' | 'sell'

const props = defineProps<{
  disabled: boolean
  busy: boolean
  error: string
  lastTx: string
  poolUsdc: bigint
  poolMebtc: bigint
  usdcBalance: bigint
  mebtcBalance: bigint
  onSwap: (params: { direction: Direction; amountIn: string; minOut: string }) => void
}>()

const direction = ref<Direction>('buy')
const amountIn = ref('')
const slippage = ref('1.0')

const inputSymbol = computed(() => direction.value === 'buy' ? TOKENS.usdc.symbol : TOKENS.mebtc.symbol)
const outputSymbol = computed(() => direction.value === 'buy' ? TOKENS.mebtc.symbol : TOKENS.usdc.symbol)
const inputDecimals = computed(() => direction.value === 'buy' ? TOKENS.usdc.decimals : TOKENS.mebtc.decimals)
const outputDecimals = computed(() => direction.value === 'buy' ? TOKENS.mebtc.decimals : TOKENS.usdc.decimals)

function trimZeros(value: string) {
  if (!value.includes('.')) return value
  const trimmed = value.replace(/0+$/, '').replace(/\.$/, '')
  return trimmed === '' ? '0' : trimmed
}

function parseSlippageBps(raw: string) {
  const normalized = raw.trim().replace(',', '.')
  const v = Number(normalized)
  if (!Number.isFinite(v) || v < 0) return 0n
  const bps = Math.round(v * 100)
  return BigInt(Math.min(Math.max(bps, 0), 10_000))
}

const balanceText = computed(() => {
  const bal = direction.value === 'buy' ? props.usdcBalance : props.mebtcBalance
  const decimals = inputDecimals.value
  if (bal <= 0n) return '0'
  return trimZeros(formatUnits(bal, decimals))
})

function setMax() {
  amountIn.value = balanceText.value
}

function getAmountOut(amountInValue: bigint, reserveIn: bigint, reserveOut: bigint) {
  if (amountInValue <= 0n || reserveIn <= 0n || reserveOut <= 0n) return 0n
  const amountInWithFee = amountInValue * 997n
  const numerator = amountInWithFee * reserveOut
  const denominator = reserveIn * 1000n + amountInWithFee
  if (denominator === 0n) return 0n
  return numerator / denominator
}

const estimatedOutAmount = computed<bigint | null>(() => {
  const input = amountIn.value.trim()
  if (!input) return null
  if (props.poolUsdc <= 0n || props.poolMebtc <= 0n) return null

  try {
    const parsedIn = parseUnits(input, inputDecimals.value)
    const reserveIn = direction.value === 'buy' ? props.poolUsdc : props.poolMebtc
    const reserveOut = direction.value === 'buy' ? props.poolMebtc : props.poolUsdc
    return getAmountOut(parsedIn, reserveIn, reserveOut)
  } catch {
    return null
  }
})

const estimatedOutText = computed(() => {
  if (estimatedOutAmount.value === null) return '-'
  return trimZeros(formatUnits(estimatedOutAmount.value, outputDecimals.value))
})

const minOutText = computed(() => {
  if (estimatedOutAmount.value === null) return '0'
  const bps = parseSlippageBps(slippage.value)
  const minOut = (estimatedOutAmount.value * (10_000n - bps)) / 10_000n
  return trimZeros(formatUnits(minOut, outputDecimals.value))
})

function toggleDirection() {
  direction.value = direction.value === 'buy' ? 'sell' : 'buy'
}
</script>

<template>
  <Card title="Swap">
    <div class="ui-subtitle" style="margin-top:8px;">Swap direction</div>
    <div class="ui-row">
      <Button size="sm" :disabled="disabled || busy" @click="toggleDirection">
        {{ inputSymbol }} -> {{ outputSymbol }}
      </Button>
      <div class="ui-muted">balance: {{ balanceText }} {{ inputSymbol }}</div>
    </div>

    <div class="ui-subtitle" style="margin-top:10px;">Amount</div>
    <div class="ui-row">
      <input
        v-model="amountIn"
        type="text"
        :placeholder="`Amount in ${inputSymbol}`"
        class="ui-input"
        :disabled="disabled || busy"
      />
      <Button size="sm" :disabled="disabled || busy" @click="setMax">
        Max
      </Button>
    </div>

    <div class="ui-row" style="margin-top:6px;">
      <div class="ui-muted">est. out: {{ estimatedOutText }} {{ outputSymbol }}</div>
      <div class="ui-muted">min out: {{ minOutText }} {{ outputSymbol }}</div>
    </div>

    <div class="ui-subtitle" style="margin-top:10px;">Slippage</div>
    <div class="ui-row">
      <input
        v-model="slippage"
        type="text"
        placeholder="Slippage % (z. B. 1.0)"
        class="ui-input"
        :disabled="disabled || busy"
      />
      <div class="ui-muted">fee est.: 0.3%</div>
    </div>

    <div class="ui-row" style="margin-top:10px;">
      <Button
        variant="solid"
        :disabled="disabled || busy || !amountIn"
        @click="() => onSwap({ direction, amountIn, minOut: minOutText }).catch(() => {})"
      >
        Swap
      </Button>
    </div>

    <ErrorPopupInline :error="error" context="Swap" />
    <div v-if="lastTx" class="ui-muted" style="margin-top:10px;">
      tx: {{ lastTx }}
    </div>
  </Card>
</template>
