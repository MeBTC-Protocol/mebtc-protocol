import { ref, watchEffect } from 'vue'
import { Contract, formatUnits } from 'ethers'
import { ADDRESSES, TOKENS } from '../contracts/addresses'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'

const ERC20_ABI = [
  'function allowance(address owner, address spender) view returns (uint256)'
]

export function useRouterAllowances() {
  const { address, readProvider } = useWallet()
  const { refreshKey } = useGlobalRefresh()
  let requestId = 0

  const loading = ref(false)
  const usdcAllowance = ref<bigint>(0n)
  const mebtcAllowance = ref<bigint>(0n)

  watchEffect(async () => {
    const rid = ++requestId
    refreshKey.value
    const a = address.value
    if (!a) {
      usdcAllowance.value = 0n
      mebtcAllowance.value = 0n
      return
    }

    loading.value = true
    try {
      const p = readProvider.value
      const usdc = new Contract(ADDRESSES.usdc, ERC20_ABI, p)
      const mebtc = new Contract(ADDRESSES.mebtc, ERC20_ABI, p)

      const [u, m] = await Promise.all([
        usdc.allowance(a, ADDRESSES.router),
        mebtc.allowance(a, ADDRESSES.router)
      ])
      if (rid !== requestId) return
      usdcAllowance.value = u as bigint
      mebtcAllowance.value = m as bigint
    } finally {
      if (rid === requestId) {
        loading.value = false
      }
    }
  })

  function fmt(v: bigint, decimals: number) {
    const isMax = v > (2n ** 255n)
    return isMax ? 'max' : formatUnits(v, decimals)
  }

  return {
    loading,
    usdcAllowance,
    mebtcAllowance,
    usdcAllowanceText: () => fmt(usdcAllowance.value, TOKENS.usdc.decimals),
    mebtcAllowanceText: () => fmt(mebtcAllowance.value, TOKENS.mebtc.decimals)
  }
}
