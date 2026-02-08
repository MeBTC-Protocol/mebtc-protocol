import { ref, watchEffect } from 'vue'
import { Contract } from 'ethers'
import { useWallet } from './useWallet'
import { ADDRESSES } from '../contracts/addresses'
import { toHttpUrl } from '../utils/ipfs'

const MINER_NFT_ABI = [
  'function tokenURI(uint256 tokenId) view returns (string)'
]

export type MinerMeta = {
  name?: string
  description?: string
  image?: string
  attributes?: Array<{ trait_type?: string; value?: any }>
}

export type MinerMetaState =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'ok'; tokenURI: string; meta: MinerMeta }
  | { status: 'error'; error: string }

export function useMinerNftMetadata(getTokenIds: () => bigint[]) {
  const { readProvider, hasWalletProvider, browserProvider, onChain } = useWallet()

  const states = ref<Record<string, MinerMetaState>>({})

  // simple in-memory caches (avoid refetch on re-render)
  const tokenUriCache = new Map<string, string>()
  const metaCache = new Map<string, MinerMeta>()

  watchEffect(async () => {
    const ids = getTokenIds() || []
    // keep state for current ids; don't delete old ones (caching)
    if (ids.length === 0) return

    const miner = new Contract(ADDRESSES.minerNft, MINER_NFT_ABI, readProvider.value) as any
    let fallbackMiner: any | null = null

    function getFallbackMiner() {
      if (fallbackMiner) return fallbackMiner
      const bp = browserProvider.value
      if (!hasWalletProvider.value || !onChain.value || !bp) return null
      fallbackMiner = new Contract(ADDRESSES.minerNft, MINER_NFT_ABI, bp) as any
      return fallbackMiner
    }

    await Promise.all(
      ids.map(async (id) => {
        const key = id.toString()

        // already ok -> skip
        if (states.value[key]?.status === 'ok') return
        if (states.value[key]?.status === 'loading') return

        states.value = { ...states.value, [key]: { status: 'loading' } }

        try {
          let tokenURI = tokenUriCache.get(key)
          if (!tokenURI) {
            try {
              tokenURI = String(await miner.tokenURI(id))
            } catch {
              const fm = getFallbackMiner()
              if (!fm) throw new Error('tokenURI failed (no fallback provider)')
              tokenURI = String(await fm.tokenURI(id))
            }
            tokenUriCache.set(key, tokenURI)
          }

          let meta = metaCache.get(key)
          if (!meta) {
            const url = toHttpUrl(tokenURI)
            const res = await fetch(url)
            if (!res.ok) throw new Error(`metadata fetch failed: ${res.status} ${res.statusText}`)
            meta = (await res.json()) as MinerMeta
            metaCache.set(key, meta)
          }

          // normalize image url (ipfs -> https)
          const normalized: MinerMeta = {
            ...meta,
            image: toHttpUrl(meta.image)
          }

          states.value = {
            ...states.value,
            [key]: { status: 'ok', tokenURI, meta: normalized }
          }
        } catch (e: any) {
          states.value = {
            ...states.value,
            [key]: { status: 'error', error: e?.message ?? String(e) }
          }
        }
      })
    )
  })

  return { states }
}
