<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { formatUnits } from 'ethers'
import Card from '../common/Card.vue'
import Button from '../common/Button.vue'
import { TOKENS } from '../../contracts/addresses'
import { useMinerModels } from '../../composables/useMinerModels'
import { useMinerUpgradeStates } from '../../composables/useMinerUpgradeStates'

const emit = defineEmits<{
  (e: 'approve-stats', payload: { missing: bigint; endValue: bigint }): void
}>()

const props = defineProps<{
  disabled: boolean
  allowanceMiner: bigint
  approveBusy: boolean
  approveError: string
  approveLastTx: string
  actionBusy: boolean
  actionError: string
  actionLastTx: string
  onApproveExact: (amount: bigint) => void
  onBuyModel: (modelId: number, qty: number) => void
  onUpgradePower: (tokenId: bigint) => void
  onUpgradeHash: (tokenId: bigint) => void
  owned: bigint[]
}>()

const { loading, models, error: modelErr } = useMinerModels()

const selectedModelId = ref<number>(1)
const qty = ref<number>(1)
const upgradeTokenId = ref<string>('')
const upgradeId = computed(() => parsedUpgradeTokenId())

// helpers: macht formatUnits crash-proof
function bn(v: unknown): bigint {
  try {
    if (typeof v === 'bigint') return v
    if (typeof v === 'number') return BigInt(v)
    if (typeof v === 'string' && v.length) return BigInt(v)
    return 0n
  } catch {
    return 0n
  }
}

function fmt(v: unknown) {
  return formatUnits(bn(v), TOKENS.usdc.decimals)
}

const selectedModel = computed(() => models.value.find(m => m.modelId === selectedModelId.value))
const modelById = computed(() => {
  const map = new Map<number, typeof models.value[number]>()
  for (const m of models.value) map.set(m.modelId, m)
  return map
})

const neededForBuy = computed(() => {
  const m = selectedModel.value
  if (!m) return 0n
  const q = BigInt(Math.max(1, qty.value || 1))
  return bn(m.priceUSDC) * q
})

const missingForBuy = computed(() => {
  const need = neededForBuy.value
  const have = bn(props.allowanceMiner)
  return need > have ? (need - have) : 0n
})

// ERC20 approve überschreibt meist -> setze Endwert so, dass es sicher reicht:
const approveEndValue = computed(() => bn(props.allowanceMiner) + missingForBuy.value)

const powerCosts = computed(() => (selectedModel.value?.powerStepCost ?? []).map(bn))
const hashCosts  = computed(() => (selectedModel.value?.hashStepCost  ?? []).map(bn))

function parsedUpgradeTokenId(): bigint | null {
  try {
    if (!upgradeTokenId.value) return null
    return BigInt(upgradeTokenId.value)
  } catch {
    return null
  }
}

const { states: upgradeStates } = useMinerUpgradeStates(() => (upgradeId.value ? [upgradeId.value] : []))

const upgradeState = computed(() => {
  const id = upgradeId.value
  if (!id) return { status: 'idle' } as const
  return upgradeStates.value[id.toString()] ?? ({ status: 'loading' } as const)
})

const upgradeStepsText = computed(() => {
  if (upgradeState.value.status !== 'ok') return ''
  const st = upgradeState.value
  const powerPending = st.powerPendingSteps > 0 ? ` (+${st.powerPendingSteps} pending)` : ''
  const hashPending = st.hashPendingSteps > 0 ? ` (+${st.hashPendingSteps} pending)` : ''
  return `Power: ${st.powerActiveSteps}/${st.maxSteps}${powerPending} | Hash: ${st.hashActiveSteps}/${st.maxSteps}${hashPending}`
})

const upgradeNextCostText = computed(() => {
  if (upgradeState.value.status !== 'ok') return ''
  const st = upgradeState.value
  const model = modelById.value.get(st.modelId)
  if (!model) return ''

  const powerIndex = st.powerActiveSteps + st.powerPendingSteps
  const hashIndex = st.hashActiveSteps + st.hashPendingSteps

  const powerCost = model.powerStepCost?.[powerIndex]
  const hashCost = model.hashStepCost?.[hashIndex]

  const powerText = typeof powerCost === 'bigint' ? fmt(powerCost) : '-'
  const hashText = typeof hashCost === 'bigint' ? fmt(hashCost) : '-'

  return `next cost:P ${powerText} ${TOKENS.usdc.symbol} |H ${hashText} ${TOKENS.usdc.symbol}`
})

watch([missingForBuy, approveEndValue], ([missing, endValue]) => {
  emit('approve-stats', { missing, endValue })
}, { immediate: true })
</script>

<template>
  <Card title="Miner pricing/Buy and upgrade ">
    <div v-if="loading">loading models…</div>
    <div v-else-if="modelErr">error loading models: {{ modelErr }}</div>

    <div v-else>
      <div style="display:flex;gap:10px;flex-wrap:wrap;align-items:center;">
        <label>
          model:
          <select v-model.number="selectedModelId">
            <option v-for="m in models" :key="m.modelId" :value="m.modelId">
              {{ m.modelId }} ({{ m.finalized ? 'live' : 'not live' }})
            </option>
          </select>
        </label>

        <label>
          qty:
          <input v-model.number="qty" type="number" min="1" style="width:80px;" />
        </label>

        <div style="opacity:.8;">
          price:
          <b>{{ fmt(neededForBuy) }} {{ TOKENS.usdc.symbol }}</b>
        </div>

        <Button
          :disabled="disabled || actionBusy || !selectedModel || missingForBuy > 0n"
          @click="onBuyModel(selectedModelId, qty)"
        >
          buy miner (model {{ selectedModelId }}, qty {{ Math.max(1, qty || 1) }})
        </Button>
      </div>

      <div v-if="selectedModel" style="margin-top:10px;opacity:.85;">
        <div>
          hashrate: {{ selectedModel.baseHashrate }} | power: {{ selectedModel.basePowerWatt }}W
        </div>
        <div>
          supply: {{ selectedModel.minted }} / {{ selectedModel.maxSupply }}
        </div>

        <div style="margin-top:8px;">
          <div>
            <b>power step costs (usdc):</b>
            {{ powerCosts.map(x => fmt(x)).join(' | ') }}
          </div>
          <div>
            <b>hash step costs (usdc):</b>
            {{ hashCosts.map(x => fmt(x)).join(' | ') }}
          </div>
        </div>
      </div>

      <div style="margin-top:12px;">
        <div style="font-weight:600;margin-bottom:6px;display:flex;gap:8px;align-items:center;flex-wrap:wrap;">
          <span>upgrade miner</span>
          <span style="font-size:12px;font-weight:400;opacity:.7;">
            (upgrades erst nach erfolgtem claim aktiv)
          </span>
        </div>
        <div style="display:flex;gap:8px;flex-wrap:wrap;align-items:center;">
          <input
            v-model="upgradeTokenId"
            type="text"
            placeholder="tokenId"
            style="width:120px;"
          />
          <Button
            :disabled="disabled || actionBusy || !parsedUpgradeTokenId()"
            @click="() => { const id = parsedUpgradeTokenId(); if (id) onUpgradePower(id) }"
            size="sm"
          >
            <template #icon>
              <svg
                viewBox="0 0 24 24"
                width="12"
                height="12"
                aria-hidden="true"
                style="display:block"
              >
                <path
                  d="M13.2 2 5 13.4h5L9.8 22 19 10.6h-5L13.2 2Z"
                  fill="currentColor"
                />
              </svg>
            </template>
            upgrade power
          </Button>
          <Button
            :disabled="disabled || actionBusy || !parsedUpgradeTokenId()"
            @click="() => { const id = parsedUpgradeTokenId(); if (id) onUpgradeHash(id) }"
            size="sm"
          >
            <template #icon>
              <svg
                viewBox="0 0 24 24"
                width="12"
                height="12"
                aria-hidden="true"
                style="display:block"
              >
                <path
                  d="M6 6h8a2 2 0 0 1 2 2v2H6zM6 12h10v4a2 2 0 0 1-2 2H6z"
                  fill="currentColor"
                />
                <circle cx="8" cy="9" r="1" fill="#fff" />
                <circle cx="12" cy="9" r="1" fill="#fff" />
                <path
                  d="M16.5 4.5 19 2l3 3-2.5 2.5L18 6l-4 4-1.5-1.5 4-4Z"
                  fill="currentColor"
                />
              </svg>
            </template>
            upgrade hash
          </Button>
        </div>
        <div v-if="upgradeTokenId" style="margin-top:6px;font-size:12px;opacity:.75;">
          <span v-if="upgradeState.status === 'loading'">loading upgrade status…</span>
          <span v-else-if="upgradeState.status === 'error'">upgrade status error: {{ upgradeState.error }}</span>
          <span v-else-if="upgradeState.status === 'ok'">
            model: {{ upgradeState.modelId }} | {{ upgradeStepsText }}
          </span>
        </div>
        <div v-if="upgradeState.status === 'ok' && upgradeNextCostText" style="margin-top:4px;font-size:12px;opacity:.75;">
          {{ upgradeNextCostText }}
        </div>
        <div v-if="owned.length" style="margin-top:6px;font-size:12px;opacity:.75;">
          owned tokenIds: {{ owned.map(x => x.toString()).join(', ') }}
        </div>
      </div>

      <div v-if="approveError" style="margin-top:10px;">approve error: {{ approveError }}</div>
      <div v-if="approveLastTx" style="margin-top:10px;opacity:.8;">approve tx: {{ approveLastTx }}</div>
      <div v-if="actionError" style="margin-top:10px;">action error: {{ actionError }}</div>
      <div v-if="actionLastTx" style="margin-top:10px;opacity:.8;">action tx: {{ actionLastTx }}</div>
    </div>
  </Card>
</template>
