import { Contract, parseUnits } from 'ethers'
import type { JsonRpcProvider, Signer } from 'ethers'
import { ADDRESSES, TOKENS } from '../contracts/addresses'

const ROUTER_ABI = [
  'function addLiquidity(address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,address to,uint deadline) returns (uint amountA,uint amountB,uint liquidity)'
]

export async function addLiquidity(params: {
  provider: JsonRpcProvider
  signer: Signer
  usdcAmount: string
  mebtcAmount: string
  slippageBps?: number
}): Promise<{ txHash: string }> {
  const { signer, usdcAmount, mebtcAmount, slippageBps = 100 } = params

  const usdc = parseUnits(usdcAmount, TOKENS.usdc.decimals)
  const mebtc = parseUnits(mebtcAmount, TOKENS.mebtc.decimals)

  if (usdc <= 0n || mebtc <= 0n) throw new Error('betrag muss > 0 sein')

  const minUsdc = (usdc * BigInt(10_000 - slippageBps)) / 10_000n
  const minMebtc = (mebtc * BigInt(10_000 - slippageBps)) / 10_000n
  const deadline = Math.floor(Date.now() / 1000) + 1200

  const router = new Contract(ADDRESSES.router, ROUTER_ABI, signer) as any
  const tx = await router.addLiquidity(
    ADDRESSES.usdc,
    ADDRESSES.mebtc,
    usdc,
    mebtc,
    minUsdc,
    minMebtc,
    await signer.getAddress(),
    deadline
  )
  await tx.wait()

  return { txHash: tx.hash }
}
