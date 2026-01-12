import { ref, computed, watchEffect } from 'vue'
import { Contract } from 'ethers'
import { ADDRESSES } from '../contracts/addresses'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'

const ME_BTC_ABI = [
  'function totalSupply() view returns (uint256)'
]

const MINER_NFT_ABI = [
  'function getMinerData(uint256 tokenId) view returns (uint256 effHash, uint256 effPowerWatt, uint256 createdAt)',
  'function nextTokenId() view returns (uint256)'
]

export function useMiningStats(firstMinerId: bigint = 1n) {
  const { readProvider } = useWallet()
  const { refreshKey } = useGlobalRefresh()

  const totalMined = ref<bigint>(0n)
  const soldMiners = ref<bigint>(0n)
  const firstMinerCreatedAt = ref<bigint | null>(null)
  const loading = ref(false)
  const error = ref('')

  const nowTs = ref(Math.floor(Date.now() / 1000))

  watchEffect((onCleanup) => {
    const id = setInterval(() => {
      nowTs.value = Math.floor(Date.now() / 1000)
    }, 10_000)

    onCleanup(() => clearInterval(id))
  })

  const intervalsSinceFirst = computed<number | null>(() => {
    if (!firstMinerCreatedAt.value) return null
    const created = Number(firstMinerCreatedAt.value)
    if (!Number.isFinite(created) || created <= 0) return null
    const delta = nowTs.value - created
    if (delta < 0) return 0
    return Math.floor(delta / 600)
  })

  watchEffect(async () => {
    refreshKey.value
    loading.value = true
    error.value = ''

    try {
      const p = readProvider.value
      const mebtc = new Contract(ADDRESSES.mebtc, ME_BTC_ABI, p)
      const miner = new Contract(ADDRESSES.minerNft, MINER_NFT_ABI, p)

      const [supply, data, nextId] = await Promise.all([
        mebtc.totalSupply(),
        miner.getMinerData(firstMinerId),
        miner.nextTokenId()
      ])

      totalMined.value = supply as bigint
      firstMinerCreatedAt.value = (data?.[2] as bigint) ?? null
      const nextTokenId = (nextId as bigint) ?? 1n
      soldMiners.value = nextTokenId > 0n ? nextTokenId - 1n : 0n
    } catch (e: any) {
      error.value = e?.shortMessage ?? e?.message ?? String(e)
    } finally {
      loading.value = false
    }
  })

  return {
    totalMined,
    soldMiners,
    firstMinerCreatedAt,
    intervalsSinceFirst,
    loading,
    error
  }
}
