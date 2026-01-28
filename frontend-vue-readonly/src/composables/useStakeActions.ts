import { ref } from 'vue'
import { Contract } from 'ethers'
import { ADDRESSES } from '../contracts/addresses'
import { stakeVaultAbi } from '../contracts/abi'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'

export function useStakeActions() {
  const { getSigner, isConnected, onChain } = useWallet()
  const { triggerRefresh } = useGlobalRefresh()

  const busy = ref(false)
  const error = ref('')
  const lastTx = ref('')

  async function withSigner<T>(fn: (vault: Contract) => Promise<T>): Promise<T> {
    error.value = ''
    lastTx.value = ''

    if (!isConnected.value) throw new Error('wallet nicht verbunden')
    if (!onChain.value) throw new Error('falsches netzwerk (bitte avalanche fuji)')

    busy.value = true
    try {
      const signer = await getSigner()
      const vault = new Contract(ADDRESSES.stakeVault, stakeVaultAbi, signer)
      return await fn(vault)
    } catch (e: any) {
      error.value = e?.shortMessage ?? e?.message ?? String(e)
      throw e
    } finally {
      busy.value = false
    }
  }

  async function stake(amount: bigint) {
    if (amount <= 0n) throw new Error('betrag muss > 0 sein')
    await withSigner(async (vault) => {
      const tx = await vault.stake(amount)
      lastTx.value = tx.hash
      await tx.wait()
      triggerRefresh('stake')
    })
  }

  async function unstake(amount: bigint) {
    if (amount <= 0n) throw new Error('betrag muss > 0 sein')
    await withSigner(async (vault) => {
      const tx = await vault.unstake(amount)
      lastTx.value = tx.hash
      await tx.wait()
      triggerRefresh('unstake')
    })
  }

  return { busy, error, lastTx, stake, unstake }
}
