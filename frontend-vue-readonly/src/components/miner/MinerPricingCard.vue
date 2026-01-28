<script setup lang="ts">
import { computed, ref } from 'vue'
import { formatUnits } from 'ethers'
import Card from '../common/Card.vue'
import Button from '../common/Button.vue'
import { useMinerModels } from '../../composables/useMinerModels'
import { useMinerUpgradeStates } from '../../composables/useMinerUpgradeStates'

const props = defineProps<{
  disabled: boolean
  allowanceMiner: bigint
  payTokenSymbol: string
  payTokenDecimals: number
  mebtcDecimals: number
  mebtcPriceUsdc: bigint
  owned: bigint[]
  payTokenAddress: string
  minerNftAddress: string
  blockExplorerBase: string
}>()

const { loading, models, error: modelErr } = useMinerModels()

const selectedModelId = ref<number>(1)
const qty = ref<number>(1)
const upgradeTokenId = ref<string>('')
const upgradeId = computed(() => parsedUpgradeTokenId())
const mebtcSharePercent = ref<number>(0)

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
  return formatUnits(bn(v), props.payTokenDecimals)
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

const powerCosts = computed(() => (selectedModel.value?.powerStepCost ?? []).map(bn))
const hashCosts = computed(() => (selectedModel.value?.hashStepCost ?? []).map(bn))

function parsedUpgradeTokenId(): bigint | null {
  try {
    if (!upgradeTokenId.value) return null
    return BigInt(upgradeTokenId.value)
  } catch {
    return null
  }
}

const mebtcShareBps = computed(() => {
  const p = Math.max(0, Math.min(30, Math.floor(mebtcSharePercent.value || 0)))
  return p * 100
})

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

  return `next cost:P ${powerText} ${props.payTokenSymbol} |H ${hashText} ${props.payTokenSymbol}`
})

const upgradePowerCost = computed(() => {
  if (upgradeState.value.status !== 'ok') return 0n
  const st = upgradeState.value
  const model = modelById.value.get(st.modelId)
  if (!model) return 0n
  const idx = st.powerActiveSteps + st.powerPendingSteps
  const cost = model.powerStepCost?.[idx]
  return typeof cost === 'bigint' ? cost : 0n
})

const upgradeHashCost = computed(() => {
  if (upgradeState.value.status !== 'ok') return 0n
  const st = upgradeState.value
  const model = modelById.value.get(st.modelId)
  if (!model) return 0n
  const idx = st.hashActiveSteps + st.hashPendingSteps
  const cost = model.hashStepCost?.[idx]
  return typeof cost === 'bigint' ? cost : 0n
})

const upgradePayTokenPart = computed(() => {
  const cost = upgradePowerCost.value + upgradeHashCost.value
  if (cost <= 0n) return 0n
  const share = BigInt(mebtcShareBps.value)
  const mebtcUsdc = (cost * share) / 10_000n
  return cost - mebtcUsdc
})

const upgradeMebtcPartEstimate = computed(() => {
  const cost = upgradePowerCost.value + upgradeHashCost.value
  if (cost <= 0n) return 0n
  const share = BigInt(mebtcShareBps.value)
  const mebtcUsdc = (cost * share) / 10_000n
  if (props.mebtcPriceUsdc <= 0n) return 0n
  return (mebtcUsdc * 10n ** BigInt(props.mebtcDecimals)) / props.mebtcPriceUsdc
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
  <Card title="Miner pricing / Buy & Upgrade (Read-only)">
    <div v-if="loading">loading models…</div>
    <div v-else-if="modelErr">error loading models: {{ modelErr }}</div>

    <div v-else>
      <div class="ui-row">
        <label>
          model:
          <select v-model.number="selectedModelId" class="ui-select">
            <option v-for="m in models" :key="m.modelId" :value="m.modelId">
              {{ m.modelId }} ({{ m.finalized ? 'live' : 'not live' }})
            </option>
          </select>
        </label>

        <label>
          qty:
          <input v-model.number="qty" type="number" min="1" class="ui-input" style="width:80px;" />
        </label>

        <div class="ui-muted">
          price:
          <b>{{ fmt(neededForBuy) }} {{ payTokenSymbol }}</b>
        </div>
      </div>
      <div v-if="missingForBuy > 0n" class="ui-muted" style="margin-top:6px;">
        allowance fehlt: {{ fmt(missingForBuy) }} {{ payTokenSymbol }}
      </div>

      <div v-if="selectedModel" class="ui-muted" style="margin-top:10px;">
        <div>
          hashrate: {{ selectedModel.baseHashrate }} | power: {{ selectedModel.basePowerWatt }}W
        </div>
        <div>
          supply: {{ selectedModel.minted }} / {{ selectedModel.maxSupply }}
        </div>

        <div style="margin-top:8px;">
          <div>
            <b>power step costs ({{ payTokenSymbol }}):</b>
            {{ powerCosts.map(x => fmt(x)).join(' | ') }}
          </div>
          <div>
            <b>hash step costs ({{ payTokenSymbol }}):</b>
            {{ hashCosts.map(x => fmt(x)).join(' | ') }}
          </div>
        </div>
      </div>

      <div class="ui-section ui-stack-sm">
        <div class="ui-subtitle">Schritt 1: Allowance (Buy)</div>
        <div class="ui-row">
          <span class="ui-muted">PayToken:</span>
          <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
            {{ payTokenAddress }}
          </span>
          <Button size="sm" :disabled="!payTokenAddress" @click="openExplorer(payTokenAddress)">Open</Button>
          <Button size="sm" :disabled="!payTokenAddress" @click="copyText('PayToken', payTokenAddress)">Copy</Button>
        </div>
        <div class="ui-row">
          <span class="ui-muted">Spender (MinerNFT):</span>
          <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
            {{ minerNftAddress }}
          </span>
          <Button size="sm" :disabled="!minerNftAddress" @click="copyText('Spender', minerNftAddress)">Copy</Button>
        </div>
        <div class="ui-row">
          <span class="ui-muted">Amount (raw):</span>
          <span class="ui-muted">{{ neededForBuy }}</span>
          <Button size="sm" @click="copyText('Amount', String(neededForBuy))">Copy</Button>
        </div>
      </div>

      <div class="ui-section ui-stack-sm">
        <div class="ui-subtitle">Schritt 2: Buy im Explorer</div>
        <div class="ui-row">
          <span class="ui-muted">Funktion:</span>
          <span class="ui-muted">buyFromModel(uint16 modelId, uint256 quantity)</span>
          <Button size="sm" @click="copyText('Funktion', 'buyFromModel(uint16 modelId, uint256 quantity)')">Copy</Button>
        </div>
        <div class="ui-row">
          <span class="ui-muted">modelId:</span>
          <span class="ui-muted">{{ selectedModelId }}</span>
          <Button size="sm" @click="copyText('modelId', String(selectedModelId))">Copy</Button>
        </div>
        <div class="ui-row">
          <span class="ui-muted">quantity:</span>
          <span class="ui-muted">{{ Math.max(1, qty || 1) }}</span>
          <Button size="sm" @click="copyText('quantity', String(Math.max(1, qty || 1)))">Copy</Button>
        </div>
        <div class="ui-row">
          <Button size="sm" :disabled="!minerNftAddress" @click="openExplorer(minerNftAddress)">MinerNFT im Explorer öffnen</Button>
        </div>
      </div>

      <div class="ui-section">
        <div class="ui-row ui-subtitle">
          <span>Upgrade miner</span>
          <span class="ui-muted" style="font-size:11px;">
            (upgrades erst nach erfolgtem claim aktiv)
          </span>
        </div>
        <div class="ui-row">
          <input
            v-model="upgradeTokenId"
            type="text"
            placeholder="tokenId"
            class="ui-input"
            style="width:120px;"
          />
          <label class="ui-muted" style="font-size:12px;">
            MeBTC Anteil:
            <select v-model.number="mebtcSharePercent" class="ui-select" style="width:90px;">
              <option :value="0">0%</option>
              <option :value="10">10%</option>
              <option :value="20">20%</option>
              <option :value="30">30%</option>
            </select>
          </label>
        </div>
        <div class="ui-row" style="margin-top:6px;">
          <span class="ui-muted">mebtcShareBps: {{ mebtcShareBps }}</span>
        </div>
        <div v-if="upgradeTokenId" class="ui-muted" style="margin-top:6px;font-size:12px;">
          <span v-if="upgradeState.status === 'loading'">loading upgrade status…</span>
          <span v-else-if="upgradeState.status === 'error'">upgrade status error: {{ upgradeState.error }}</span>
          <span v-else-if="upgradeState.status === 'ok'">
            model: {{ upgradeState.modelId }} | {{ upgradeStepsText }}
          </span>
        </div>
        <div v-if="upgradeState.status === 'ok' && upgradeNextCostText" class="ui-muted" style="margin-top:4px;font-size:12px;">
          {{ upgradeNextCostText }}
        </div>
        <div v-if="owned.length" class="ui-muted" style="margin-top:6px;font-size:12px;">
          owned tokenIds: {{ owned.map(x => x.toString()).join(', ') }}
        </div>

        <div class="ui-section ui-stack-sm">
          <div class="ui-subtitle">Schritt 1: Allowance (Upgrade)</div>
          <div class="ui-row">
            <span class="ui-muted">PayToken Anteil (raw):</span>
            <span class="ui-muted">{{ upgradePayTokenPart }}</span>
            <Button size="sm" @click="copyText('PayToken Anteil', String(upgradePayTokenPart))">Copy</Button>
          </div>
          <div class="ui-row">
            <span class="ui-muted">MeBTC Anteil (estimate, raw):</span>
            <span class="ui-muted">{{ upgradeMebtcPartEstimate }}</span>
            <Button size="sm" @click="copyText('MeBTC Anteil', String(upgradeMebtcPartEstimate))">Copy</Button>
          </div>
          <div class="ui-muted" style="font-size:12px;">
            Hinweis: MeBTC-Anteil ist eine Schaetzung basierend auf dem aktuellen Preis.
          </div>
        </div>

        <div class="ui-section ui-stack-sm">
          <div class="ui-subtitle">Schritt 2: Upgrade im Explorer</div>
          <div class="ui-row">
            <span class="ui-muted">Power (ohne MeBTC):</span>
            <span class="ui-muted">requestUpgradePower(uint256 tokenId)</span>
          </div>
          <div class="ui-row">
            <span class="ui-muted">Power (mit MeBTC):</span>
            <span class="ui-muted">requestUpgradePowerWithMebtc(uint256 tokenId, uint16 mebtcShareBps)</span>
          </div>
          <div class="ui-row">
            <span class="ui-muted">Hash (ohne MeBTC):</span>
            <span class="ui-muted">requestUpgradeHash(uint256 tokenId)</span>
          </div>
          <div class="ui-row">
            <span class="ui-muted">Hash (mit MeBTC):</span>
            <span class="ui-muted">requestUpgradeHashWithMebtc(uint256 tokenId, uint16 mebtcShareBps)</span>
          </div>
          <div class="ui-row">
            <span class="ui-muted">tokenId:</span>
            <span class="ui-muted">{{ parsedUpgradeTokenId() ?? '-' }}</span>
            <Button size="sm" :disabled="!parsedUpgradeTokenId()" @click="copyText('tokenId', String(parsedUpgradeTokenId()))">Copy</Button>
          </div>
          <div class="ui-row">
            <span class="ui-muted">mebtcShareBps:</span>
            <span class="ui-muted">{{ mebtcShareBps }}</span>
            <Button size="sm" @click="copyText('mebtcShareBps', String(mebtcShareBps))">Copy</Button>
          </div>
          <div class="ui-row">
            <Button size="sm" :disabled="!minerNftAddress" @click="openExplorer(minerNftAddress)">MinerNFT im Explorer öffnen</Button>
          </div>
        </div>
      </div>

      <div v-if="copyNote" class="ui-muted" style="margin-top:8px;">{{ copyNote }}</div>
    </div>
  </Card>
</template>
