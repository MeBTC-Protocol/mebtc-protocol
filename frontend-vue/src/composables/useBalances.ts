import { ref, watchEffect } from 'vue'
import { Contract } from 'ethers'
import { ADDRESSES, TOKENS } from '../contracts/addresses'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'
import { fetchPayTokenAddress } from '../services/payToken'
import { usePayToken } from './usePayToken'

const ERC20_ABI = [
  'function balanceOf(address) view returns (uint256)'
]

export function useBalances() {
  const { address, readProvider } = useWallet()
  const { refreshKey } = useGlobalRefresh()
  let requestId = 0

  const mebtc = ref<bigint>(0n)
  const payToken = ref<bigint>(0n)
  const loading = ref(false)

  const mebtcDecimals = TOKENS.mebtc.decimals
  const { symbol: payTokenSymbol, decimals: payTokenDecimals, address: payTokenAddress } = usePayToken()

  watchEffect(async () => {
    const rid = ++requestId
    refreshKey.value
    const a = address.value
    if (!a) {
      mebtc.value = 0n
      payToken.value = 0n
      return
    }

    loading.value = true
    try {
      const p = readProvider.value

      const mebtcC = new Contract(ADDRESSES.mebtc, ERC20_ABI, p) as any
      const token = payTokenAddress.value || (await fetchPayTokenAddress(p))
      const payTokenC = new Contract(token, ERC20_ABI, p) as any

      const [mebtcRes, payRes] = await Promise.all([
        mebtcC.balanceOf(a),
        payTokenC.balanceOf(a)
      ])
      if (rid !== requestId) return
      mebtc.value = mebtcRes as bigint
      payToken.value = payRes as bigint
    } finally {
      if (rid === requestId) {
        loading.value = false
      }
    }
  })

  return { mebtc, payToken, loading, mebtcDecimals, payTokenDecimals, payTokenSymbol }
}
