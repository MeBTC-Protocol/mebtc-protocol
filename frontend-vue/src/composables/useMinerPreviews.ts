import { ref, watch, computed } from 'vue'
import { useWallet } from './useWallet'
import { fetchClaimPreview } from '../services/minerClaimService'

type PreviewEntry = { reward: bigint; fee: bigint }

export function useMinerPreviews(getOwned: () => bigint[]) {
  const w = useWallet()

  const previewMap = ref<Map<string, PreviewEntry>>(new Map())
  const busy = ref(false)
  const error = ref('')

  const ownedKeys = computed(() => getOwned().map(x => x.toString()))

  async function refresh() {
    error.value = ''

    const provider = w.readProvider.value
    const owner = w.address.value

    if (!w.isConnected.value || !w.onChain.value || !owner) {
      previewMap.value = new Map()
      return
    }

    const ids = getOwned()
    if (ids.length === 0) {
      previewMap.value = new Map()
      return
    }

    busy.value = true
    try {
      const next = new Map<string, PreviewEntry>()
      for (const id of ids) {
        const p = await fetchClaimPreview(provider, id, owner)
        next.set(id.toString(), { reward: p.rewardRaw, fee: p.feeUsdcRaw })
      }
      previewMap.value = next
    } catch (e: any) {
      error.value = e?.shortMessage ?? e?.message ?? String(e)
    } finally {
      busy.value = false
    }
  }

  watch([() => w.address.value, () => w.onChain.value, ownedKeys], refresh, { immediate: true })

  return { previewMap, busy, error, refresh }
}

