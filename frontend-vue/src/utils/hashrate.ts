const UNITS = ['Hash/s', 'kH/s', 'MH/s', 'GH/s', 'TH/s', 'PH/s', 'EH/s'] as const
const BASE = 1_000n
const GH_TO_HASH = 1_000_000_000n

export function formatHashRateFromHash(value: bigint) {
  let unitIndex = 0
  let scaled = value
  while (scaled >= BASE && unitIndex < UNITS.length - 1) {
    scaled = scaled / BASE
    unitIndex++
  }

  const denom = BASE ** BigInt(unitIndex)
  if (unitIndex === 0) return `${value.toString()} ${UNITS[unitIndex]}`

  const whole = value / denom
  const frac = ((value % denom) * 100n) / denom
  const fracText = frac.toString().padStart(2, '0')
  return `${whole.toString()}.${fracText} ${UNITS[unitIndex]}`
}

// On-chain effHash/baseHashrate are in GH/s.
export function formatHashRateFromGh(valueGh: bigint) {
  return formatHashRateFromHash(valueGh * GH_TO_HASH)
}
