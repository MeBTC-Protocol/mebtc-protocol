import { createAppKit } from '@reown/appkit/vue'
import { EthersAdapter } from '@reown/appkit-adapter-ethers'
import { defineChain } from '@reown/appkit/networks'
import { html, type TemplateResult } from 'lit'
import { WuiAvatar } from '@reown/appkit-ui/wui-avatar'
import { ENV } from '../config/env'
import { AVALANCHE, FUJI, TARGET_CHAIN } from '../contracts/chain'

const MODAL_AVATAR_IMAGE = '/MeBTC%20Logo%20Kugel.png'
let avatarPatched = false

function patchAppKitAvatarFallback() {
  if (avatarPatched) return
  avatarPatched = true

  const originalVisualTemplate = WuiAvatar.prototype.visualTemplate
  WuiAvatar.prototype.visualTemplate = function mebtcAvatarFallback(
    this: WuiAvatar
  ): TemplateResult<1> | null {
    if (!this.imageSrc) {
      this.dataset.variant = 'image'
      this.style.cssText += '\n transform: scale(1.14); transform-origin: center;'
      return html`<wui-image src=${MODAL_AVATAR_IMAGE} alt=${this.alt ?? 'avatar'}></wui-image>`
    }
    return originalVisualTemplate.call(this)
  }
}

export function initAppKit() {
  patchAppKitAvatarFallback()

  const projectId = ENV.REOWN_PROJECT_ID

  const iconBase =
    typeof window !== 'undefined' && window.location?.origin ? window.location.origin : ENV.APP_URL
  const iconUrl = new URL('/Vintage MeBTC cryptocurrency token.png', iconBase).toString()

  const metadata = {
    name: 'MeBTC Dashboard',
    description: 'MeBTC Dashboard',
    url: ENV.APP_URL,
    icons: [iconUrl]
  }

  const avalancheMainnet = defineChain({
    id: AVALANCHE.chainId,
    name: AVALANCHE.name,
    caipNetworkId: 'eip155:43114',
    chainNamespace: 'eip155',
    nativeCurrency: { name: 'Avalanche', symbol: 'AVAX', decimals: 18 },
    rpcUrls: {
      default: {
        http: [AVALANCHE.rpcUrl]
      }
    },
    blockExplorers: {
      default: { name: 'SnowTrace', url: AVALANCHE.blockExplorer }
    }
  })

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
      default: { name: 'SnowTrace', url: FUJI.blockExplorer }
    }
  })

  const ethersAdapter = new EthersAdapter()
  const defaultNetwork =
    TARGET_CHAIN.chainId === AVALANCHE.chainId ? avalancheMainnet : avalancheFuji

  createAppKit({
    adapters: [ethersAdapter],
    networks: [avalancheMainnet, avalancheFuji],
    defaultNetwork,
    projectId,
    metadata,
    defaultAccountTypes: { eip155: 'eoa' },
    features: { analytics: false }
  })
}
