import { Contract } from 'ethers'
import type { JsonRpcProvider } from 'ethers'
import { ADDRESSES, TOKENS } from '../contracts/addresses'
import { miningManagerAbi } from '../contracts/abi'

export async function fetchPayTokenAddress(provider: JsonRpcProvider): Promise<string> {
  const manager = new Contract(ADDRESSES.miningManager, miningManagerAbi, provider)
  try {
    return await manager.payToken()
  } catch {
    return ADDRESSES.usdc
  }
}

const ERC20_META_ABI = [
  'function symbol() view returns (string)',
  'function decimals() view returns (uint8)'
]

export async function fetchPayTokenMeta(provider: JsonRpcProvider): Promise<{
  address: string
  symbol: string
  decimals: number
}> {
  const address = await fetchPayTokenAddress(provider)
  const token = new Contract(address, ERC20_META_ABI, provider)

  let symbol = TOKENS.usdc.symbol
  let decimals = TOKENS.usdc.decimals

  try {
    symbol = await token.symbol()
  } catch {
    // fallback to default
  }

  try {
    decimals = Number(await token.decimals())
  } catch {
    // fallback to default
  }

  return { address, symbol, decimals }
}
