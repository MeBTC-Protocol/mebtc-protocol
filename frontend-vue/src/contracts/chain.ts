import { ENV } from '../config/env'

export const FUJI = {
  chainId: 43113,
  name: 'Avalanche Fuji',
  rpcUrl: ENV.FUJI_RPC_URL,
  blockExplorer: 'https://testnet.snowtrace.io'
} as const

export const AVALANCHE = {
  chainId: 43114,
  name: 'Avalanche',
  rpcUrl: ENV.AVALANCHE_RPC_URL,
  blockExplorer: 'https://snowtrace.io'
} as const

const targetId = Number(ENV.TARGET_CHAIN_ID)
export const TARGET_CHAIN = targetId === AVALANCHE.chainId ? AVALANCHE : FUJI
