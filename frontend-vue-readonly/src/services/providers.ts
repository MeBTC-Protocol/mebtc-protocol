import { BrowserProvider, JsonRpcProvider } from 'ethers'
import { TARGET_CHAIN } from '../contracts/chain'

let cachedReadProvider: JsonRpcProvider | undefined

export function getReadProvider(): JsonRpcProvider {
  if (!cachedReadProvider) {
    cachedReadProvider = new JsonRpcProvider(TARGET_CHAIN.rpcUrl)
  }
  return cachedReadProvider
}

export function resetReadProvider() {
  // Falls du später Chain/RPC dynamisch wechseln willst
  cachedReadProvider = undefined
}

export function getBrowserProvider(walletProvider: unknown): BrowserProvider {
  // BrowserProvider sollte pro injected provider ok sein
  return new BrowserProvider(walletProvider as any)
}
