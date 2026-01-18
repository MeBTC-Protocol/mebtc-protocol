<script setup lang="ts">
import { computed, ref } from "vue"
import { formatUnits } from "ethers"
import Card from "../common/Card.vue"
import Button from "../common/Button.vue"
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
  onApprove: () => void
  onStake: (amount: string) => void
  onUnstake: (amount: string) => void
}>()

const amount = ref("")

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
      <Button :disabled="disabled || busy" @click="() => onApprove().catch(() => {})">
        Approve MeBTC
      </Button>
      <Button :disabled="disabled || busy" @click="() => onStake(amount).catch(() => {})">
        Stake
      </Button>
      <Button
        :disabled="disabled || busy || isLocked"
        @click="() => onUnstake(amount).catch(() => {})"
      >
        Unstake
      </Button>
    </div>

    <div v-if="isLocked" class="ui-muted" style="margin-top:10px;">
      lock aktiv - unstake erst nach unlock
    </div>

    <div v-if="error" style="margin-top:10px;">error: {{ error }}</div>

    <div v-if="lastTx" class="ui-muted" style="margin-top:10px;">
      tx: {{ lastTx }}
    </div>
  </Card>
</template>
