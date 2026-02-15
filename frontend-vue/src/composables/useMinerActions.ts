import { ref } from 'vue'
import { Contract } from 'ethers'
import { ADDRESSES } from '../contracts/addresses'
import { useWallet } from './useWallet'
import { useMinerStatsRefresh } from './useMinerStatsRefresh'
import { useGlobalRefresh } from './useGlobalRefresh'

const MAX_UPGRADE_BATCH_IDS_PER_TX = 100
const MAX_BUY_QTY_PER_TX = 50

export type MinerQueueStatus = {
  running: boolean
  total: number
  processed: number
  currentBatchSize: number
  remaining: number
  note: string
}

const MINER_ACTION_ABI = [
  'function buyFromModel(uint16 modelId, uint256 quantity) returns (uint256)',
  'function requestUpgradePower(uint256 tokenId) returns (uint16)',
  'function requestUpgradeHash(uint256 tokenId) returns (uint16)',
  'function requestUpgradePowerWithMebtc(uint256 tokenId, uint16 mebtcShareBps) returns (uint16)',
  'function requestUpgradeHashWithMebtc(uint256 tokenId, uint16 mebtcShareBps) returns (uint16)',
  'function requestUpgradePowerBatch(uint256[] tokenIds) returns (uint16[])',
  'function requestUpgradeHashBatch(uint256[] tokenIds) returns (uint16[])',
  'function requestUpgradePowerBatchWithMebtc(uint256[] tokenIds, uint16 mebtcShareBps) returns (uint16[])',
  'function requestUpgradeHashBatchWithMebtc(uint256[] tokenIds, uint16 mebtcShareBps) returns (uint16[])'
]

function errorText(err: any): string {
  const parts = [
    err?.shortMessage,
    err?.message,
    err?.reason,
    err?.code,
    err?.cause?.shortMessage,
    err?.cause?.message
  ]
  return parts.filter(Boolean).join(' | ').toLowerCase()
}

function isLikelyGasError(err: any): boolean {
  const text = errorText(err)
  if (!text) return false
  return [
    'out of gas',
    'intrinsic gas too low',
    'gas required exceeds allowance',
    'gas limit',
    'exceeds block gas limit',
    'unpredictable_gas_limit',
    'cannot estimate gas'
  ].some(x => text.includes(x))
}

function chunkIds(tokenIds: bigint[], size: number) {
  const chunks: bigint[][] = []
  for (let i = 0; i < tokenIds.length; i += size) {
    chunks.push(tokenIds.slice(i, i + size))
  }
  return chunks
}

export function useMinerActions() {
  const w = useWallet()
  const { triggerRefresh } = useMinerStatsRefresh()
  const { triggerRefresh: triggerGlobalRefresh } = useGlobalRefresh()

  const busy = ref(false)
  const error = ref('')
  const lastTx = ref('')
  const queueStatus = ref<MinerQueueStatus>({
    running: false,
    total: 0,
    processed: 0,
    currentBatchSize: 0,
    remaining: 0,
    note: ''
  })
  const buyQueueStatus = ref<MinerQueueStatus>({
    running: false,
    total: 0,
    processed: 0,
    currentBatchSize: 0,
    remaining: 0,
    note: ''
  })

  function resetQueueStatus() {
    queueStatus.value = {
      running: false,
      total: 0,
      processed: 0,
      currentBatchSize: 0,
      remaining: 0,
      note: ''
    }
  }

  function resetBuyQueueStatus() {
    buyQueueStatus.value = {
      running: false,
      total: 0,
      processed: 0,
      currentBatchSize: 0,
      remaining: 0,
      note: ''
    }
  }

  async function withSigner<T>(fn: (miner: any) => Promise<T>): Promise<T> {
    error.value = ''
    lastTx.value = ''

    if (!w.isConnected.value) throw new Error('wallet nicht verbunden')
    if (!w.onChain.value) throw new Error('falsches netzwerk (bitte avalanche fuji)')

    busy.value = true
    try {
      const signer = await w.getSigner()
      const miner = new Contract(ADDRESSES.minerNft, MINER_ACTION_ABI, signer) as any
      const res = await fn(miner)
      return res
    } catch (e: any) {
      error.value = e?.shortMessage ?? e?.message ?? String(e)
      throw e
    } finally {
      busy.value = false
    }
  }

  async function sendUpgradeBatchWithEstimatedGas(params: {
    miner: any
    tokenIds: bigint[]
    mebtcShareBps: number
    kind: 'power' | 'hash'
  }) {
    const { miner, tokenIds, mebtcShareBps, kind } = params
    if (kind === 'power') {
      if (mebtcShareBps > 0) {
        const est = await miner.requestUpgradePowerBatchWithMebtc.estimateGas(tokenIds, mebtcShareBps)
        const gasLimit = (BigInt(est) * 12n) / 10n + 50_000n
        return miner.requestUpgradePowerBatchWithMebtc(tokenIds, mebtcShareBps, { gasLimit })
      }
      const est = await miner.requestUpgradePowerBatch.estimateGas(tokenIds)
      const gasLimit = (BigInt(est) * 12n) / 10n + 50_000n
      return miner.requestUpgradePowerBatch(tokenIds, { gasLimit })
    }

    if (mebtcShareBps > 0) {
      const est = await miner.requestUpgradeHashBatchWithMebtc.estimateGas(tokenIds, mebtcShareBps)
      const gasLimit = (BigInt(est) * 12n) / 10n + 50_000n
      return miner.requestUpgradeHashBatchWithMebtc(tokenIds, mebtcShareBps, { gasLimit })
    }
    const est = await miner.requestUpgradeHashBatch.estimateGas(tokenIds)
    const gasLimit = (BigInt(est) * 12n) / 10n + 50_000n
    return miner.requestUpgradeHashBatch(tokenIds, { gasLimit })
  }

  async function requestUpgradeBatchQueued(params: {
    tokenIds: bigint[]
    mebtcShareBps: number
    kind: 'power' | 'hash'
  }) {
    const { tokenIds, mebtcShareBps, kind } = params
    if (!tokenIds.length) throw new Error('keine tokenIds')

    resetBuyQueueStatus()
    resetQueueStatus()
    const share = Math.max(0, Math.min(3000, Math.floor(mebtcShareBps)))
    const chunks = chunkIds(tokenIds, MAX_UPGRADE_BATCH_IDS_PER_TX)
    let processed = 0

    queueStatus.value = {
      running: true,
      total: tokenIds.length,
      processed,
      currentBatchSize: chunks[0]?.length ?? 0,
      remaining: tokenIds.length,
      note: ''
    }

    await withSigner(async (miner) => {
      while (chunks.length) {
        const batch = chunks.shift()!
        try {
          const tx = await sendUpgradeBatchWithEstimatedGas({
            miner,
            tokenIds: batch,
            mebtcShareBps: share,
            kind
          })
          lastTx.value = tx.hash
          await tx.wait()
          processed += batch.length
          queueStatus.value = {
            running: processed < tokenIds.length,
            total: tokenIds.length,
            processed,
            currentBatchSize: chunks[0]?.length ?? 0,
            remaining: tokenIds.length - processed,
            note: ''
          }
        } catch (e: any) {
          if (batch.length > 1 && isLikelyGasError(e)) {
            const leftSize = Math.ceil(batch.length / 2)
            const left = batch.slice(0, leftSize)
            const right = batch.slice(leftSize)
            if (right.length) chunks.unshift(right)
            chunks.unshift(left)
            queueStatus.value = {
              running: true,
              total: tokenIds.length,
              processed,
              currentBatchSize: chunks[0]?.length ?? 0,
              remaining: tokenIds.length - processed,
              note: `gas-engpass: teile batch ${batch.length} -> ${left.length}${right.length ? `/${right.length}` : ''}`
            }
            continue
          }
          throw e
        }
      }

      triggerRefresh()
      triggerGlobalRefresh(kind === 'power' ? 'upgrade-power-batch' : 'upgrade-hash-batch')
    }).finally(() => {
      queueStatus.value = {
        ...queueStatus.value,
        running: false
      }
    })
  }

  async function buyFromModel(modelId: number, quantity: number) {
    resetQueueStatus()
    resetBuyQueueStatus()
    const qty = Math.max(1, Math.floor(quantity))
    if (!Number.isFinite(modelId) || modelId <= 0) {
      throw new Error('ungueltige modelId')
    }

    const qtyChunks: number[] = []
    for (let i = 0; i < qty; i += MAX_BUY_QTY_PER_TX) {
      qtyChunks.push(Math.min(MAX_BUY_QTY_PER_TX, qty - i))
    }

    let processed = 0
    buyQueueStatus.value = {
      running: true,
      total: qty,
      processed: 0,
      currentBatchSize: qtyChunks[0] ?? 0,
      remaining: qty,
      note: ''
    }

    await withSigner(async (miner) => {
      while (qtyChunks.length) {
        const chunkQty = qtyChunks.shift()!
        try {
          const est = await miner.buyFromModel.estimateGas(modelId, chunkQty)
          const gasLimit = (BigInt(est) * 12n) / 10n + 50_000n
          const tx = await miner.buyFromModel(modelId, chunkQty, { gasLimit })
          lastTx.value = tx.hash
          await tx.wait()
          processed += chunkQty
          buyQueueStatus.value = {
            running: processed < qty,
            total: qty,
            processed,
            currentBatchSize: qtyChunks[0] ?? 0,
            remaining: qty - processed,
            note: ''
          }
        } catch (e: any) {
          if (chunkQty > 1 && isLikelyGasError(e)) {
            const left = Math.ceil(chunkQty / 2)
            const right = chunkQty - left
            if (right > 0) qtyChunks.unshift(right)
            qtyChunks.unshift(left)
            buyQueueStatus.value = {
              running: true,
              total: qty,
              processed,
              currentBatchSize: qtyChunks[0] ?? 0,
              remaining: qty - processed,
              note: `gas-engpass: teile menge ${chunkQty} -> ${left}${right > 0 ? `/${right}` : ''}`
            }
            continue
          }
          throw e
        }
      }

      triggerGlobalRefresh('buy-miner', { rescanOwned: true })
    }).finally(() => {
      buyQueueStatus.value = {
        ...buyQueueStatus.value,
        running: false
      }
    })
  }

  async function requestUpgradePower(tokenId: bigint, mebtcShareBps = 0) {
    resetBuyQueueStatus()
    resetQueueStatus()
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
    resetBuyQueueStatus()
    resetQueueStatus()
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

  async function requestUpgradePowerBatch(tokenIds: bigint[], mebtcShareBps = 0) {
    await requestUpgradeBatchQueued({
      tokenIds,
      mebtcShareBps,
      kind: 'power'
    })
  }

  async function requestUpgradeHashBatch(tokenIds: bigint[], mebtcShareBps = 0) {
    await requestUpgradeBatchQueued({
      tokenIds,
      mebtcShareBps,
      kind: 'hash'
    })
  }

  return {
    busy,
    error,
    lastTx,
    maxBuyQtyPerTx: MAX_BUY_QTY_PER_TX,
    buyQueueStatus,
    maxBatchIdsPerTx: MAX_UPGRADE_BATCH_IDS_PER_TX,
    queueStatus,
    buyFromModel,
    requestUpgradePower,
    requestUpgradeHash,
    requestUpgradePowerBatch,
    requestUpgradeHashBatch
  }
}
