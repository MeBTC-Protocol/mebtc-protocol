<script setup lang="ts">
import { computed, ref } from 'vue'
import { formatUnits } from 'ethers'
import Card from '../common/Card.vue'
import { TOKENS } from '../../contracts/addresses'
import { useMinerModels } from '../../composables/useMinerModels'

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
</script>

<template>
  <Card title="miner pricing + allowance (usdc)">
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

        <div style="opacity:.8;">
          allowance minerNFT:
          <b>{{ fmt(allowanceMiner) }} {{ TOKENS.usdc.symbol }}</b>
        </div>

        <button
          :disabled="disabled || approveBusy || missingForBuy === 0n"
          @click="onApproveExact(approveEndValue)"
          style="padding:10px 12px;border-radius:12px;border:1px solid #999;background:transparent;cursor:pointer;"
        >
          approve miner exact (missing {{ fmt(missingForBuy) }} {{ TOKENS.usdc.symbol }})
        </button>

        <button
          :disabled="disabled || actionBusy || !selectedModel || missingForBuy > 0n"
          @click="onBuyModel(selectedModelId, qty)"
          style="padding:10px 12px;border-radius:12px;border:1px solid #999;background:transparent;cursor:pointer;"
        >
          buy miner (model {{ selectedModelId }}, qty {{ Math.max(1, qty || 1) }})
        </button>
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
        <div style="font-weight:600;margin-bottom:6px;">upgrade miner</div>
        <div style="display:flex;gap:8px;flex-wrap:wrap;align-items:center;">
          <input
            v-model="upgradeTokenId"
            type="text"
            placeholder="tokenId"
            style="width:120px;"
          />
          <button
            :disabled="disabled || actionBusy || !parsedUpgradeTokenId()"
            @click="() => { const id = parsedUpgradeTokenId(); if (id) onUpgradePower(id) }"
            style="padding:8px 10px;border-radius:10px;border:1px solid #999;background:transparent;cursor:pointer;"
          >
            upgrade power
          </button>
          <button
            :disabled="disabled || actionBusy || !parsedUpgradeTokenId()"
            @click="() => { const id = parsedUpgradeTokenId(); if (id) onUpgradeHash(id) }"
            style="padding:8px 10px;border-radius:10px;border:1px solid #999;background:transparent;cursor:pointer;"
          >
            upgrade hash
          </button>
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
