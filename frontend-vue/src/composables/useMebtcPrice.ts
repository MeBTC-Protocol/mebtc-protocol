import { ref, computed, watchEffect } from 'vue'
import { Contract, formatUnits } from 'ethers'
import { ADDRESSES, TOKENS } from '../contracts/addresses'
import { twapOracleAbi } from '../contracts/abi'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'

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
  const twapPriceUsdc = ref<bigint | null>(null)
  const poolPriceUsdc = ref<bigint | null>(null)
  const source = ref<Source>('none')
  const error = ref('')
  const feePriceFresh = ref(false)

  watchEffect(async () => {
    refreshKey.value
    loading.value = true
    error.value = ''

    try {
      const p = readProvider.value
      const twap = new Contract(ADDRESSES.twapOracle, twapOracleAbi, p) as any

      twapPriceUsdc.value = null
      poolPriceUsdc.value = null

      try {
        const [v, fresh] = await twap.getPriceForFees()
        feePriceFresh.value = Boolean(fresh)
        if (v && v > 0n) {
          twapPriceUsdc.value = v as bigint
        }
      } catch {
        feePriceFresh.value = false
      }

      try {
        const pair = new Contract(ADDRESSES.pair, PAIR_ABI, p) as any
        const [token0, reserves] = await Promise.all([pair.token0(), pair.getReserves()])

        const r0 = reserves?.[0] as bigint
        const r1 = reserves?.[1] as bigint
        if (r0 === 0n || r1 === 0n) {
          poolPriceUsdc.value = null
        } else {
          const usdcIs0 = String(token0).toLowerCase() === ADDRESSES.usdc.toLowerCase()
          const reserveUsdc = usdcIs0 ? r0 : r1
          const reserveMebtc = usdcIs0 ? r1 : r0
          const price = (reserveUsdc * 10n ** BigInt(TOKENS.mebtc.decimals)) / reserveMebtc
          poolPriceUsdc.value = price
        }
      } catch {
        poolPriceUsdc.value = null
      }

      if (feePriceFresh.value && twapPriceUsdc.value && twapPriceUsdc.value > 0n) {
        priceUsdc.value = twapPriceUsdc.value
        source.value = 'twap'
      } else if (poolPriceUsdc.value && poolPriceUsdc.value > 0n) {
        priceUsdc.value = poolPriceUsdc.value
        source.value = 'pool'
      } else if (twapPriceUsdc.value && twapPriceUsdc.value > 0n) {
        priceUsdc.value = twapPriceUsdc.value
        source.value = 'twap'
      } else {
        priceUsdc.value = null
        source.value = 'none'
      }
      if (!twapPriceUsdc.value && !poolPriceUsdc.value) {
        error.value = 'kein TWAP- oder Poolpreis verfügbar'
      }
    } catch (e: any) {
      error.value = e?.shortMessage ?? e?.message ?? String(e)
      priceUsdc.value = null
      twapPriceUsdc.value = null
      poolPriceUsdc.value = null
      source.value = 'none'
      feePriceFresh.value = false
    } finally {
      loading.value = false
    }
  })

  const priceText = computed(() => {
    if (!priceUsdc.value) return '-'
    return formatUnits(priceUsdc.value, TOKENS.usdc.decimals)
  })

  const twapPriceText = computed(() => {
    if (!twapPriceUsdc.value) return '-'
    return formatUnits(twapPriceUsdc.value, TOKENS.usdc.decimals)
  })

  const poolPriceText = computed(() => {
    if (!poolPriceUsdc.value) return '-'
    return formatUnits(poolPriceUsdc.value, TOKENS.usdc.decimals)
  })

  const sourceText = computed(() => {
    if (source.value === 'twap') return 'TWAP'
    if (source.value === 'pool') return 'Pool'
    return '-'
  })

  return {
    priceUsdc,
    priceText,
    twapPriceUsdc,
    twapPriceText,
    poolPriceUsdc,
    poolPriceText,
    source,
    sourceText,
    feePriceFresh,
    loading,
    error
  }
}
