import { ref } from 'vue'
import { Contract } from 'ethers'
import { ADDRESSES } from '../contracts/addresses'
import { useWallet } from './useWallet'
import { useMinerStatsRefresh } from './useMinerStatsRefresh'
import { useGlobalRefresh } from './useGlobalRefresh'

const MINER_ACTION_ABI = [
  'function buyFromModel(uint16 modelId, uint256 quantity) returns (uint256)',
  'function requestUpgradePower(uint256 tokenId) returns (uint16)',
  'function requestUpgradeHash(uint256 tokenId) returns (uint16)',
  'function requestUpgradePowerWithMebtc(uint256 tokenId, uint16 mebtcShareBps) returns (uint16)',
  'function requestUpgradeHashWithMebtc(uint256 tokenId, uint16 mebtcShareBps) returns (uint16)'
]

export function useMinerActions() {
  const w = useWallet()
  const { triggerRefresh } = useMinerStatsRefresh()
  const { triggerRefresh: triggerGlobalRefresh } = useGlobalRefresh()

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
      triggerGlobalRefresh('buy-miner', { rescanOwned: true })
    })
  }

  async function requestUpgradePower(tokenId: bigint, mebtcShareBps = 0) {
    await withSigner(async (miner) => {
      const tx = mebtcShareBps > 0
        ? await miner.requestUpgradePowerWithMebtc(tokenId, mebtcShareBps)
        : await miner.requestUpgradePower(tokenId)
      lastTx.value = tx.hash
      await tx.wait()
      triggerRefresh()
      triggerGlobalRefresh('upgrade-power')
    })
  }

  async function requestUpgradeHash(tokenId: bigint, mebtcShareBps = 0) {
    await withSigner(async (miner) => {
      const tx = mebtcShareBps > 0
        ? await miner.requestUpgradeHashWithMebtc(tokenId, mebtcShareBps)
        : await miner.requestUpgradeHash(tokenId)
      lastTx.value = tx.hash
      await tx.wait()
      triggerRefresh()
      triggerGlobalRefresh('upgrade-hash')
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
