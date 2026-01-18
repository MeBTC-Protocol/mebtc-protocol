import { ref } from 'vue'
import { Contract, MaxUint256 } from 'ethers'
import { ADDRESSES } from '../contracts/addresses'
import { useWallet } from './useWallet'
import { useGlobalRefresh } from './useGlobalRefresh'

const ERC20_ABI = [
  'function approve(address spender, uint256 amount) returns (bool)'
]

export function useApproveRouterTokens() {
  const { getSigner, isConnected, onChain } = useWallet()
  const { triggerRefresh } = useGlobalRefresh()

  const busy = ref(false)
  const error = ref('')
  const lastTx = ref('')

  async function approve(token: string) {
    error.value = ''
    lastTx.value = ''

    if (!isConnected.value) throw new Error('wallet nicht verbunden')
    if (!onChain.value) throw new Error('falsches netzwerk (bitte avalanche fuji)')

    busy.value = true
    try {
      const signer = await getSigner()
      const erc20 = new Contract(token, ERC20_ABI, signer)
      const tx = await erc20.approve(ADDRESSES.router, MaxUint256)
      lastTx.value = tx.hash
      await tx.wait()
      triggerRefresh('approve-router')
    } catch (e: any) {
      error.value = e?.shortMessage ?? e?.message ?? String(e)
      throw e
    } finally {
      busy.value = false
    }
  }

  async function approveUsdc() {
    return approve(ADDRESSES.usdc)
  }

  async function approveMebtc() {
    return approve(ADDRESSES.mebtc)
  }

  return { busy, error, lastTx, approveUsdc, approveMebtc }
}
