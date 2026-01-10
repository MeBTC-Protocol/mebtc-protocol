import { ENV } from '../config/env'

export const FUJI = {
  chainId: 43113,
  name: 'Avalanche Fuji',
  rpcUrl: ENV.FUJI_RPC_URL
} as const
