import { ref, watchEffect } from 'vue'
import { Contract } from 'ethers'
import { useWallet } from './useWallet'
import { ADDRESSES } from '../contracts/addresses'

const MINER_ABI = [
  'function nextModelId() view returns (uint16)',
  'function getModel(uint16 modelId) view returns (uint32,uint32,uint32,uint32,uint256,bool,uint256[4],uint256[4],string)'
]

export type MinerModel = {
  modelId: number
  baseHashrate: number
  basePowerWatt: number
  maxSupply: number
  minted: number
  priceUSDC: bigint
  finalized: boolean
  powerStepCost: bigint[]
  hashStepCost: bigint[]
  uri: string
}

export function useMinerModels() {
  const { readProvider } = useWallet()

  const loading = ref(false)
  const models = ref<MinerModel[]>([])
  const error = ref('')

  watchEffect(async () => {
    loading.value = true
    error.value = ''
    try {
      const p = readProvider.value
      const miner = new Contract(ADDRESSES.minerNft, MINER_ABI, p) as any

      const nextId = Number(await miner.nextModelId()) // nextModelId-1 ist letzter
      const out: MinerModel[] = []

      for (let id = 1; id < nextId; id++) {
        const r = await miner.getModel(id)

        // tuple unpack
        const baseHashrate = Number(r[0])
        const basePowerWatt = Number(r[1])
        const maxSupply = Number(r[2])
        const minted = Number(r[3])
        const priceUSDC = r[4] as bigint
        const finalized = Boolean(r[5])
        const powerStepCost = (r[6] as bigint[]).slice()
        const hashStepCost = (r[7] as bigint[]).slice()
        const uri = String(r[8])

        out.push({
          modelId: id,
          baseHashrate,
          basePowerWatt,
          maxSupply,
          minted,
          priceUSDC,
          finalized,
          powerStepCost,
          hashStepCost,
          uri
        })
      }

      models.value = out
    } catch (e: any) {
      error.value = e?.message ?? String(e)
      models.value = []
    } finally {
      loading.value = false
    }
  })

  return { loading, models, error }
}
