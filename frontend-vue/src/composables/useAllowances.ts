import { ref, watchEffect } from 'vue'
import { Contract, formatUnits } from 'ethers'
import { ADDRESSES, TOKENS } from '../contracts/addresses'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'
import { fetchPayTokenAddress } from '../services/payToken'
import { usePayToken } from './usePayToken'

const ERC20_ABI = [
  'function allowance(address owner, address spender) view returns (uint256)'
]

export function useAllowances() {
  const { address, readProvider } = useWallet()
  const { refreshKey } = useGlobalRefresh()

  const loading = ref(false)
  const allowanceMiner = ref<bigint>(0n)
  const allowanceManager = ref<bigint>(0n)
  const { decimals: payTokenDecimals } = usePayToken()

  watchEffect(async () => {
    refreshKey.value
    const a = address.value
    if (!a) {
      allowanceMiner.value = 0n
      allowanceManager.value = 0n
      return
    }

    loading.value = true
    try {
      const p = readProvider.value
      const token = await fetchPayTokenAddress(p)
      const payToken = new Contract(token, ERC20_ABI, p)

      allowanceMiner.value = (await payToken.allowance(a, ADDRESSES.minerNft)) as bigint
      allowanceManager.value = (await payToken.allowance(a, ADDRESSES.miningManager)) as bigint
    } finally {
      loading.value = false
    }
  })

  function fmt(v: bigint) {
    const isMax = v > (2n ** 255n)
    return isMax ? 'max' : formatUnits(v, payTokenDecimals.value ?? TOKENS.usdc.decimals)
  }

  function allowanceMinerText() {
    return fmt(allowanceMiner.value)
  }

  function allowanceManagerText() {
    return fmt(allowanceManager.value)
  }

  return {
    loading,
    allowanceMiner,
    allowanceManager,
    allowanceMinerText,
    allowanceManagerText
  }
}
