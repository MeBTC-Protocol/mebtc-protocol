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

  const mebtc = ref<bigint>(0n)
  const payToken = ref<bigint>(0n)
  const loading = ref(false)

  const mebtcDecimals = TOKENS.mebtc.decimals
  const { symbol: payTokenSymbol, decimals: payTokenDecimals, address: payTokenAddress } = usePayToken()

  watchEffect(async () => {
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

      const mebtcC = new Contract(ADDRESSES.mebtc, ERC20_ABI, p)
      const token = payTokenAddress.value || (await fetchPayTokenAddress(p))
      const payTokenC = new Contract(token, ERC20_ABI, p)

      mebtc.value = (await mebtcC.balanceOf(a)) as bigint
      payToken.value = (await payTokenC.balanceOf(a)) as bigint
    } finally {
      loading.value = false
    }
  })

  return { mebtc, payToken, loading, mebtcDecimals, payTokenDecimals, payTokenSymbol }
}
