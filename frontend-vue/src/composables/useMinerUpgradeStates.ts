import { ref, watchEffect } from 'vue'
import { Contract } from 'ethers'
import { useWallet } from './useWallet'
import { ADDRESSES } from '../contracts/addresses'

const MINER_STATE_ABI = [
  'function getMinerState(uint256 tokenId) view returns (uint16,uint16,uint16,uint16,uint16,uint40,uint40)'
]

const POWER_STEP_BPS = 500
const HASH_STEP_BPS = 250
const MAX_STEPS = 4

export type MinerUpgradeState =
  | { status: 'idle' }
  | { status: 'loading' }
  | {
      status: 'ok'
      modelId: number
      powerActiveSteps: number
      powerPendingSteps: number
      hashActiveSteps: number
      hashPendingSteps: number
      maxSteps: number
    }
  | { status: 'error'; error: string }

export function useMinerUpgradeStates(getTokenIds: () => bigint[]) {
  const { readProvider } = useWallet()
  const states = ref<Record<string, MinerUpgradeState>>({})

  watchEffect(async () => {
    const ids = getTokenIds() || []
    if (ids.length === 0) return

    const miner = new Contract(ADDRESSES.minerNft, MINER_STATE_ABI, readProvider.value)

    await Promise.all(
      ids.map(async (id) => {
        const key = id.toString()

        if (states.value[key]?.status === 'ok') return
        if (states.value[key]?.status === 'loading') return

        states.value = { ...states.value, [key]: { status: 'loading' } }

        try {
          const res = await miner.getMinerState(id)
          const modelId = Number(res[0])
          const powerUpgradeBps = Number(res[1])
          const hashUpgradeBps = Number(res[2])
          const pendingPowerUpgradeBps = Number(res[3])
          const pendingHashUpgradeBps = Number(res[4])

          states.value = {
            ...states.value,
            [key]: {
              status: 'ok',
              modelId,
              powerActiveSteps: Math.floor(powerUpgradeBps / POWER_STEP_BPS),
              powerPendingSteps: Math.floor(pendingPowerUpgradeBps / POWER_STEP_BPS),
              hashActiveSteps: Math.floor(hashUpgradeBps / HASH_STEP_BPS),
              hashPendingSteps: Math.floor(pendingHashUpgradeBps / HASH_STEP_BPS),
              maxSteps: MAX_STEPS
            }
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
