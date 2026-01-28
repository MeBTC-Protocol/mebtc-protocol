import type { Interface } from 'ethers'

export function pickFunctionName(iface: Interface, candidates: string[]): string {
  for (const name of candidates) {
    try {
      // getFunction wirft, wenn es die Funktion nicht gibt
      iface.getFunction(name)
      return name
    } catch {
      // ignore
    }
  }
  throw new Error(
    `Keine passende Funktion gefunden. Getestet: ${candidates.join(', ')}`
  )
}
