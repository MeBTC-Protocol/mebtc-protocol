<script setup lang="ts">
import { computed, ref } from 'vue'
import { formatUnits, parseUnits } from 'ethers'
import { ADDRESSES, TOKENS } from '../../contracts/addresses'
import Card from '../common/Card.vue'
import Button from '../common/Button.vue'

type Direction = 'buy' | 'sell'

const props = defineProps<{
  disabled: boolean
  poolUsdc: bigint
  poolMebtc: bigint
  usdcBalance: bigint
  mebtcBalance: bigint
  userAddress: string
  routerAddress: string
  blockExplorerBase: string
}>()

const direction = ref<Direction>('buy')
const amountIn = ref('')
const slippage = ref('1.0')

const inputSymbol = computed(() => direction.value === 'buy' ? TOKENS.usdc.symbol : TOKENS.mebtc.symbol)
const outputSymbol = computed(() => direction.value === 'buy' ? TOKENS.mebtc.symbol : TOKENS.usdc.symbol)
const inputDecimals = computed(() => direction.value === 'buy' ? TOKENS.usdc.decimals : TOKENS.mebtc.decimals)
const outputDecimals = computed(() => direction.value === 'buy' ? TOKENS.mebtc.decimals : TOKENS.usdc.decimals)
const tokenInAddress = computed(() => direction.value === 'buy' ? ADDRESSES.usdc : ADDRESSES.mebtc)
const tokenOutAddress = computed(() => direction.value === 'buy' ? ADDRESSES.mebtc : ADDRESSES.usdc)

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

const amountInRaw = computed(() => {
  const input = amountIn.value.trim()
  if (!input) return null
  try {
    return parseUnits(input, inputDecimals.value)
  } catch {
    return null
  }
})

const minOutRaw = computed(() => {
  if (estimatedOutAmount.value === null) return 0n
  const bps = parseSlippageBps(slippage.value)
  return (estimatedOutAmount.value * (10_000n - bps)) / 10_000n
})

const pathText = computed(() => `[${tokenInAddress.value}, ${tokenOutAddress.value}]`)

const deadline = computed(() => Math.floor(Date.now() / 1000) + 1200)

function toggleDirection() {
  direction.value = direction.value === 'buy' ? 'sell' : 'buy'
}

const copyNote = ref('')
let copyTimer: number | undefined

function setCopyNote(msg: string) {
  copyNote.value = msg
  if (copyTimer) window.clearTimeout(copyTimer)
  copyTimer = window.setTimeout(() => {
    copyNote.value = ''
  }, 1600)
}

async function copyText(label: string, text: string) {
  if (!text) return
  try {
    if (!navigator?.clipboard?.writeText) throw new Error('clipboard not available')
    await navigator.clipboard.writeText(text)
    setCopyNote(`${label} kopiert`)
  } catch {
    setCopyNote('kopieren fehlgeschlagen')
  }
}

function openExplorer(address: string) {
  if (!address || !props.blockExplorerBase) return
  const base = props.blockExplorerBase.replace(/\/$/, '')
  const url = `${base}/address/${address}`
  window.open(url, '_blank', 'noopener')
}
</script>

<template>
  <Card title="Swap (Read-only)">
    <div class="ui-subtitle" style="margin-top:8px;">Swap direction</div>
    <div class="ui-row">
      <Button size="sm" :disabled="disabled" @click="toggleDirection">
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
        :disabled="disabled"
      />
      <Button size="sm" :disabled="disabled" @click="setMax">
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
        :disabled="disabled"
      />
      <div class="ui-muted">fee est.: 0.3%</div>
    </div>

    <div class="ui-section ui-stack-sm">
      <div class="ui-subtitle">Schritt 1: Allowance (Input Token)</div>
      <div class="ui-muted">Spender: Router</div>
      <div class="ui-row">
        <span class="ui-muted">Token:</span>
        <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
          {{ tokenInAddress }}
        </span>
        <Button size="sm" :disabled="!tokenInAddress" @click="openExplorer(tokenInAddress)">Open</Button>
        <Button size="sm" :disabled="!tokenInAddress" @click="copyText('Token', tokenInAddress)">Copy</Button>
      </div>
      <div class="ui-row">
        <span class="ui-muted">Spender (Router):</span>
        <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
          {{ routerAddress }}
        </span>
        <Button size="sm" :disabled="!routerAddress" @click="copyText('Spender', routerAddress)">Copy</Button>
      </div>
      <div class="ui-row">
        <span class="ui-muted">Amount (raw):</span>
        <span class="ui-muted">{{ amountInRaw ?? 0n }}</span>
        <Button size="sm" :disabled="!amountInRaw" @click="copyText('Amount', String(amountInRaw ?? 0n))">Copy</Button>
      </div>
    </div>

    <div class="ui-section ui-stack-sm">
      <div class="ui-subtitle">Schritt 2: Swap im Explorer</div>
      <div class="ui-muted">Router-Funktion: swapExactTokensForTokens</div>
      <div class="ui-row">
        <span class="ui-muted">amountIn:</span>
        <span class="ui-muted">{{ amountInRaw ?? 0n }}</span>
        <Button size="sm" :disabled="!amountInRaw" @click="copyText('amountIn', String(amountInRaw ?? 0n))">Copy</Button>
      </div>
      <div class="ui-row">
        <span class="ui-muted">amountOutMin:</span>
        <span class="ui-muted">{{ minOutRaw }}</span>
        <Button size="sm" @click="copyText('amountOutMin', String(minOutRaw))">Copy</Button>
      </div>
      <div class="ui-row">
        <span class="ui-muted">path:</span>
        <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
          {{ pathText }}
        </span>
        <Button size="sm" @click="copyText('path', pathText)">Copy</Button>
      </div>
      <div class="ui-row">
        <span class="ui-muted">to:</span>
        <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
          {{ userAddress || '-' }}
        </span>
        <Button size="sm" :disabled="!userAddress" @click="copyText('to', userAddress)">Copy</Button>
      </div>
      <div class="ui-row">
        <span class="ui-muted">deadline:</span>
        <span class="ui-muted">{{ deadline }}</span>
        <Button size="sm" @click="copyText('deadline', String(deadline))">Copy</Button>
      </div>
      <div class="ui-row">
        <Button size="sm" :disabled="!routerAddress" @click="openExplorer(routerAddress)">Router im Explorer öffnen</Button>
      </div>
    </div>

    <div v-if="copyNote" class="ui-muted" style="margin-top:8px;">{{ copyNote }}</div>
  </Card>
</template>
