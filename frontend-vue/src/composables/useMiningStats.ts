import { ref, computed, watchEffect } from 'vue'
import { Contract } from 'ethers'
import { ADDRESSES } from '../contracts/addresses'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'

const ME_BTC_ABI = [
  'function totalSupply() view returns (uint256)',
  'function balanceOf(address owner) view returns (uint256)'
]

const ERC20_ABI = [
  'function balanceOf(address owner) view returns (uint256)'
]

const MINER_NFT_ABI = [
  'function getMinerData(uint256 tokenId) view returns (uint256 effHash, uint256 effPowerWatt, uint256 createdAt)',
  'function nextTokenId() view returns (uint256)'
]

const PAIR_ABI = [
  'function token0() view returns (address)',
  'function token1() view returns (address)',
  'function getReserves() view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast)'
]

export function useMiningStats(firstMinerId: bigint = 1n) {
  const { readProvider } = useWallet()
  const { refreshKey } = useGlobalRefresh()

  const totalMined = ref<bigint>(0n)
  const soldMiners = ref<bigint>(0n)
  const firstMinerCreatedAt = ref<bigint | null>(null)
  const totalStaked = ref<bigint>(0n)
  const feeVaultMebtc = ref<bigint>(0n)
  const demandVaultUsdc = ref<bigint>(0n)
  const poolMebtc = ref<bigint>(0n)
  const poolUsdc = ref<bigint>(0n)
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

  const nextSlotInSeconds = computed<number | null>(() => {
    if (!firstMinerCreatedAt.value) return null
    const created = Number(firstMinerCreatedAt.value)
    if (!Number.isFinite(created) || created <= 0) return null
    const delta = nowTs.value - created
    if (delta < 0) return null
    const mod = delta % 600
    return mod === 0 ? 600 : 600 - mod
  })

  watchEffect(async () => {
    refreshKey.value
    loading.value = true
    error.value = ''

    try {
      const p = readProvider.value
      const mebtc = new Contract(ADDRESSES.mebtc, ME_BTC_ABI, p)
      const usdc = new Contract(ADDRESSES.usdc, ERC20_ABI, p)
      const miner = new Contract(ADDRESSES.minerNft, MINER_NFT_ABI, p)
      const pair = new Contract(ADDRESSES.pair, PAIR_ABI, p)

      const [supply, data, nextId, staked, feeMebtc, demandUsdc, token0, reserves] = await Promise.all([
        mebtc.totalSupply(),
        miner.getMinerData(firstMinerId),
        miner.nextTokenId(),
        mebtc.balanceOf(ADDRESSES.stakeVault),
        mebtc.balanceOf(ADDRESSES.feeVaultMeBTC),
        usdc.balanceOf(ADDRESSES.demandVault),
        pair.token0(),
        pair.getReserves()
      ])

      totalMined.value = supply as bigint
      firstMinerCreatedAt.value = (data?.[2] as bigint) ?? null
      const nextTokenId = (nextId as bigint) ?? 1n
      soldMiners.value = nextTokenId > 0n ? nextTokenId - 1n : 0n
      totalStaked.value = staked as bigint
      feeVaultMebtc.value = feeMebtc as bigint
      demandVaultUsdc.value = demandUsdc as bigint

      const r0 = reserves?.[0] as bigint
      const r1 = reserves?.[1] as bigint
      if (String(token0).toLowerCase() === ADDRESSES.usdc.toLowerCase()) {
        poolUsdc.value = r0
        poolMebtc.value = r1
      } else {
        poolUsdc.value = r1
        poolMebtc.value = r0
      }
    } catch (e: any) {
      error.value = e?.shortMessage ?? e?.message ?? String(e)
    } finally {
      loading.value = false
    }
  })

  return {
    totalMined,
    totalStaked,
    feeVaultMebtc,
    demandVaultUsdc,
    poolMebtc,
    poolUsdc,
    soldMiners,
    firstMinerCreatedAt,
    intervalsSinceFirst,
    nextSlotInSeconds,
    loading,
    error
  }
}
