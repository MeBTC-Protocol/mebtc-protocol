import { Contract } from 'ethers'
import { computed } from 'vue'
import { ADDRESSES } from '../contracts/addresses'
import { erc20Abi, minerNftAbi, miningManagerAbi } from '../contracts/abi'
import { useWallet } from './useWallet'
import { fetchPayTokenAddress } from '../services/payToken'

export function useContracts() {
  const w = useWallet()

  const mebtcRead = computed(() => new Contract(ADDRESSES.mebtc, erc20Abi, w.readProvider.value))
  const minerRead = computed(() => new Contract(ADDRESSES.minerNft, minerNftAbi, w.readProvider.value))
  const managerRead = computed(() => new Contract(ADDRESSES.miningManager, miningManagerAbi, w.readProvider.value))

  async function payTokenRead() {
    const token = await fetchPayTokenAddress(w.readProvider.value)
    return new Contract(token, erc20Abi, w.readProvider.value)
  }

  async function payTokenWrite() {
    const signer = await w.getSigner()
    const token = await fetchPayTokenAddress(w.readProvider.value)
    return new Contract(token, erc20Abi, signer)
  }

  async function managerWrite() {
    const signer = await w.getSigner()
    return new Contract(ADDRESSES.miningManager, miningManagerAbi, signer)
  }

  return {
    payTokenRead,
    mebtcRead,
    minerRead,
    managerRead,
    payTokenWrite,
    managerWrite
  }
}
