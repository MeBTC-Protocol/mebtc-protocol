import { ref, watchEffect } from 'vue'
import { Contract } from 'ethers'
import { ADDRESSES } from '../contracts/addresses'
import { stakeVaultAbi } from '../contracts/abi'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'

export function useStakeInfo() {
  const { address, readProvider } = useWallet()
  const { refreshKey } = useGlobalRefresh()
  let requestId = 0

  const loading = ref(false)
  const balance = ref<bigint>(0n)
  const tier = ref(0)
  const unlockAt = ref(0)
  const hashBonusBps = ref(0)
  const powerBonusBps = ref(0)

  watchEffect(async () => {
    const rid = ++requestId
    refreshKey.value
    const a = address.value
    if (!a) {
      balance.value = 0n
      tier.value = 0
      unlockAt.value = 0
      hashBonusBps.value = 0
      powerBonusBps.value = 0
      return
    }

    loading.value = true
    try {
      const p = readProvider.value
      const vault = new Contract(ADDRESSES.stakeVault, stakeVaultAbi, p) as any
      const res = await vault.getStakeInfo(a)
      if (rid !== requestId) return
      balance.value = res[0] as bigint
      tier.value = Number(res[1])
      unlockAt.value = Number(res[2])
      hashBonusBps.value = Number(res[3])
      powerBonusBps.value = Number(res[4])
    } finally {
      if (rid === requestId) {
        loading.value = false
      }
    }
  })

  return {
    loading,
    balance,
    tier,
    unlockAt,
    hashBonusBps,
    powerBonusBps
  }
}
