import { Contract } from 'ethers'
import { computed } from 'vue'
import { ADDRESSES } from '../contracts/addresses'
import { erc20Abi, minerNftAbi, miningManagerAbi } from '../contracts/abi'
import { useWallet } from './useWallet'

export function useContracts() {
  const w = useWallet()

  const usdcRead = computed(() => new Contract(ADDRESSES.usdc, erc20Abi, w.readProvider.value))
  const mebtcRead = computed(() => new Contract(ADDRESSES.mebtc, erc20Abi, w.readProvider.value))
  const minerRead = computed(() => new Contract(ADDRESSES.minerNft, minerNftAbi, w.readProvider.value))
  const managerRead = computed(() => new Contract(ADDRESSES.miningManager, miningManagerAbi, w.readProvider.value))

  async function usdcWrite() {
    const signer = await w.getSigner()
    return new Contract(ADDRESSES.usdc, erc20Abi, signer)
  }

  async function managerWrite() {
    const signer = await w.getSigner()
    return new Contract(ADDRESSES.miningManager, miningManagerAbi, signer)
  }

  return {
    usdcRead,
    mebtcRead,
    minerRead,
    managerRead,
    usdcWrite,
    managerWrite
  }
}
