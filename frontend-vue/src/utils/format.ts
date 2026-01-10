import { formatUnits } from 'ethers'

export const MAX_UINT256 = (1n << 256n) - 1n

export function formatToken(raw: bigint | undefined, decimals: number) {
  if (raw === undefined) return '-'
  return formatUnits(raw, decimals)
}

export function formatAllowanceUSDC(raw: bigint | undefined, usdcDecimals: number) {
  if (raw === undefined) return '-'
  if (raw === MAX_UINT256) return '∞ (max)'
  return formatUnits(raw, usdcDecimals)
}

export function shortAddr(a?: unknown) {
  if (typeof a !== 'string') return '-'
  if (a.length <= 12) return a
  return `${a.slice(0, 6)}...${a.slice(-4)}`
}


