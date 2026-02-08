<script setup lang="ts">
import { computed, ref } from "vue"
import { formatUnits } from "ethers"
import Card from "../common/Card.vue"
import Button from "../common/Button.vue"
import ErrorPopupInline from "../common/ErrorPopupInline.vue"
import { TOKENS } from "../../contracts/addresses"

const props = defineProps<{
  disabled: boolean
  busy: boolean
  error: string
  lastTx: string
  allowanceText: string
  stakedBalance: bigint
  tier: number
  unlockAt: number
  hashBonusBps: number
  powerBonusBps: number
  mebtcDecimals: number
  inputError: string
  onStake: (amount: string) => void
  onUnstake: (amount: string) => void
}>()

const amount = ref("")
const tierOptions = [
  { label: "Tier 1 (10k)", amount: "10000", bonus: "+5% Hash / -5% Power", lock: "30d" },
  { label: "Tier 2 (50k)", amount: "50000", bonus: "+10% Hash / -12% Power", lock: "90d" },
  { label: "Tier 3 (250k)", amount: "250000", bonus: "+15% Hash / -20% Power", lock: "180d" }
]

const unlockLabel = computed(() => {
  if (!props.unlockAt) return "-"
  const d = new Date(props.unlockAt * 1000)
  return d.toLocaleString()
})

const isLocked = computed(() => {
  if (!props.unlockAt) return false
  return Math.floor(Date.now() / 1000) < props.unlockAt
})

const tierLabel = computed(() => {
  if (props.tier <= 0) return "None"
  return `Tier ${props.tier}`
})

function safeCall(fn: () => Promise<unknown> | unknown) {
  Promise.resolve(fn()).catch(() => {})
}

</script>

<template>
  <Card title="Staking">
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
        :disabled="disabled || busy"
      />
      <div class="ui-row">
        <Button
          v-for="opt in tierOptions"
          :key="opt.label"
          :disabled="disabled || busy"
          @click="amount = opt.amount"
        >
          {{ opt.label }}
        </Button>
      </div>
      <div class="ui-row ui-muted" style="gap:16px;">
        <div v-for="opt in tierOptions" :key="opt.label">
          {{ opt.label }}: {{ opt.bonus }} (Lock {{ opt.lock }})
        </div>
      </div>
      <Button :disabled="disabled || busy" @click="() => safeCall(() => onStake(amount))">
        Stake
      </Button>
      <Button
        :disabled="disabled || busy || isLocked"
        @click="() => safeCall(() => onUnstake(amount))"
      >
        Unstake
      </Button>
    </div>

    <div v-if="isLocked" class="ui-muted" style="margin-top:10px;">
      lock aktiv - unstake erst nach unlock
    </div>

    <ErrorPopupInline :error="error" context="Staking" />
    <ErrorPopupInline :error="inputError" context="Staking Eingabe" />

    <div v-if="lastTx" class="ui-muted" style="margin-top:10px;">
      tx: {{ lastTx }}
    </div>
  </Card>
</template>
