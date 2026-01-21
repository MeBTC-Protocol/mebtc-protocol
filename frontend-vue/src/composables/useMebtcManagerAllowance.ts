import { ref, watchEffect } from 'vue'
import { Contract, formatUnits } from 'ethers'
import { ADDRESSES, TOKENS } from '../contracts/addresses'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'

const ERC20_ABI = [
  'function allowance(address owner, address spender) view returns (uint256)'
]

export function useMebtcManagerAllowance() {
  const { address, readProvider } = useWallet()
  const { refreshKey } = useGlobalRefresh()
  let requestId = 0

  const loading = ref(false)
  const allowance = ref<bigint>(0n)

  watchEffect(async () => {
    const rid = ++requestId
    refreshKey.value
    const a = address.value
    if (!a) {
      allowance.value = 0n
      return
    }

    loading.value = true
    try {
      const p = readProvider.value
      const mebtc = new Contract(ADDRESSES.mebtc, ERC20_ABI, p)
      const res = await mebtc.allowance(a, ADDRESSES.miningManager)
      if (rid !== requestId) return
      allowance.value = res as bigint
    } finally {
      if (rid === requestId) {
        loading.value = false
      }
    }
  })

  function allowanceText() {
    const v = allowance.value
    const isMax = v > (2n ** 255n)
    return isMax ? 'max' : formatUnits(v, TOKENS.mebtc.decimals)
  }

  return { loading, allowance, allowanceText }
}
