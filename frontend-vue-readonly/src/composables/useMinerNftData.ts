import { ref, watchEffect } from 'vue'
import { Contract } from 'ethers'
import { useWallet } from './useWallet'
import { ADDRESSES } from '../contracts/addresses'
import { useMinerStatsRefresh } from './useMinerStatsRefresh'

const MINER_NFT_ABI = [
  'function getMinerData(uint256 tokenId) view returns (uint256 effHash, uint256 effPowerWatt, uint256 createdAt)'
]

export type MinerDataState =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'ok'; effHash: bigint; effPowerWatt: bigint; createdAt: bigint }
  | { status: 'error'; error: string }

export function useMinerNftData(getTokenIds: () => bigint[]) {
  const { readProvider } = useWallet()
  const states = ref<Record<string, MinerDataState>>({})
  const { refreshKey } = useMinerStatsRefresh()
  const lastRefresh = ref(refreshKey.value)

  watchEffect(async () => {
    const ids = getTokenIds() || []
    if (ids.length === 0) return

    if (refreshKey.value !== lastRefresh.value) {
      lastRefresh.value = refreshKey.value
      const next = { ...states.value }
      for (const id of ids) {
        next[id.toString()] = { status: 'idle' }
      }
      states.value = next
    }

    const miner = new Contract(ADDRESSES.minerNft, MINER_NFT_ABI, readProvider.value)

    await Promise.all(
      ids.map(async (id) => {
        const key = id.toString()

        if (states.value[key]?.status === 'ok') return
        if (states.value[key]?.status === 'loading') return

        states.value = { ...states.value, [key]: { status: 'loading' } }

        try {
          const res = await miner.getMinerData(id)
          const effHash = res[0] as bigint
          const effPowerWatt = res[1] as bigint
          const createdAt = res[2] as bigint

          states.value = {
            ...states.value,
            [key]: { status: 'ok', effHash, effPowerWatt, createdAt }
          }
        } catch (e: any) {
          states.value = {
            ...states.value,
            [key]: { status: 'error', error: e?.message ?? String(e) }
          }
        }
      })
    )
  })

  return { states }
}
