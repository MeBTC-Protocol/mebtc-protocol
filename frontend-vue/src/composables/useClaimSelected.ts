import { computed, ref, watch } from 'vue'
import { useWallet } from './useWallet'
import { claimMinerQueued } from '../services/minerClaimService'
import { useGlobalRefresh } from './useGlobalRefresh'
import { emitClaimAttempt, emitClaimFailure, emitClaimSuccess } from '../monitoring/runtimeTelemetry'

const MAX_CLAIM_IDS_PER_TX = 100

export type ClaimQueueStatus = {
  running: boolean
  total: number
  processed: number
  currentBatchSize: number
  remaining: number
  note: string
}

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
  const claimQueueStatus = ref<ClaimQueueStatus>({
    running: false,
    total: 0,
    processed: 0,
    currentBatchSize: 0,
    remaining: 0,
    note: ''
  })

  function syncSelection(ids: bigint[]) {
    const next: Record<string, boolean> = {}
    for (const id of ids) {
      const k = id.toString()
      next[k] = selected.value[k] ?? true
    }
    selected.value = next
  }

  watch(
    () => params.owned().map(id => id.toString()),
    () => {
      syncSelection(params.owned())
    },
    { immediate: true }
  )

  const selectedIds = computed(() => {
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

  async function claim(mebtcShareBps = 0) {
    error.value = ''
    lastTx.value = ''
    lastApproveTx.value = ''
    claimQueueStatus.value = {
      running: false,
      total: 0,
      processed: 0,
      currentBatchSize: 0,
      remaining: 0,
      note: ''
    }

    if (!w.isConnected.value) return error.value = 'wallet nicht verbunden'
    if (!w.onChain.value) return error.value = 'falsches netzwerk'
    if (!w.address.value) return error.value = 'keine adresse'
    const claimIds = selectedIds.value.slice()
    if (!claimIds.length) return error.value = 'keine tokenIds ausgewaehlt'

    const missing = claimIds.filter(id => !params.previewMap().has(id.toString()))
    if (missing.length > 0) {
      error.value = `previews fehlen für: ${missing.join(', ')}`
      return
    }

    let totalFeeForClaim = 0n
    for (const id of claimIds) {
      const preview = params.previewMap().get(id.toString())
      if (preview) totalFeeForClaim += preview.fee
    }

    if (!w.hasWalletProvider.value) {
      error.value = "wallet provider fehlt. wallet neu verbinden (disconnect/connect) oder seite reload."
      return
    }

    const provider = w.readProvider.value
    const signer = await w.getSigner()
    const mode = mebtcShareBps > 0 ? 'mixed' as const : 'usdc' as const
    emitClaimAttempt({
      mode,
      tokenCount: claimIds.length,
      mebtcShareBps
    })

    busy.value = true
    try {
      const res = await claimMinerQueued({
        provider,
        signer,
        owner: w.address.value,
        tokenIds: claimIds,
        totalFeeNeeded: totalFeeForClaim,
        mebtcShareBps,
        maxBatchSize: MAX_CLAIM_IDS_PER_TX,
        onProgress: (progress) => {
          claimQueueStatus.value = {
            running: progress.processed < progress.total,
            total: progress.total,
            processed: progress.processed,
            currentBatchSize: progress.currentBatchSize,
            remaining: progress.remaining,
            note: progress.note ?? ''
          }
        }
      })
      lastApproveTx.value = res.approveTxHash ?? ''
      lastTx.value = res.claimTxHashes[res.claimTxHashes.length - 1] ?? ''
      claimQueueStatus.value = {
        ...claimQueueStatus.value,
        running: false,
        processed: claimIds.length,
        remaining: 0
      }
      emitClaimSuccess({
        mode,
        tokenCount: claimIds.length,
        mebtcShareBps
      })
      triggerRefresh('claim-miner', { rescanOwned: true })
    } catch (e: any) {
      error.value = e?.shortMessage ?? e?.message ?? String(e)
      emitClaimFailure({
        mode,
        tokenCount: claimIds.length,
        mebtcShareBps,
        rawError: e
      })
      claimQueueStatus.value = {
        ...claimQueueStatus.value,
        running: false
      }
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
    maxIdsPerTx: MAX_CLAIM_IDS_PER_TX,
    claimQueueStatus,
    claim
  }
}
