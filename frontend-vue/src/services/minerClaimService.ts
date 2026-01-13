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

function miningManagerRead(provider: JsonRpcProvider) {
  return new Contract(ADDRESSES.miningManager, miningManagerAbi, provider)
}

function miningManagerWrite(signer: Signer) {
  return new Contract(ADDRESSES.miningManager, miningManagerAbi, signer)
}

async function payTokenRead(provider: JsonRpcProvider) {
  const token = await fetchPayTokenAddress(provider)
  return new Contract(token, erc20Abi, provider)
}

async function payTokenWrite(provider: JsonRpcProvider, signer: Signer) {
  const token = await fetchPayTokenAddress(provider)
  return new Contract(token, erc20Abi, signer)
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
}): Promise<{ claimTxHash: string; approveTxHash?: string }> {
  const { provider, signer, owner, tokenIds, totalFeeNeeded } = params

  if (tokenIds.length === 0) throw new Error("keine tokenIds")

  const { approveTxHash } = await ensureUsdcAllowanceExact({
    provider,
    signer,
    owner,
    spender: ADDRESSES.miningManager,
    needed: totalFeeNeeded,
  })

  const mm = miningManagerWrite(signer)
  const tx = await mm.claim(tokenIds)
  await tx.wait()

  return { claimTxHash: tx.hash, approveTxHash }
}
