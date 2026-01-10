import { computed, toRefs } from 'vue'
import { BrowserProvider, type Eip1193Provider, type JsonRpcProvider } from 'ethers'
import { useAppKitAccount, useAppKitNetwork, useAppKitProvider } from '@reown/appkit/vue'
import { FUJI } from '../contracts/chain'
import { getReadProvider } from '../services/readProvider'

export function useWallet() {
  const account = useAppKitAccount({ namespace: 'eip155' })
  const network = useAppKitNetwork()
  const providerState = useAppKitProvider<Eip1193Provider>('eip155')
  const { walletProvider } = toRefs(providerState)

  const isConnected = computed(() => !!account.value?.isConnected)

  const address = computed(() => {
    const a = account.value?.address
    return typeof a === 'string' && a.length > 0 ? a : undefined
  })

  const chainId = computed<number | undefined>(() => {
    const raw: any = network.value?.chainId
    if (typeof raw === 'number') return raw
    if (typeof raw === 'string' && raw.length > 0) return Number(raw)
    return undefined
  })

  const onChain = computed(() => chainId.value === FUJI.chainId)

  // ✅ Read Provider (RPC) -> immer verfügbar
  const readProvider = computed<JsonRpcProvider>(() => getReadProvider())

  // ✅ AppKit Wallet Provider -> nur wenn wirklich connected & provider vorhanden
  const hasWalletProvider = computed(() => !!walletProvider.value)

  const browserProvider = computed<BrowserProvider | undefined>(() => {
    const wp = walletProvider.value
    if (!wp) return undefined
    return new BrowserProvider(wp)
  })

  async function getSigner() {
    // SRP: diese Funktion liefert Signer ODER wirft (klarer Fehler)
    const bp = browserProvider.value
    if (!bp) {
      throw new Error('no wallet provider (AppKit walletProvider is undefined). Reconnect wallet or reload.')
    }
    return await bp.getSigner()
  }

  return {
    isConnected,
    address,
    chainId,
    onChain,
    readProvider,
    hasWalletProvider,
    browserProvider,
    getSigner
  }
}


