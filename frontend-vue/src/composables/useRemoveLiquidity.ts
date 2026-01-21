import { ref } from 'vue'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'
import { removeLiquidity } from '../services/removeLiquidity'

export function useRemoveLiquidity() {
  const w = useWallet()
  const { triggerRefresh } = useGlobalRefresh()

  const busy = ref(false)
  const error = ref('')
  const lastTx = ref('')

  async function submit(lpAmount: string) {
    error.value = ''
    lastTx.value = ''

    if (!w.isConnected.value) throw new Error('wallet nicht verbunden')
    if (!w.onChain.value) throw new Error('falsches netzwerk (bitte avalanche fuji)')
    if (!w.hasWalletProvider.value) throw new Error('wallet provider fehlt')

    busy.value = true
    try {
      const provider = w.readProvider.value
      const signer = await w.getSigner()
      const res = await removeLiquidity({ provider, signer, lpAmount })
      lastTx.value = res.txHash
      triggerRefresh('remove-liquidity')
    } catch (e: any) {
      error.value = e?.shortMessage ?? e?.message ?? String(e)
      throw e
    } finally {
      busy.value = false
    }
  }

  return { busy, error, lastTx, submit }
}
