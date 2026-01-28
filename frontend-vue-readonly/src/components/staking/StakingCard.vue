<script setup lang="ts">
import { computed, ref } from 'vue'
import { formatUnits, parseUnits } from 'ethers'
import Card from '../common/Card.vue'
import Button from '../common/Button.vue'
import { ADDRESSES, TOKENS } from '../../contracts/addresses'

const props = defineProps<{
  disabled: boolean
  allowanceText: string
  stakedBalance: bigint
  tier: number
  unlockAt: number
  hashBonusBps: number
  powerBonusBps: number
  mebtcDecimals: number
  stakeVaultAddress: string
  blockExplorerBase: string
  userAddress: string
}>()

const amount = ref('')
const tierOptions = [
  { label: 'Tier 1 (10k)', amount: '10000', bonus: '+5% Hash / -5% Power', lock: '30d' },
  { label: 'Tier 2 (50k)', amount: '50000', bonus: '+10% Hash / -12% Power', lock: '90d' },
  { label: 'Tier 3 (250k)', amount: '250000', bonus: '+15% Hash / -20% Power', lock: '180d' }
]

const unlockLabel = computed(() => {
  if (!props.unlockAt) return '-'
  const d = new Date(props.unlockAt * 1000)
  return d.toLocaleString()
})

const isLocked = computed(() => {
  if (!props.unlockAt) return false
  return Math.floor(Date.now() / 1000) < props.unlockAt
})

const tierLabel = computed(() => {
  if (props.tier <= 0) return 'None'
  return `Tier ${props.tier}`
})

const amountRaw = computed(() => {
  const v = amount.value.trim()
  if (!v) return null
  try {
    return parseUnits(v, props.mebtcDecimals || TOKENS.mebtc.decimals)
  } catch {
    return null
  }
})

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
  <Card title="Staking (Read-only)">
    <div class="ui-row">
      <div class="ui-muted">
        staked: {{ formatUnits(stakedBalance, mebtcDecimals || TOKENS.mebtc.decimals) }} MeBTC
      </div>
      <div class="ui-muted">tier: {{ tierLabel }}</div>
      <div class="ui-muted">unlock: {{ unlockLabel }}</div>
    </div>

    <div class="ui-row">
      <div class="ui-muted">bonus hash: +{{ (hashBonusBps / 100).toFixed(2) }}%</div>
      <div class="ui-muted">bonus power: -{{ (powerBonusBps / 100).toFixed(2) }}%</div>
      <div class="ui-muted">allowance: {{ allowanceText }} MeBTC</div>
    </div>

    <div class="ui-row">
      <input
        v-model="amount"
        type="text"
        placeholder="amount"
        class="ui-input"
        :disabled="disabled"
      />
      <div class="ui-row">
        <Button
          v-for="opt in tierOptions"
          :key="opt.label"
          :disabled="disabled"
          @click="amount = opt.amount"
        >
          {{ opt.label }}
        </Button>
      </div>
    </div>

    <div class="ui-row ui-muted" style="gap:16px; margin-top:6px;">
      <div v-for="opt in tierOptions" :key="opt.label">
        {{ opt.label }}: {{ opt.bonus }} (Lock {{ opt.lock }})
      </div>
    </div>

    <div class="ui-section ui-stack-sm">
      <div class="ui-subtitle">Schritt 1: Allowance (MeBTC)</div>
      <div class="ui-row">
        <span class="ui-muted">Token:</span>
        <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
          {{ ADDRESSES.mebtc }}
        </span>
        <Button size="sm" @click="openExplorer(ADDRESSES.mebtc)">Open</Button>
      </div>
      <div class="ui-row">
        <span class="ui-muted">Spender (StakeVault):</span>
        <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
          {{ stakeVaultAddress }}
        </span>
        <Button size="sm" :disabled="!stakeVaultAddress" @click="copyText('Spender', stakeVaultAddress)">Copy</Button>
      </div>
      <div class="ui-row">
        <span class="ui-muted">Amount (raw):</span>
        <span class="ui-muted">{{ amountRaw ?? 0n }}</span>
        <Button size="sm" :disabled="!amountRaw" @click="copyText('Amount', String(amountRaw ?? 0n))">Copy</Button>
      </div>
    </div>

    <div class="ui-section ui-stack-sm">
      <div class="ui-subtitle">Schritt 2: Stake/Unstake im Explorer</div>
      <div class="ui-row">
        <span class="ui-muted">Stake function:</span>
        <span class="ui-muted">stake(uint256 amount)</span>
        <Button size="sm" @click="copyText('Funktion', 'stake(uint256 amount)')">Copy</Button>
      </div>
      <div class="ui-row">
        <span class="ui-muted">Unstake function:</span>
        <span class="ui-muted">unstake(uint256 amount)</span>
        <Button size="sm" @click="copyText('Funktion', 'unstake(uint256 amount)')">Copy</Button>
      </div>
      <div class="ui-row">
        <span class="ui-muted">amount (raw):</span>
        <span class="ui-muted">{{ amountRaw ?? 0n }}</span>
        <Button size="sm" :disabled="!amountRaw" @click="copyText('amount', String(amountRaw ?? 0n))">Copy</Button>
      </div>
      <div class="ui-row">
        <span class="ui-muted">Contract:</span>
        <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
          {{ stakeVaultAddress }}
        </span>
        <Button size="sm" :disabled="!stakeVaultAddress" @click="openExplorer(stakeVaultAddress)">Open</Button>
      </div>
      <div v-if="isLocked" class="ui-muted" style="margin-top:6px;">
        lock aktiv - unstake erst nach unlock
      </div>
    </div>

    <div v-if="copyNote" class="ui-muted" style="margin-top:8px;">{{ copyNote }}</div>
  </Card>
</template>
