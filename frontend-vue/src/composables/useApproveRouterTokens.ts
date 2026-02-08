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

  async function approve(token: string, amount: bigint) {
    error.value = ''
    lastTx.value = ''

    if (!isConnected.value) throw new Error('wallet nicht verbunden')
    if (!onChain.value) throw new Error('falsches netzwerk (bitte avalanche fuji)')

    busy.value = true
    try {
      const signer = await getSigner()
      const erc20 = new Contract(token, ERC20_ABI, signer) as any
      const tx = await erc20.approve(ADDRESSES.router, amount)
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
    return approve(ADDRESSES.usdc, MaxUint256)
  }

  async function approveMebtc() {
    return approve(ADDRESSES.mebtc, MaxUint256)
  }

  async function approveLp() {
    return approve(ADDRESSES.pair, MaxUint256)
  }

  async function approveUsdcExact(amount: bigint) {
    return approve(ADDRESSES.usdc, amount)
  }

  async function approveMebtcExact(amount: bigint) {
    return approve(ADDRESSES.mebtc, amount)
  }

  async function approveLpExact(amount: bigint) {
    return approve(ADDRESSES.pair, amount)
  }

  return {
    busy,
    error,
    lastTx,
    approveUsdc,
    approveMebtc,
    approveLp,
    approveUsdcExact,
    approveMebtcExact,
    approveLpExact
  }
}
