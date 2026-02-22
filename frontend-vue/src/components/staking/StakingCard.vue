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
  {
    label: "Tier 1 (10k)",
    amount: "10000",
    bonus: "+5% Hash / -5% Power",
    lock: "30d"
  },
  {
    label: "Tier 2 (50k)",
    amount: "50000",
    bonus: "+10% Hash / -12% Power",
    lock: "90d"
  },
  {
    label: "Tier 3 (250k)",
    amount: "250000",
    bonus: "+15% Hash / -20% Power",
    lock: "180d"
  }
]

const stakingTitleInfo = [
  "Tier 1 ab 10.000 MeBTC: +5% Hash / -5% Power, Lock 30d",
  "Tier 2 ab 50.000 MeBTC: +10% Hash / -12% Power, Lock 90d",
  "Tier 3 ab 250.000 MeBTC: +15% Hash / -20% Power, Lock 180d",
  "Der Tier richtet sich nach dem gesamten Stake (z. B. 10k + 40k = Tier 2).",
  "Bei Tier-Aufstieg wird die Unlock-Zeit auf die neue Lock-Dauer verlaengert."
].join("\n")

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

const stakeHelp = "Fuehrt Stake mit dem Betrag aus dem Eingabefeld aus."

const unstakeHelp = computed(() => {
  if (isLocked.value) return `Unstake gesperrt bis ${unlockLabel.value}.`
  return "Fuehrt Unstake mit dem Betrag aus dem Eingabefeld aus."
})

function safeCall(fn: () => Promise<unknown> | unknown) {
  Promise.resolve(fn()).catch(() => {})
}

</script>

<template>
  <Card title="Staking" :title-info="stakingTitleInfo" compact collapsible>
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
        <div v-for="opt in tierOptions" :key="opt.label" class="stake-tooltip-wrap">
          <Button :disabled="disabled || busy" @click="amount = opt.amount">
            {{ opt.label }}
          </Button>
          <span class="stake-tooltip">
            {{ opt.label }}: {{ opt.bonus }} (Lock {{ opt.lock }})
          </span>
        </div>
      </div>
      <div class="stake-tooltip-wrap">
        <Button :disabled="disabled || busy" @click="() => safeCall(() => onStake(amount))">
          Stake
        </Button>
        <span class="stake-tooltip">
          {{ stakeHelp }}
        </span>
      </div>
      <div class="stake-tooltip-wrap">
        <Button
          :disabled="disabled || busy || isLocked"
          @click="() => safeCall(() => onUnstake(amount))"
        >
          Unstake
        </Button>
        <span class="stake-tooltip">
          {{ unstakeHelp }}
        </span>
      </div>
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

<style scoped>
.stake-tooltip-wrap {
  position: relative;
}

.stake-tooltip {
  position: absolute;
  top: calc(100% + 8px);
  left: 0;
  z-index: 30;
  min-width: 220px;
  max-width: min(320px, 70vw);
  border: var(--ui-border-width) solid var(--ui-border);
  border-radius: var(--ui-radius-md);
  background: var(--ui-panel);
  box-shadow: 0 16px 30px -24px var(--ui-shadow-color);
  color: var(--ui-text-muted);
  font-size: 11px;
  line-height: 1.35;
  padding: 8px 10px;
  opacity: 0;
  transform: translateY(-4px);
  pointer-events: none;
  transition: opacity 120ms ease, transform 120ms ease;
}

.stake-tooltip-wrap:hover .stake-tooltip,
.stake-tooltip-wrap:focus-within .stake-tooltip {
  opacity: 1;
  transform: translateY(0);
}
</style>
