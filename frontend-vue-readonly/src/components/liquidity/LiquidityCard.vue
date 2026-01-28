<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { formatUnits, parseUnits } from 'ethers'
import { ADDRESSES, TOKENS } from '../../contracts/addresses'
import Card from '../common/Card.vue'
import Button from '../common/Button.vue'

const props = defineProps<{
  disabled: boolean
  lpBalanceText: string
  lpPositionUsdcText: string
  lpPositionMebtcText: string
  lpShareText: string
  poolUsdc: bigint
  poolMebtc: bigint
  lpBalance: bigint
  positionUsdc: bigint
  positionMebtc: bigint
  userAddress: string
  routerAddress: string
  pairAddress: string
  blockExplorerBase: string
}>()

const usdcAmount = ref('')
const mebtcAmount = ref('')
const lpAmount = ref('')
const slippage = ref('1.0')
const lastEdited = ref<'usdc' | 'mebtc' | null>(null)
const internalUpdate = ref(false)

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
    setMebtcAmount('')
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
    setUsdcAmount('')
    return
  }
  if (props.poolUsdc <= 0n || props.poolMebtc <= 0n) return
  try {
    const mebtc = parseUnits(input, TOKENS.mebtc.decimals)
    const usdc = (mebtc * props.poolUsdc) / props.poolMebtc
    setUsdcAmount(trimZeros(formatUnits(usdc, TOKENS.usdc.decimals)))
  } catch {}
}

watch([usdcAmount, () => props.poolUsdc, () => props.poolMebtc], () => {
  if (internalUpdate.value || lastEdited.value !== 'usdc') return
  updateFromUsdc()
}, { flush: 'sync' })

watch([mebtcAmount, () => props.poolUsdc, () => props.poolMebtc], () => {
  if (internalUpdate.value || lastEdited.value !== 'mebtc') return
  updateFromMebtc()
}, { flush: 'sync' })

function onUsdcInput() {
  lastEdited.value = 'usdc'
}

function onMebtcInput() {
  lastEdited.value = 'mebtc'
}

const usdcParsed = computed(() => {
  const v = usdcAmount.value.trim()
  if (!v) return null
  try {
    return parseUnits(v, TOKENS.usdc.decimals)
  } catch {
    return null
  }
})

const mebtcParsed = computed(() => {
  const v = mebtcAmount.value.trim()
  if (!v) return null
  try {
    return parseUnits(v, TOKENS.mebtc.decimals)
  } catch {
    return null
  }
})

const lpParsed = computed(() => {
  const v = lpAmount.value.trim()
  if (!v) return null
  try {
    return parseUnits(v, 18)
  } catch {
    return null
  }
})

const minUsdcAdd = computed(() => {
  if (!usdcParsed.value) return 0n
  const bps = parseSlippageBps(slippage.value)
  return (usdcParsed.value * (10_000n - bps)) / 10_000n
})

const minMebtcAdd = computed(() => {
  if (!mebtcParsed.value) return 0n
  const bps = parseSlippageBps(slippage.value)
  return (mebtcParsed.value * (10_000n - bps)) / 10_000n
})

const expectedRemove = computed(() => {
  if (!lpParsed.value || props.lpBalance <= 0n) return { usdc: 0n, mebtc: 0n }
  const usdc = (props.positionUsdc * lpParsed.value) / props.lpBalance
  const mebtc = (props.positionMebtc * lpParsed.value) / props.lpBalance
  return { usdc, mebtc }
})

const minUsdcRemove = computed(() => {
  const bps = parseSlippageBps(slippage.value)
  return (expectedRemove.value.usdc * (10_000n - bps)) / 10_000n
})

const minMebtcRemove = computed(() => {
  const bps = parseSlippageBps(slippage.value)
  return (expectedRemove.value.mebtc * (10_000n - bps)) / 10_000n
})

const deadline = computed(() => Math.floor(Date.now() / 1000) + 1200)

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
  <Card title="Liquidity (Read-only)">
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
        :disabled="disabled"
        @input="onUsdcInput"
      />
      <input
        v-model="mebtcAmount"
        type="text"
        placeholder="MeBTC amount"
        class="ui-input"
        :disabled="disabled"
        @input="onMebtcInput"
      />
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
    </div>

    <div class="ui-section ui-stack-sm">
      <div class="ui-subtitle">Schritt 1: Allowance (USDC + MeBTC)</div>
      <div class="ui-row">
        <span class="ui-muted">USDC:</span>
        <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
          {{ ADDRESSES.usdc }}
        </span>
        <Button size="sm" @click="openExplorer(ADDRESSES.usdc)">Open</Button>
      </div>
      <div class="ui-row">
        <span class="ui-muted">MeBTC:</span>
        <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
          {{ ADDRESSES.mebtc }}
        </span>
        <Button size="sm" @click="openExplorer(ADDRESSES.mebtc)">Open</Button>
      </div>
      <div class="ui-row">
        <span class="ui-muted">Spender (Router):</span>
        <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
          {{ routerAddress }}
        </span>
        <Button size="sm" :disabled="!routerAddress" @click="copyText('Spender', routerAddress)">Copy</Button>
      </div>
      <div class="ui-row">
        <span class="ui-muted">USDC Amount (raw):</span>
        <span class="ui-muted">{{ usdcParsed ?? 0n }}</span>
        <Button size="sm" :disabled="!usdcParsed" @click="copyText('USDC Amount', String(usdcParsed ?? 0n))">Copy</Button>
      </div>
      <div class="ui-row">
        <span class="ui-muted">MeBTC Amount (raw):</span>
        <span class="ui-muted">{{ mebtcParsed ?? 0n }}</span>
        <Button size="sm" :disabled="!mebtcParsed" @click="copyText('MeBTC Amount', String(mebtcParsed ?? 0n))">Copy</Button>
      </div>
    </div>

    <div class="ui-section ui-stack-sm">
      <div class="ui-subtitle">Schritt 2: addLiquidity im Explorer</div>
      <div class="ui-row">
        <span class="ui-muted">tokenA:</span>
        <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
          {{ ADDRESSES.usdc }}
        </span>
      </div>
      <div class="ui-row">
        <span class="ui-muted">tokenB:</span>
        <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
          {{ ADDRESSES.mebtc }}
        </span>
      </div>
      <div class="ui-row">
        <span class="ui-muted">amountADesired:</span>
        <span class="ui-muted">{{ usdcParsed ?? 0n }}</span>
        <Button size="sm" :disabled="!usdcParsed" @click="copyText('amountADesired', String(usdcParsed ?? 0n))">Copy</Button>
      </div>
      <div class="ui-row">
        <span class="ui-muted">amountBDesired:</span>
        <span class="ui-muted">{{ mebtcParsed ?? 0n }}</span>
        <Button size="sm" :disabled="!mebtcParsed" @click="copyText('amountBDesired', String(mebtcParsed ?? 0n))">Copy</Button>
      </div>
      <div class="ui-row">
        <span class="ui-muted">amountAMin:</span>
        <span class="ui-muted">{{ minUsdcAdd }}</span>
        <Button size="sm" @click="copyText('amountAMin', String(minUsdcAdd))">Copy</Button>
      </div>
      <div class="ui-row">
        <span class="ui-muted">amountBMin:</span>
        <span class="ui-muted">{{ minMebtcAdd }}</span>
        <Button size="sm" @click="copyText('amountBMin', String(minMebtcAdd))">Copy</Button>
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

    <div class="ui-section">
      <div class="ui-subtitle">Remove liquidity</div>
      <div class="ui-row">
        <input
          v-model="lpAmount"
          type="text"
          placeholder="LP amount"
          class="ui-input"
          :disabled="disabled"
        />
        <Button :disabled="disabled" @click="lpAmount = lpBalanceText">Max</Button>
      </div>
      <div class="ui-row" style="margin-top:6px;">
        <div class="ui-muted">expected: {{ formatUnits(expectedRemove.usdc, TOKENS.usdc.decimals) }} USDC / {{ formatUnits(expectedRemove.mebtc, TOKENS.mebtc.decimals) }} MeBTC</div>
      </div>

      <div class="ui-section ui-stack-sm">
        <div class="ui-subtitle">Schritt 1: Allowance (LP Token)</div>
        <div class="ui-row">
          <span class="ui-muted">LP Token:</span>
          <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
            {{ pairAddress }}
          </span>
          <Button size="sm" :disabled="!pairAddress" @click="openExplorer(pairAddress)">Open</Button>
        </div>
        <div class="ui-row">
          <span class="ui-muted">Spender (Router):</span>
          <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
            {{ routerAddress }}
          </span>
          <Button size="sm" :disabled="!routerAddress" @click="copyText('Spender', routerAddress)">Copy</Button>
        </div>
        <div class="ui-row">
          <span class="ui-muted">LP Amount (raw):</span>
          <span class="ui-muted">{{ lpParsed ?? 0n }}</span>
          <Button size="sm" :disabled="!lpParsed" @click="copyText('LP Amount', String(lpParsed ?? 0n))">Copy</Button>
        </div>
      </div>

      <div class="ui-section ui-stack-sm">
        <div class="ui-subtitle">Schritt 2: removeLiquidity im Explorer</div>
        <div class="ui-row">
          <span class="ui-muted">tokenA:</span>
          <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
            {{ ADDRESSES.usdc }}
          </span>
        </div>
        <div class="ui-row">
          <span class="ui-muted">tokenB:</span>
          <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
            {{ ADDRESSES.mebtc }}
          </span>
        </div>
        <div class="ui-row">
          <span class="ui-muted">liquidity:</span>
          <span class="ui-muted">{{ lpParsed ?? 0n }}</span>
          <Button size="sm" :disabled="!lpParsed" @click="copyText('liquidity', String(lpParsed ?? 0n))">Copy</Button>
        </div>
        <div class="ui-row">
          <span class="ui-muted">amountAMin:</span>
          <span class="ui-muted">{{ minUsdcRemove }}</span>
          <Button size="sm" @click="copyText('amountAMin', String(minUsdcRemove))">Copy</Button>
        </div>
        <div class="ui-row">
          <span class="ui-muted">amountBMin:</span>
          <span class="ui-muted">{{ minMebtcRemove }}</span>
          <Button size="sm" @click="copyText('amountBMin', String(minMebtcRemove))">Copy</Button>
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
    </div>

    <div v-if="copyNote" class="ui-muted" style="margin-top:8px;">{{ copyNote }}</div>
  </Card>
</template>
