import { ref, watchEffect } from 'vue'
import { Contract, formatUnits } from 'ethers'
import { ADDRESSES, TOKENS } from '../contracts/addresses'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'

const ERC20_ABI = [
  'function allowance(address owner, address spender) view returns (uint256)'
]

export function useMebtcUpgradeAllowance() {
  const { address, readProvider, hasWalletProvider, browserProvider, onChain } = useWallet()
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
      const readAllowance = async (p: any) => {
        const mebtc = new Contract(ADDRESSES.mebtc, ERC20_ABI, p) as any
        const res = await mebtc.allowance(a, ADDRESSES.minerNft)
        if (rid !== requestId) return
        allowance.value = res as bigint
      }

      try {
        await readAllowance(readProvider.value)
      } catch {
        const bp = browserProvider.value
        if (hasWalletProvider.value && onChain.value && bp) {
          await readAllowance(bp)
        }
      }
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
