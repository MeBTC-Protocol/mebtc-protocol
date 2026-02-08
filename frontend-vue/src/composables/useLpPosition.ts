import { ref, watchEffect } from 'vue'
import { Contract, formatUnits } from 'ethers'
import { ADDRESSES, TOKENS } from '../contracts/addresses'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'

const PAIR_ABI = [
  'function balanceOf(address owner) view returns (uint256)',
  'function totalSupply() view returns (uint256)',
  'function token0() view returns (address)',
  'function getReserves() view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast)'
]

const LP_DECIMALS = 18

export function useLpPosition() {
  const { address, readProvider } = useWallet()
  const { refreshKey } = useGlobalRefresh()
  let requestId = 0

  const loading = ref(false)
  const lpBalance = ref<bigint>(0n)
  const positionUsdc = ref<bigint>(0n)
  const positionMebtc = ref<bigint>(0n)
  const shareBps = ref<bigint>(0n)

  watchEffect(async () => {
    const rid = ++requestId
    refreshKey.value
    const a = address.value
    if (!a) {
      lpBalance.value = 0n
      positionUsdc.value = 0n
      positionMebtc.value = 0n
      shareBps.value = 0n
      return
    }

    loading.value = true
    try {
      const p = readProvider.value
      const pair = new Contract(ADDRESSES.pair, PAIR_ABI, p) as any
      const [balance, totalSupply, token0, reserves] = await Promise.all([
        pair.balanceOf(a),
        pair.totalSupply(),
        pair.token0(),
        pair.getReserves()
      ])
      if (rid !== requestId) return

      const lp = balance as bigint
      const ts = totalSupply as bigint
      lpBalance.value = lp
      shareBps.value = ts > 0n ? (lp * 10_000n) / ts : 0n

      if (ts <= 0n || lp <= 0n) {
        positionUsdc.value = 0n
        positionMebtc.value = 0n
        return
      }

      const r0 = reserves?.[0] as bigint
      const r1 = reserves?.[1] as bigint
      const usdcIs0 = String(token0).toLowerCase() === ADDRESSES.usdc.toLowerCase()
      const poolUsdc = usdcIs0 ? r0 : r1
      const poolMebtc = usdcIs0 ? r1 : r0

      positionUsdc.value = (lp * poolUsdc) / ts
      positionMebtc.value = (lp * poolMebtc) / ts
    } finally {
      if (rid === requestId) {
        loading.value = false
      }
    }
  })

  function lpBalanceText() {
    return formatUnits(lpBalance.value, LP_DECIMALS)
  }

  function positionUsdcText() {
    return formatUnits(positionUsdc.value, TOKENS.usdc.decimals)
  }

  function positionMebtcText() {
    return formatUnits(positionMebtc.value, TOKENS.mebtc.decimals)
  }

  function shareText() {
    return `${(Number(shareBps.value) / 100).toFixed(2)}%`
  }

  return {
    loading,
    lpBalance,
    positionUsdc,
    positionMebtc,
    shareBps,
    lpBalanceText,
    positionUsdcText,
    positionMebtcText,
    shareText
  }
}
