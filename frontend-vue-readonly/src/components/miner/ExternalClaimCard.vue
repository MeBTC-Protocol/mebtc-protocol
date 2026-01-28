<script setup lang="ts">
import { computed, ref } from 'vue'
import { formatUnits } from 'ethers'
import Card from '../common/Card.vue'
import Button from '../common/Button.vue'
import { TOKENS } from '../../contracts/addresses'

const props = defineProps<{
  disabled: boolean
  owned: bigint[]
  previewMap: Map<string, { reward: bigint; fee: bigint }>
  selected: Record<string, boolean>
  totalFeeSelected: bigint
  payTokenSymbol: string
  payTokenDecimals: number
  payTokenAddress: string
  miningManagerAddress: string
  blockExplorerBase: string
  allowanceManagerText: string
  setSelected: (next: Record<string, boolean>) => void
}>()

const mebtcSharePercent = ref<number>(0)
const mebtcShareBps = computed(() => {
  const p = Math.max(0, Math.min(30, Math.floor(mebtcSharePercent.value || 0)))
  return p * 100
})

const selectedIds = computed(() => {
  return (props.owned || []).filter(id => props.selected[id.toString()])
})

const selectedIdsText = computed(() => {
  if (!selectedIds.value.length) return '[]'
  return `[${selectedIds.value.map(id => id.toString()).join(', ')}]`
})

const totalFeeText = computed(() => {
  return formatUnits(props.totalFeeSelected ?? 0n, props.payTokenDecimals)
})

const feeTokenNeeded = computed(() => {
  const total = props.totalFeeSelected ?? 0n
  if (total <= 0n) return 0n
  const share = BigInt(mebtcShareBps.value)
  const discount = (total * share) / 10_000n
  const needed = total - discount
  return needed >= 0n ? needed : 0n
})

const feeTokenNeededText = computed(() => {
  return formatUnits(feeTokenNeeded.value, props.payTokenDecimals)
})

const claimSignature = computed(() => {
  return mebtcShareBps.value > 0
    ? 'claimWithMebtc(uint256[] tokenIds, uint16 mebtcShareBps)'
    : 'claim(uint256[] tokenIds)'
})

const claimParamsText = computed(() => {
  return mebtcShareBps.value > 0
    ? `${selectedIdsText.value}, ${mebtcShareBps.value}`
    : selectedIdsText.value
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
    if (!navigator?.clipboard?.writeText) {
      throw new Error('clipboard not available')
    }
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

function toggle(id: bigint, checked: boolean) {
  const key = id.toString()
  props.setSelected({ ...props.selected, [key]: checked })
}
</script>

<template>
  <Card title="Claim extern (Read-only)">
    <div class="ui-stack">
      <div class="ui-stack-sm">
        <div class="ui-subtitle">Schritt 1: Auswahl</div>
        <div class="ui-muted">
          Waehle Token IDs fuer den Claim. Diese Liste wird fuer den externen Claim genutzt.
        </div>
        <div class="ui-row">
          <span class="ui-muted">tokenIds:</span>
          <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
            {{ selectedIdsText }}
          </span>
          <Button size="sm" :disabled="disabled || selectedIds.length === 0" @click="copyText('tokenIds', selectedIdsText)">
            Copy
          </Button>
        </div>
        <div class="ui-muted">
          total fee selected: {{ totalFeeText }} {{ payTokenSymbol }}
        </div>
      </div>

      <div class="ui-section ui-stack-sm">
        <div class="ui-subtitle">Schritt 2: Allowance (PayToken)</div>
        <div class="ui-muted">
          Falls die Allowance zu klein ist, im Explorer den PayToken fuer den MiningManager approven.
        </div>
        <div class="ui-row">
          <span class="ui-muted">PayToken:</span>
          <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
            {{ payTokenAddress || '-' }}
          </span>
          <Button size="sm" :disabled="!payTokenAddress" @click="openExplorer(payTokenAddress)">
            Open
          </Button>
          <Button size="sm" :disabled="!payTokenAddress" @click="copyText('PayToken', payTokenAddress)">
            Copy
          </Button>
        </div>
        <div class="ui-row">
          <span class="ui-muted">Spender (MiningManager):</span>
          <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
            {{ miningManagerAddress }}
          </span>
          <Button size="sm" :disabled="!miningManagerAddress" @click="copyText('Spender', miningManagerAddress)">
            Copy
          </Button>
        </div>
        <div class="ui-row">
          <span class="ui-muted">Amount (needed):</span>
          <span class="ui-muted">
            {{ feeTokenNeededText }} {{ payTokenSymbol }}
          </span>
          <Button size="sm" :disabled="feeTokenNeeded <= 0n" @click="copyText('Amount', feeTokenNeeded.toString())">
            Copy
          </Button>
        </div>
        <div class="ui-muted">
          aktuelle allowance: {{ allowanceManagerText }} {{ payTokenSymbol }}
        </div>
      </div>

      <div class="ui-section ui-stack-sm">
        <div class="ui-subtitle">Schritt 3: Claim im Explorer</div>
        <div class="ui-muted">
          MiningManager im Explorer oeffnen, Tab \"Write Contract\" waehlen und die Funktion ausfuehren.
        </div>
        <div class="ui-row">
          <span class="ui-muted">MiningManager:</span>
          <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
            {{ miningManagerAddress }}
          </span>
          <Button size="sm" :disabled="!miningManagerAddress" @click="openExplorer(miningManagerAddress)">
            Open
          </Button>
          <Button size="sm" :disabled="!miningManagerAddress" @click="copyText('MiningManager', miningManagerAddress)">
            Copy
          </Button>
        </div>
        <div class="ui-row">
          <label class="ui-muted" style="font-size:12px;">
            MeBTC Anteil:
            <select v-model.number="mebtcSharePercent" class="ui-select" style="width:90px;" :disabled="disabled">
              <option :value="0">0%</option>
              <option :value="10">10%</option>
              <option :value="20">20%</option>
              <option :value="30">30%</option>
            </select>
          </label>
          <div class="ui-muted">
            mebtcShareBps: {{ mebtcShareBps }}
          </div>
        </div>
        <div class="ui-row">
          <span class="ui-muted">Funktion:</span>
          <span class="ui-muted">{{ claimSignature }}</span>
          <Button size="sm" @click="copyText('Funktion', claimSignature)">
            Copy
          </Button>
        </div>
        <div class="ui-row">
          <span class="ui-muted">Parameter:</span>
          <span class="ui-muted" style="font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;">
            {{ claimParamsText }}
          </span>
          <Button size="sm" :disabled="selectedIds.length === 0" @click="copyText('Parameter', claimParamsText)">
            Copy
          </Button>
        </div>
      </div>

      <div class="ui-section">
        <table class="ui-table">
          <thead>
            <tr>
              <th>select</th>
              <th>tokenId</th>
              <th>reward</th>
              <th>fee</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="id in owned" :key="id.toString()">
              <td>
                <input
                  type="checkbox"
                  :checked="!!selected[id.toString()]"
                  :disabled="disabled"
                  @change="toggle(id, ($event.target as HTMLInputElement).checked)"
                />
              </td>
              <td>#{{ id.toString() }}</td>
              <td>
                <span v-if="previewMap.get(id.toString())">
                  {{ formatUnits(previewMap.get(id.toString())!.reward, TOKENS.mebtc.decimals) }}
                </span>
                <span v-else>-</span>
              </td>
              <td>
                <span v-if="previewMap.get(id.toString())">
                  {{ formatUnits(previewMap.get(id.toString())!.fee, payTokenDecimals) }}
                </span>
                <span v-else>-</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div v-if="copyNote" class="ui-muted">{{ copyNote }}</div>
    </div>
  </Card>
</template>
