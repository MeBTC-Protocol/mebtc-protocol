import { JsonRpcProvider } from 'ethers'
import { FUJI } from '../contracts/chain'

let provider: JsonRpcProvider | null = null

export function getReadProvider(): JsonRpcProvider {
  if (!provider) {
    provider = new JsonRpcProvider(FUJI.rpcUrl)
  }
  return provider
}

export function resetReadProvider() {
  provider = null
}
