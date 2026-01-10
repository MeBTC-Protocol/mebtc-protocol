import { ref } from 'vue'
import { Contract } from 'ethers'
import { ADDRESSES } from '../contracts/addresses'
import { useWallet } from './useWallet'

const MINER_ACTION_ABI = [
  'function buyFromModel(uint16 modelId, uint256 quantity) returns (uint256)',
  'function requestUpgradePower(uint256 tokenId) returns (uint16)',
  'function requestUpgradeHash(uint256 tokenId) returns (uint16)'
]

export function useMinerActions() {
  const w = useWallet()

  const busy = ref(false)
  const error = ref('')
  const lastTx = ref('')

  async function withSigner<T>(fn: (miner: Contract) => Promise<T>): Promise<T> {
    error.value = ''
    lastTx.value = ''

    if (!w.isConnected.value) throw new Error('wallet nicht verbunden')
    if (!w.onChain.value) throw new Error('falsches netzwerk (bitte avalanche fuji)')

    busy.value = true
    try {
      const signer = await w.getSigner()
      const miner = new Contract(ADDRESSES.minerNft, MINER_ACTION_ABI, signer)
      const res = await fn(miner)
      return res
    } catch (e: any) {
      error.value = e?.shortMessage ?? e?.message ?? String(e)
      throw e
    } finally {
      busy.value = false
    }
  }

  async function buyFromModel(modelId: number, quantity: number) {
    const qty = Math.max(1, Math.floor(quantity))
    if (!Number.isFinite(modelId) || modelId <= 0) {
      throw new Error('ungueltige modelId')
    }
    await withSigner(async (miner) => {
      const tx = await miner.buyFromModel(modelId, qty)
      lastTx.value = tx.hash
      await tx.wait()
    })
  }

  async function requestUpgradePower(tokenId: bigint) {
    await withSigner(async (miner) => {
      const tx = await miner.requestUpgradePower(tokenId)
      lastTx.value = tx.hash
      await tx.wait()
    })
  }

  async function requestUpgradeHash(tokenId: bigint) {
    await withSigner(async (miner) => {
      const tx = await miner.requestUpgradeHash(tokenId)
      lastTx.value = tx.hash
      await tx.wait()
    })
  }

  return {
    busy,
    error,
    lastTx,
    buyFromModel,
    requestUpgradePower,
    requestUpgradeHash
  }
}
