import { Contract, parseUnits } from 'ethers'
import type { JsonRpcProvider, Signer } from 'ethers'
import { ADDRESSES, TOKENS } from '../contracts/addresses'

const ROUTER_ABI = [
  'function removeLiquidity(address tokenA,address tokenB,uint liquidity,uint amountAMin,uint amountBMin,address to,uint deadline) returns (uint amountA,uint amountB)'
]

const PAIR_ABI = [
  'function totalSupply() view returns (uint256)',
  'function token0() view returns (address)',
  'function token1() view returns (address)',
  'function getReserves() view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast)'
]

const LP_DECIMALS = 18

export async function removeLiquidity(params: {
  provider: JsonRpcProvider
  signer: Signer
  lpAmount: string
  slippageBps?: number
}): Promise<{ txHash: string }> {
  const { provider, signer, lpAmount, slippageBps = 100 } = params

  const lp = parseUnits(lpAmount, LP_DECIMALS)
  if (lp <= 0n) throw new Error('betrag muss > 0 sein')

  const pair = new Contract(ADDRESSES.pair, PAIR_ABI, provider)
  const [totalSupply, token0, reserves] = await Promise.all([
    pair.totalSupply(),
    pair.token0(),
    pair.getReserves()
  ])

  const ts = totalSupply as bigint
  if (ts <= 0n) throw new Error('pool ist leer')

  const r0 = reserves?.[0] as bigint
  const r1 = reserves?.[1] as bigint

  const amount0 = (lp * r0) / ts
  const amount1 = (lp * r1) / ts

  const usdcIs0 = String(token0).toLowerCase() === ADDRESSES.usdc.toLowerCase()
  const expUsdc = usdcIs0 ? amount0 : amount1
  const expMebtc = usdcIs0 ? amount1 : amount0

  const minUsdc = (expUsdc * BigInt(10_000 - slippageBps)) / 10_000n
  const minMebtc = (expMebtc * BigInt(10_000 - slippageBps)) / 10_000n
  const deadline = Math.floor(Date.now() / 1000) + 1200

  const router = new Contract(ADDRESSES.router, ROUTER_ABI, signer)
  const tx = await router.removeLiquidity(
    ADDRESSES.usdc,
    ADDRESSES.mebtc,
    lp,
    minUsdc,
    minMebtc,
    await signer.getAddress(),
    deadline
  )
  await tx.wait()

  return { txHash: tx.hash }
}
