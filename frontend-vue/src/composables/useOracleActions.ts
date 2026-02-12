import { ref } from 'vue'
import { Contract } from 'ethers'
import { ADDRESSES } from '../contracts/addresses'
import { liquidityEngineAbi } from '../contracts/abi'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'

export function useOracleActions() {
  const { getSigner, isConnected, onChain } = useWallet()
  const { triggerRefresh } = useGlobalRefresh()

  const busy = ref(false)
  const error = ref('')
  const lastTx = ref('')

  async function withSigner<T>(fn: (signer: any) => Promise<T>): Promise<T> {
    error.value = ''
    lastTx.value = ''

    if (!isConnected.value) throw new Error('wallet nicht verbunden')
    if (!onChain.value) throw new Error('falsches netzwerk (bitte avalanche fuji)')

    busy.value = true
    try {
      const signer = await getSigner()
      return await fn(signer)
    } catch (e: any) {
      error.value = e?.shortMessage ?? e?.message ?? String(e)
      throw e
    } finally {
      busy.value = false
    }
  }

  async function executeEpoch() {
    await withSigner(async (signer) => {
      const engine = new Contract(ADDRESSES.engine, liquidityEngineAbi, signer) as any
      const tx = await engine.executeEpoch()
      lastTx.value = tx.hash
      await tx.wait()
      triggerRefresh('engine-epoch')
    })
  }

  return { busy, error, lastTx, executeEpoch }
}
