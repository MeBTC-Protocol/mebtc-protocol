import { Contract, parseUnits } from 'ethers'
import type { Signer } from 'ethers'
import { ADDRESSES, TOKENS } from '../contracts/addresses'

const ROUTER_ABI = [
  'function swapExactTokensForTokens(uint256 amountIn,uint256 amountOutMin,address[] calldata path,address to,uint256 deadline) returns (uint256[] memory amounts)'
]

type Direction = 'buy' | 'sell'

export async function swapExactTokens(params: {
  signer: Signer
  direction: Direction
  amountIn: string
  minOut?: string
}): Promise<{ txHash: string }> {
  const { signer, direction, amountIn, minOut = '0' } = params

  const tokenIn = direction === 'buy' ? ADDRESSES.usdc : ADDRESSES.mebtc
  const tokenOut = direction === 'buy' ? ADDRESSES.mebtc : ADDRESSES.usdc
  const inDecimals = direction === 'buy' ? TOKENS.usdc.decimals : TOKENS.mebtc.decimals
  const outDecimals = direction === 'buy' ? TOKENS.mebtc.decimals : TOKENS.usdc.decimals

  const inAmount = parseUnits(amountIn, inDecimals)
  if (inAmount <= 0n) throw new Error('betrag muss > 0 sein')

  let minOutAmount = 0n
  if (minOut.trim()) {
    minOutAmount = parseUnits(minOut, outDecimals)
  }

  const deadline = Math.floor(Date.now() / 1000) + 1200
  const router = new Contract(ADDRESSES.router, ROUTER_ABI, signer)
  const tx = await router.swapExactTokensForTokens(
    inAmount,
    minOutAmount,
    [tokenIn, tokenOut],
    await signer.getAddress(),
    deadline
  )
  await tx.wait()

  return { txHash: tx.hash }
}
