import { ref, watchEffect } from 'vue'
import { Contract } from 'ethers'
import { ADDRESSES, TOKENS } from '../contracts/addresses'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'

const ERC20_ABI = [
  'function balanceOf(address) view returns (uint256)'
]

export function useBalances() {
  const { address, readProvider } = useWallet()
  const { refreshKey } = useGlobalRefresh()

  const mebtc = ref<bigint>(0n)
  const usdc = ref<bigint>(0n)
  const loading = ref(false)

  const mebtcDecimals = TOKENS.mebtc.decimals
  const usdcDecimals = TOKENS.usdc.decimals

  watchEffect(async () => {
    refreshKey.value
    const a = address.value
    if (!a) {
      mebtc.value = 0n
      usdc.value = 0n
      return
    }

    loading.value = true
    try {
      const p = readProvider.value

      const mebtcC = new Contract(ADDRESSES.mebtc, ERC20_ABI, p)
      const usdcC = new Contract(ADDRESSES.usdc, ERC20_ABI, p)

      mebtc.value = (await mebtcC.balanceOf(a)) as bigint
      usdc.value = (await usdcC.balanceOf(a)) as bigint
    } finally {
      loading.value = false
    }
  })

  return { mebtc, usdc, loading, mebtcDecimals, usdcDecimals }
}

