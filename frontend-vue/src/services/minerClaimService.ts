import { Contract, formatUnits } from "ethers"
import type { JsonRpcProvider, Signer } from "ethers"
import { ADDRESSES, TOKENS } from "../contracts/addresses"
import { miningManagerAbi, erc20Abi } from "../contracts/abi"
import { fetchPayTokenAddress } from "./payToken"

export type ClaimPreview = {
  tokenId: bigint
  rewardRaw: bigint
  rewardFormatted: string
  feeUsdcRaw: bigint
  feeUsdcFormatted: string
}

export type ClaimQueueProgress = {
  total: number
  processed: number
  currentBatchSize: number
  remaining: number
  note?: string
}

function miningManagerRead(provider: JsonRpcProvider) {
  return new Contract(ADDRESSES.miningManager, miningManagerAbi, provider) as any
}

function miningManagerWrite(signer: Signer) {
  return new Contract(ADDRESSES.miningManager, miningManagerAbi, signer) as any
}

async function payTokenRead(provider: JsonRpcProvider) {
  const token = await fetchPayTokenAddress(provider)
  return new Contract(token, erc20Abi, provider) as any
}

async function payTokenWrite(provider: JsonRpcProvider, signer: Signer) {
  const token = await fetchPayTokenAddress(provider)
  return new Contract(token, erc20Abi, signer) as any
}

function errorText(err: any): string {
  const parts = [
    err?.shortMessage,
    err?.message,
    err?.reason,
    err?.code,
    err?.cause?.shortMessage,
    err?.cause?.message
  ]
  return parts.filter(Boolean).join(" | ").toLowerCase()
}

function isLikelyGasError(err: any): boolean {
  const text = errorText(err)
  if (!text) return false
  return [
    "out of gas",
    "intrinsic gas too low",
    "gas required exceeds allowance",
    "gas limit",
    "exceeds block gas limit",
    "unpredictable_gas_limit",
    "cannot estimate gas"
  ].some(x => text.includes(x))
}

async function sendClaimWithEstimatedGas(mm: any, tokenIds: bigint[], share: number) {
  if (share > 0) {
    const est = await mm.claimWithMebtc.estimateGas(tokenIds, share)
    const gasLimit = (BigInt(est) * 12n) / 10n + 50_000n
    return mm.claimWithMebtc(tokenIds, share, { gasLimit })
  }
  const est = await mm.claim.estimateGas(tokenIds)
  const gasLimit = (BigInt(est) * 12n) / 10n + 50_000n
  return mm.claim(tokenIds, { gasLimit })
}

/**
 * preview(id, owner) -> (reward, feeUSDC)
 * SRP: nur Preview für ein Token.
 */
export async function fetchClaimPreview(
  provider: JsonRpcProvider,
  tokenId: bigint,
  owner: string
): Promise<ClaimPreview> {
  const mm = miningManagerRead(provider)
  const res = await mm.preview(tokenId, owner)

  const rewardRaw = BigInt(res[0])
  const feeUsdcRaw = BigInt(res[1])

  return {
    tokenId,
    rewardRaw,
    rewardFormatted: formatUnits(rewardRaw, TOKENS.mebtc.decimals),
    feeUsdcRaw,
    feeUsdcFormatted: formatUnits(feeUsdcRaw, TOKENS.usdc.decimals),
  }
}

/**
 * SRP: nur Allowance lesen.
 */
export async function getUsdcAllowance(
  provider: JsonRpcProvider,
  owner: string,
  spender: string
): Promise<bigint> {
  const payToken = await payTokenRead(provider)
  const allowance = await payToken.allowance(owner, spender)
  return BigInt(allowance)
}

/**
 * SRP: nur sicherstellen, dass Allowance >= needed.
 * Policy: wir approven "exakt" needed (Endwert = needed).
 * (USDC auf Fuji macht das i.d.R. sauber. Falls ein Token 0->needed verlangt,
 * kannst du hier optional approve(spender, 0) davor setzen.)
 */
export async function ensureUsdcAllowanceExact(params: {
  provider: JsonRpcProvider
  signer: Signer
  owner: string
  spender: string
  needed: bigint
}): Promise<{ approved: boolean; approveTxHash?: string }> {
  const { provider, signer, owner, spender, needed } = params

  if (needed <= 0n) return { approved: false }

  const current = await getUsdcAllowance(provider, owner, spender)
  if (current >= needed) return { approved: false }

  const payToken = await payTokenWrite(provider, signer)
  const tx = await payToken.approve(spender, needed)
  await tx.wait()

  return { approved: true, approveTxHash: tx.hash }
}

/**
 * SRP: der eigentliche Batch-Claim.
 * - nimmt tokenIds + totalFeeNeeded (aus deinem Preview/Selection State)
 * - stellt Allowance sicher (approve exact) und macht dann claim(tokenIds)
 */
export async function claimMinerBatch(params: {
  provider: JsonRpcProvider
  signer: Signer
  owner: string
  tokenIds: bigint[]
  totalFeeNeeded: bigint
  mebtcShareBps?: number
}): Promise<{ claimTxHash: string; approveTxHash?: string }> {
  const res = await claimMinerQueued({
    ...params,
    maxBatchSize: Math.max(1, params.tokenIds.length)
  })
  return {
    claimTxHash: res.claimTxHashes[res.claimTxHashes.length - 1] ?? "",
    approveTxHash: res.approveTxHash
  }
}

export async function claimMinerQueued(params: {
  provider: JsonRpcProvider
  signer: Signer
  owner: string
  tokenIds: bigint[]
  totalFeeNeeded: bigint
  mebtcShareBps?: number
  maxBatchSize?: number
  onProgress?: (progress: ClaimQueueProgress) => void
}): Promise<{ claimTxHashes: string[]; approveTxHash?: string }> {
  const {
    provider,
    signer,
    owner,
    tokenIds,
    totalFeeNeeded,
    mebtcShareBps = 0,
    maxBatchSize = 100,
    onProgress
  } = params

  if (!tokenIds.length) throw new Error("keine tokenIds")

  const share = Math.max(0, Math.min(3000, Math.floor(mebtcShareBps)))
  const usdcNeeded = totalFeeNeeded - (totalFeeNeeded * BigInt(share)) / 10_000n
  const effectiveMaxBatchSize = Math.max(1, Math.min(100, Math.floor(maxBatchSize)))

  const { approveTxHash } = await ensureUsdcAllowanceExact({
    provider,
    signer,
    owner,
    spender: ADDRESSES.miningManager,
    needed: usdcNeeded,
  })

  const queue: bigint[][] = []
  for (let i = 0; i < tokenIds.length; i += effectiveMaxBatchSize) {
    queue.push(tokenIds.slice(i, i + effectiveMaxBatchSize))
  }

  let processed = 0
  const txHashes: string[] = []
  const mm = miningManagerWrite(signer)

  onProgress?.({
    total: tokenIds.length,
    processed,
    currentBatchSize: queue[0]?.length ?? 0,
    remaining: tokenIds.length
  })

  while (queue.length) {
    const batch = queue.shift()!
    try {
      const tx = await sendClaimWithEstimatedGas(mm, batch, share)
      await tx.wait()
      txHashes.push(tx.hash)
      processed += batch.length
      onProgress?.({
        total: tokenIds.length,
        processed,
        currentBatchSize: queue[0]?.length ?? 0,
        remaining: tokenIds.length - processed
      })
    } catch (e: any) {
      if (batch.length > 1 && isLikelyGasError(e)) {
        const leftSize = Math.ceil(batch.length / 2)
        const left = batch.slice(0, leftSize)
        const right = batch.slice(leftSize)
        if (right.length) queue.unshift(right)
        queue.unshift(left)
        onProgress?.({
          total: tokenIds.length,
          processed,
          currentBatchSize: queue[0]?.length ?? 0,
          remaining: tokenIds.length - processed,
          note: `gas-engpass: teile batch ${batch.length} -> ${left.length}${right.length ? `/${right.length}` : ''}`
        })
        continue
      }
      throw e
    }
  }

  return { claimTxHashes: txHashes, approveTxHash }
}
