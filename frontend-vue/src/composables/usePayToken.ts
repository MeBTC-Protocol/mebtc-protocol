import { ref, watchEffect } from 'vue'
import { useWallet } from './useWallet'
import { fetchPayTokenMeta } from '../services/payToken'
import { ADDRESSES, TOKENS } from '../contracts/addresses'

export function usePayToken() {
  const { readProvider } = useWallet()
  let requestId = 0

  const address = ref<string>(ADDRESSES.usdc)
  const symbol = ref<string>(TOKENS.usdc.symbol)
  const decimals = ref<number>(TOKENS.usdc.decimals)
  const loading = ref<boolean>(false)
  const error = ref<string>('')

  watchEffect(async () => {
    const rid = ++requestId
    loading.value = true
    if (rid === requestId) {
      error.value = ''
    }
    try {
      const meta = await fetchPayTokenMeta(readProvider.value)
      if (rid !== requestId) return
      address.value = meta.address
      symbol.value = meta.symbol
      decimals.value = meta.decimals
    } catch (e: any) {
      if (rid === requestId) {
        error.value = e?.message ?? String(e)
      }
    } finally {
      if (rid === requestId) {
        loading.value = false
      }
    }
  })

  return { address, symbol, decimals, loading, error }
}
