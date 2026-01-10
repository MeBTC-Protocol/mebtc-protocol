import { createAppKit } from '@reown/appkit/vue'
import { EthersAdapter } from '@reown/appkit-adapter-ethers'
import { defineChain } from '@reown/appkit/networks'
import { ENV } from '../config/env'
import { FUJI } from '../contracts/chain'

export function initAppKit() {
  const projectId = ENV.REOWN_PROJECT_ID

  const metadata = {
    name: 'MeBTC Dashboard',
    description: 'MeBTC Dashboard (Vue + Reown + Ethers)',
    url: ENV.APP_URL,
    icons: []
  }

  const avalancheFuji = defineChain({
    id: FUJI.chainId,
    name: FUJI.name,
    caipNetworkId: 'eip155:43113',
    chainNamespace: 'eip155',
    nativeCurrency: { name: 'Avalanche', symbol: 'AVAX', decimals: 18 },
    rpcUrls: {
      default: {
        http: [FUJI.rpcUrl]
      }
    },
    blockExplorers: {
      default: { name: 'SnowTrace', url: 'https://testnet.snowtrace.io' }
    }
  })

  const ethersAdapter = new EthersAdapter()

  createAppKit({
    adapters: [ethersAdapter],
    networks: [avalancheFuji],
    defaultNetwork: avalancheFuji,
    projectId,
    metadata,
    defaultAccountTypes: { eip155: 'eoa' },
    features: { analytics: false }
  })
}



