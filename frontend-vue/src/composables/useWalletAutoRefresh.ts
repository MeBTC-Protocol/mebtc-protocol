import { watch } from 'vue'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'

export function useWalletAutoRefresh() {
  const w = useWallet()
  const { triggerRefresh } = useGlobalRefresh()

  watch(
    [() => w.isConnected.value, () => w.address.value, () => w.chainId.value, () => w.onChain.value],
    () => {
      triggerRefresh('wallet-change', { rescanOwned: true })
    },
    { immediate: true }
  )
}
