import { computed, ref } from 'vue'
import { useWallet } from './useWallet'
import { claimMinerBatch } from '../services/minerClaimService'
import { useGlobalRefresh } from './useGlobalRefresh'

export function useClaimSelected(params: {
  owned: () => bigint[]
  previewMap: () => Map<string, { reward: bigint; fee: bigint }>
}) {
  const w = useWallet()
  const { triggerRefresh } = useGlobalRefresh()

  const selected = ref<Record<string, boolean>>({})
  const busy = ref(false)
  const error = ref('')
  const lastTx = ref('')
  const lastApproveTx = ref('')

  function initSelection() {
    const next: Record<string, boolean> = {}
    for (const id of params.owned()) {
      const k = id.toString()
      next[k] = selected.value[k] ?? true
    }
    selected.value = next
  }

  const selectedIds = computed(() => {
    initSelection()
    return params.owned().filter(id => selected.value[id.toString()])
  })

  const totalFeeSelected = computed(() => {
    const m = params.previewMap()
    let sum = 0n
    for (const id of selectedIds.value) {
      const p = m.get(id.toString())
      if (p) sum += p.fee
    }
    return sum
  })

  async function claim() {
    error.value = ''
    lastTx.value = ''
    lastApproveTx.value = ''

    if (!w.isConnected.value) return error.value = 'wallet nicht verbunden'
    if (!w.onChain.value) return error.value = 'falsches netzwerk'
    if (!w.address.value) return error.value = 'keine adresse'

    const provider = w.readProvider.value
    const signer = await w.getSigner()

    const missing = selectedIds.value.filter(id => !params.previewMap().has(id.toString()))
    if (missing.length > 0) {
      error.value = `previews fehlen für: ${missing.join(', ')}`
      return
    }
    // ... nach owner-check und missing-preview-check:

    if (!w.hasWalletProvider.value) {
      error.value = "wallet provider fehlt. wallet neu verbinden (disconnect/connect) oder seite reload."
      return
    }

    busy.value = true
    try {
      const res = await claimMinerBatch({
        provider,
        signer,
        owner: w.address.value,
        tokenIds: selectedIds.value,
        totalFeeNeeded: totalFeeSelected.value
      })
      lastApproveTx.value = res.approveTxHash ?? ''
      lastTx.value = res.claimTxHash
      triggerRefresh('claim-miner', { rescanOwned: true })
    } catch (e: any) {
      error.value = e?.shortMessage ?? e?.message ?? String(e)
    } finally {
      busy.value = false
    }
  }

  return {
    selected,
    selectedIds,
    totalFeeSelected,
    busy,
    error,
    lastTx,
    lastApproveTx,
    claim
  }
}


