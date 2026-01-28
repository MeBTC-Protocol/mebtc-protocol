import { JsonRpcProvider } from 'ethers'
import { TARGET_CHAIN } from '../contracts/chain'

let provider: JsonRpcProvider | null = null

export function getReadProvider(): JsonRpcProvider {
  if (!provider) {
    provider = new JsonRpcProvider(TARGET_CHAIN.rpcUrl)
  }
  return provider
}

export function resetReadProvider() {
  provider = null
}
