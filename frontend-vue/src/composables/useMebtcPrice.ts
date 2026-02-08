import { ref, computed, watchEffect } from 'vue'
import { Contract, formatUnits } from 'ethers'
import { ADDRESSES, TOKENS } from '../contracts/addresses'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'

const TWAP_ABI = [
  'function isReady() view returns (bool)',
  'function priceMebtcInUsdc() view returns (uint256)'
]

const PAIR_ABI = [
  'function token0() view returns (address)',
  'function getReserves() view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast)'
]

type Source = 'twap' | 'pool' | 'none'

export function useMebtcPrice() {
  const { readProvider } = useWallet()
  const { refreshKey } = useGlobalRefresh()

  const loading = ref(false)
  const priceUsdc = ref<bigint | null>(null)
  const source = ref<Source>('none')
  const error = ref('')

  watchEffect(async () => {
    refreshKey.value
    loading.value = true
    error.value = ''

    try {
      const p = readProvider.value
      const twap = new Contract(ADDRESSES.twapOracle, TWAP_ABI, p) as any

      try {
        const ready = await twap.isReady()
        if (ready) {
          const v = await twap.priceMebtcInUsdc()
          priceUsdc.value = v as bigint
          source.value = 'twap'
          return
        }
      } catch {
        // fallback to pool spot price
      }

      const pair = new Contract(ADDRESSES.pair, PAIR_ABI, p) as any
      const [token0, reserves] = await Promise.all([pair.token0(), pair.getReserves()])

      const r0 = reserves?.[0] as bigint
      const r1 = reserves?.[1] as bigint
      if (r0 === 0n || r1 === 0n) {
        priceUsdc.value = null
        source.value = 'none'
        return
      }

      const usdcIs0 = String(token0).toLowerCase() === ADDRESSES.usdc.toLowerCase()
      const reserveUsdc = usdcIs0 ? r0 : r1
      const reserveMebtc = usdcIs0 ? r1 : r0

      const price = (reserveUsdc * 10n ** BigInt(TOKENS.mebtc.decimals)) / reserveMebtc
      priceUsdc.value = price
      source.value = 'pool'
    } catch (e: any) {
      error.value = e?.shortMessage ?? e?.message ?? String(e)
      priceUsdc.value = null
      source.value = 'none'
    } finally {
      loading.value = false
    }
  })

  const priceText = computed(() => {
    if (!priceUsdc.value) return '-'
    return formatUnits(priceUsdc.value, TOKENS.usdc.decimals)
  })

  const sourceText = computed(() => {
    if (source.value === 'twap') return 'TWAP'
    if (source.value === 'pool') return 'Pool'
    return '-'
  })

  return { priceUsdc, priceText, source, sourceText, loading, error }
}
