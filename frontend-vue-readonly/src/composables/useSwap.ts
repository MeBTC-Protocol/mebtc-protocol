import { ref } from 'vue'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'
import { swapExactTokens } from '../services/swapExact'

type Direction = 'buy' | 'sell'

export function useSwap() {
  const w = useWallet()
  const { triggerRefresh } = useGlobalRefresh()

  const busy = ref(false)
  const error = ref('')
  const lastTx = ref('')

  async function submit(params: { direction: Direction; amountIn: string; minOut?: string }) {
    error.value = ''
    lastTx.value = ''

    if (!w.isConnected.value) throw new Error('wallet nicht verbunden')
    if (!w.onChain.value) throw new Error('falsches netzwerk (bitte avalanche fuji)')
    if (!w.hasWalletProvider.value) throw new Error('wallet provider fehlt')

    busy.value = true
    try {
      const signer = await w.getSigner()
      const res = await swapExactTokens({
        signer,
        direction: params.direction,
        amountIn: params.amountIn,
        minOut: params.minOut
      })
      lastTx.value = res.txHash
      triggerRefresh('swap')
    } catch (e: any) {
      error.value = e?.shortMessage ?? e?.message ?? String(e)
      throw e
    } finally {
      busy.value = false
    }
  }

  return { busy, error, lastTx, submit }
}
