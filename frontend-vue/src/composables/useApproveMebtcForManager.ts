import { ref } from 'vue'
import { Contract, MaxUint256 } from 'ethers'
import { ADDRESSES } from '../contracts/addresses'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'

const ERC20_ABI = [
  'function approve(address spender, uint256 amount) returns (bool)'
]

export function useApproveMebtcForManager() {
  const { getSigner, isConnected, onChain } = useWallet()
  const { triggerRefresh } = useGlobalRefresh()

  const busy = ref(false)
  const error = ref('')
  const lastTx = ref('')

  async function approve(amount: bigint) {
    error.value = ''
    lastTx.value = ''

    if (!isConnected.value) throw new Error('wallet nicht verbunden')
    if (!onChain.value) throw new Error('falsches netzwerk (bitte avalanche fuji)')

    busy.value = true
    try {
      const signer = await getSigner()
      const mebtc = new Contract(ADDRESSES.mebtc, ERC20_ABI, signer)
      const tx = await mebtc.approve(ADDRESSES.miningManager, amount)
      lastTx.value = tx.hash
      await tx.wait()
      triggerRefresh('approve-mebtc-claim')
    } catch (e: any) {
      error.value = e?.shortMessage ?? e?.message ?? String(e)
      throw e
    } finally {
      busy.value = false
    }
  }

  async function approveMax() {
    return approve(MaxUint256)
  }

  return { busy, error, lastTx, approveMax }
}
