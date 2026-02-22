<script setup lang="ts">
import { computed, ref } from 'vue'
import { formatUnits, parseUnits } from 'ethers'
import Header from './components/layout/Header.vue'
import ThemeToggle from './components/common/ThemeToggle.vue'
import ApprovalPrompt from './components/common/ApprovalPrompt.vue'
import BalancesCard from './components/wallet/BalancesCard.vue'
import AllowancesDropdown from './components/wallet/AllowancesDropdown.vue'
import OracleActionsDropdown from './components/wallet/OracleActionsDropdown.vue'
import MinerScannerCard from './components/miner/MinerScannerCard.vue'
import ClaimCard from './components/miner/ClaimCard.vue'
import MinerPricingCard from './components/miner/MinerPricingCard.vue'
import MiningStatsDropdown from './components/miner/MiningStatsDropdown.vue'
import StakingCard from './components/staking/StakingCard.vue'
import LiquidityCard from './components/liquidity/LiquidityCard.vue'
import SwapCard from './components/swap/SwapCard.vue'

import { ADDRESSES, TOKENS } from './contracts/addresses'
import { ME_BTC_ICON_URL } from './contracts/assets'
import { useWallet } from './composables/useWallet'
import { useBalances } from './composables/useBalances'
import { useAllowances } from './composables/useAllowances'
import { useApproveUSDC } from './composables/useApproveUSDC'
import { useOwnedMinerTokenIds } from './composables/useOwnedMinerTokenIds'
import { useMinerPreviews } from './composables/useMinerPreviews'
import { useClaimSelected } from './composables/useClaimSelected'
import { useMinerActions } from './composables/useMinerActions'
import { useWalletAutoRefresh } from './composables/useWalletAutoRefresh'
import { useMiningStats } from './composables/useMiningStats'
import { useStakeInfo } from './composables/useStakeInfo'
import { useStakeActions } from './composables/useStakeActions'
import { useMebtcAllowance } from './composables/useMebtcAllowance'
import { useApproveMebtc } from './composables/useApproveMebtc'
import { useMebtcUpgradeAllowance } from './composables/useMebtcUpgradeAllowance'
import { useApproveMebtcForMiner } from './composables/useApproveMebtcForMiner'
import { useMebtcManagerAllowance } from './composables/useMebtcManagerAllowance'
import { useApproveMebtcForManager } from './composables/useApproveMebtcForManager'
import { useRouterAllowances } from './composables/useRouterAllowances'
import { useApproveRouterTokens } from './composables/useApproveRouterTokens'
import { useAddLiquidity } from './composables/useAddLiquidity'
import { useRemoveLiquidity } from './composables/useRemoveLiquidity'
import { useLpPosition } from './composables/useLpPosition'
import { useMebtcPrice } from './composables/useMebtcPrice'
import { useSwap } from './composables/useSwap'
import { useOracleActions } from './composables/useOracleActions'
import { useUiRpcMonitoring } from './composables/useUiRpcMonitoring'

// wallet
const { isConnected, onChain } = useWallet()
useWalletAutoRefresh()

// balances
const { mebtc, payToken, loading: balancesLoading, mebtcDecimals, payTokenDecimals, payTokenSymbol } = useBalances()
const {
  priceUsdc: mebtcPriceUsdc,
  twapPriceText,
  poolPriceText,
  feePriceFresh
} = useMebtcPrice()
const {
  totalMined,
  totalStaked,
  feeVaultMebtc,
  demandVaultUsdc,
  poolMebtc,
  poolUsdc,
  totalEffectiveHash,
  soldMiners,
  firstMinerCreatedAt,
  intervalsSinceFirst,
  nextSlotInSeconds,
  loading: miningStatsLoading,
  error: miningStatsError
} = useMiningStats(1n)

// allowances
const {
  loading: allowancesLoading,
  allowanceMiner,
  allowanceManager,
  allowanceMinerText,
  allowanceManagerText
} = useAllowances()

const approveExactMissing = ref<bigint>(0n)
const approveExactValue = ref<bigint>(0n)

// approve (nur noch für MinerPricingCard nötig)
const {
  approveManagerExact,
  approveMinerExact,
  approveMinerMax,
  approveManagerMax
} = useApproveUSDC()

const {
  busy: actionBusy,
  error: actionError,
  lastTx: actionLastTx,
  maxBuyQtyPerTx,
  buyQueueStatus,
  maxBatchIdsPerTx,
  queueStatus: actionQueueStatus,
  buyFromModel,
  requestUpgradePower,
  requestUpgradeHash,
  requestUpgradePowerBatch,
  requestUpgradeHashBatch
} = useMinerActions()

const {
  busy: oracleBusy,
  error: oracleError,
  lastTx: oracleLastTx,
  executeEpoch
} = useOracleActions()

// miners
const { owned, busy: scanBusy, msg: scanMsg, error: scanError, rescan } = useOwnedMinerTokenIds()

// previews
const { previewMap } = useMinerPreviews(() => owned.value)

// claim
const {
  selected,
  busy: claimBusy,
  error: claimError,
  lastTx: claimLastTx,
  lastApproveTx,
  totalFeeSelected,
  maxIdsPerTx: claimMaxIdsPerTx,
  claimQueueStatus,
  claim
} = useClaimSelected({
  owned: () => owned.value,
  previewMap: () => previewMap.value
})

// staking
const {
  loading: stakeLoading,
  balance: stakedBalance,
  tier: stakeTier,
  unlockAt,
  hashBonusBps,
  powerBonusBps
} = useStakeInfo()

const {
  busy: stakeBusy,
  error: stakeError,
  lastTx: stakeLastTx,
  stake,
  unstake
} = useStakeActions()

const stakeInputError = ref('')

const {
  allowanceText: mebtcAllowanceText,
  allowance: mebtcAllowance,
  loading: mebtcAllowanceLoading
} = useMebtcAllowance()
const {
  allowanceText: mebtcUpgradeAllowanceText,
  allowance: mebtcUpgradeAllowance,
  loading: mebtcUpgradeAllowanceLoading
} = useMebtcUpgradeAllowance()
const {
  allowanceText: mebtcManagerAllowanceText,
  allowance: mebtcManagerAllowance,
  loading: mebtcManagerAllowanceLoading
} = useMebtcManagerAllowance()
const {
  approveMax: approveMebtcMax,
  approveExact: approveMebtcExact
} = useApproveMebtc()
const {
  approveMax: approveMebtcUpgradeMax,
  approveExact: approveMebtcUpgradeExact
} = useApproveMebtcForMiner()
const {
  approveMax: approveMebtcManagerMax,
  approveExact: approveMebtcManagerExact
} = useApproveMebtcForManager()

// liquidity
const {
  loading: routerAllowancesLoading,
  usdcAllowance,
  mebtcAllowance: routerMebtcAllowance,
  lpAllowance,
  usdcAllowanceText,
  mebtcAllowanceText: routerMebtcAllowanceText,
  lpAllowanceText
} = useRouterAllowances()
const {
  busy: approveRouterBusy,
  error: approveRouterError,
  lastTx: approveRouterLastTx,
  approveUsdc,
  approveMebtc,
  approveLp,
  approveUsdcExact: approveRouterUsdcExact,
  approveMebtcExact: approveRouterMebtcExact,
  approveLpExact: approveRouterLpExact
} = useApproveRouterTokens()
const {
  busy: addLiquidityBusy,
  error: addLiquidityError,
  lastTx: addLiquidityLastTx,
  submit: addLiquidity
} = useAddLiquidity()
const {
  busy: removeLiquidityBusy,
  error: removeLiquidityError,
  lastTx: removeLiquidityLastTx,
  submit: removeLiquidity
} = useRemoveLiquidity()
const {
  loading: lpPositionLoading,
  lpBalanceText,
  positionUsdcText,
  positionMebtcText,
  shareText
} = useLpPosition()
const {
  busy: swapBusy,
  error: swapError,
  lastTx: swapLastTx,
  submit: swapTokens
} = useSwap()

const mebtcAllowancesLoading = computed(() => {
  return mebtcAllowanceLoading.value || mebtcManagerAllowanceLoading.value || mebtcUpgradeAllowanceLoading.value
})

const upgradeCosts = ref<{ power: bigint; hash: bigint; mebtcShareBps: number }>({
  power: 0n,
  hash: 0n,
  mebtcShareBps: 0
})

type ApprovalPromptState = {
  tokenSymbol: string
  spenderLabel: string
  neededText: string
  allowanceText: string
  exactEnabled: boolean
  onApproveExact: () => Promise<void>
  onApproveMax: () => Promise<void>
  resolve: (ok: boolean) => void
}

const approvalPrompt = ref<ApprovalPromptState | null>(null)
const approvalPromptBusy = ref(false)
const approvalPromptError = ref('')

useUiRpcMonitoring([
  { context: 'mining-stats', error: miningStatsError },
  { context: 'miner-action', error: actionError },
  { context: 'oracle-action', error: oracleError },
  { context: 'miner-scan', error: scanError },
  { context: 'claim', error: claimError },
  { context: 'stake', error: stakeError },
  { context: 'router-approve', error: approveRouterError },
  { context: 'add-liquidity', error: addLiquidityError },
  { context: 'remove-liquidity', error: removeLiquidityError },
  { context: 'swap', error: swapError },
  { context: 'approval-prompt', error: approvalPromptError }
])

function formatAmount(amount: bigint, decimals: number) {
  return formatUnits(amount, decimals)
}

async function requestApproval(params: {
  tokenSymbol: string
  spenderLabel: string
  needed: bigint
  allowance: bigint
  decimals: number
  onApproveExact: () => Promise<void>
  onApproveMax: () => Promise<void>
  exactEnabled?: boolean
}) {
  if (params.needed <= params.allowance) return true

  return new Promise<boolean>((resolve) => {
    approvalPrompt.value = {
      tokenSymbol: params.tokenSymbol,
      spenderLabel: params.spenderLabel,
      neededText: formatAmount(params.needed, params.decimals),
      allowanceText: formatAmount(params.allowance, params.decimals),
      exactEnabled: params.exactEnabled ?? true,
      onApproveExact: params.onApproveExact,
      onApproveMax: params.onApproveMax,
      resolve
    }
    approvalPromptError.value = ''
  })
}

async function handleApprovalExact() {
  if (!approvalPrompt.value) return
  approvalPromptBusy.value = true
  approvalPromptError.value = ''
  try {
    await approvalPrompt.value.onApproveExact()
    approvalPrompt.value.resolve(true)
    approvalPrompt.value = null
  } catch (e: any) {
    approvalPromptError.value = e?.shortMessage ?? e?.message ?? String(e)
  } finally {
    approvalPromptBusy.value = false
  }
}

async function handleApprovalMax() {
  if (!approvalPrompt.value) return
  approvalPromptBusy.value = true
  approvalPromptError.value = ''
  try {
    await approvalPrompt.value.onApproveMax()
    approvalPrompt.value.resolve(true)
    approvalPrompt.value = null
  } catch (e: any) {
    approvalPromptError.value = e?.shortMessage ?? e?.message ?? String(e)
  } finally {
    approvalPromptBusy.value = false
  }
}

function handleApprovalCancel() {
  if (!approvalPrompt.value) return
  approvalPrompt.value.resolve(false)
  approvalPrompt.value = null
  approvalPromptError.value = ''
}

const approveManagerExactMissing = computed(() => {
  return totalFeeSelected.value > allowanceManager.value
    ? totalFeeSelected.value - allowanceManager.value
    : 0n
})

function setSelected(next: Record<string, boolean>) {
  selected.value = next
}

function setApproveStats(payload: { missing: bigint; endValue: bigint }) {
  approveExactMissing.value = payload.missing
  approveExactValue.value = payload.endValue
}

function setUpgradeCosts(payload: { power: bigint; hash: bigint; mebtcShareBps: number }) {
  upgradeCosts.value = payload
}

async function ensurePayTokenForMiner(needed: bigint) {
  return requestApproval({
    tokenSymbol: payTokenSymbol.value,
    spenderLabel: 'MinerNFT',
    needed,
    allowance: allowanceMiner.value,
    decimals: payTokenDecimals.value,
    onApproveExact: () => approveMinerExact(needed),
    onApproveMax: approveMinerMax
  })
}

async function ensurePayTokenForManager(needed: bigint) {
  return requestApproval({
    tokenSymbol: payTokenSymbol.value,
    spenderLabel: 'Manager',
    needed,
    allowance: allowanceManager.value,
    decimals: payTokenDecimals.value,
    onApproveExact: () => approveManagerExact(needed),
    onApproveMax: approveManagerMax
  })
}

async function ensureMebtcForStake(needed: bigint) {
  return requestApproval({
    tokenSymbol: TOKENS.mebtc.symbol,
    spenderLabel: 'StakeVault',
    needed,
    allowance: mebtcAllowance.value,
    decimals: TOKENS.mebtc.decimals,
    onApproveExact: () => approveMebtcExact(needed),
    onApproveMax: approveMebtcMax
  })
}

async function ensureMebtcForManager(needed: bigint, exactEnabled = true) {
  return requestApproval({
    tokenSymbol: TOKENS.mebtc.symbol,
    spenderLabel: 'Manager',
    needed,
    allowance: mebtcManagerAllowance.value,
    decimals: TOKENS.mebtc.decimals,
    onApproveExact: () => approveMebtcManagerExact(needed),
    onApproveMax: approveMebtcManagerMax,
    exactEnabled
  })
}

async function ensureMebtcForUpgrade(needed: bigint, exactEnabled = true) {
  return requestApproval({
    tokenSymbol: TOKENS.mebtc.symbol,
    spenderLabel: 'MinerNFT',
    needed,
    allowance: mebtcUpgradeAllowance.value,
    decimals: TOKENS.mebtc.decimals,
    onApproveExact: () => approveMebtcUpgradeExact(needed),
    onApproveMax: approveMebtcUpgradeMax,
    exactEnabled
  })
}

async function ensureRouterToken(needed: bigint, token: 'usdc' | 'mebtc' | 'lp') {
  const tokenSymbol = token === 'usdc' ? TOKENS.usdc.symbol : token === 'mebtc' ? TOKENS.mebtc.symbol : 'LP'
  const allowance = token === 'usdc' ? usdcAllowance.value : token === 'mebtc' ? routerMebtcAllowance.value : lpAllowance.value
  const decimals = token === 'usdc' ? TOKENS.usdc.decimals : token === 'mebtc' ? TOKENS.mebtc.decimals : 18
  const approveExact = token === 'usdc'
    ? () => approveRouterUsdcExact(needed)
    : token === 'mebtc'
      ? () => approveRouterMebtcExact(needed)
      : () => approveRouterLpExact(needed)
  const approveMax = token === 'usdc'
    ? approveUsdc
    : token === 'mebtc'
      ? approveMebtc
      : approveLp

  return requestApproval({
    tokenSymbol,
    spenderLabel: 'Router',
    needed,
    allowance,
    decimals,
    onApproveExact: approveExact,
    onApproveMax: approveMax
  })
}

function calcMebtcAmountFromUsdc(usdcAmount: bigint) {
  if (!mebtcPriceUsdc.value || mebtcPriceUsdc.value <= 0n) return null
  return (usdcAmount * 10n ** BigInt(TOKENS.mebtc.decimals)) / mebtcPriceUsdc.value
}

async function stakeFromInput(amount: string) {
  stakeInputError.value = ''
  const v = normalizeAmount(amount)
  if (!v) {
    stakeInputError.value = 'betrag fehlt'
    throw new Error('betrag fehlt')
  }
  let amt: bigint
  try {
    amt = parseUnits(v, mebtcDecimals ?? TOKENS.mebtc.decimals)
  } catch {
    stakeInputError.value = 'ungueltiges format (z. B. 10000 oder 10000.5)'
    throw new Error('format')
  }
  const ok = await ensureMebtcForStake(amt)
  if (!ok) return
  await stake(amt)
}

async function unstakeFromInput(amount: string) {
  stakeInputError.value = ''
  const v = normalizeAmount(amount)
  if (!v) {
    stakeInputError.value = 'betrag fehlt'
    throw new Error('betrag fehlt')
  }
  let amt: bigint
  try {
    amt = parseUnits(v, mebtcDecimals ?? TOKENS.mebtc.decimals)
  } catch {
    stakeInputError.value = 'ungueltiges format (z. B. 10000 oder 10000.5)'
    throw new Error('format')
  }
  await unstake(amt)
}

function normalizeAmount(raw: string) {
  let v = raw.trim()
  if (!v) return ''
  // remove any stray characters except digits and separators
  v = v.replace(/[^\d.,]/g, '')
  v = v.replace(/\s+/g, '')
  if (!v) return ''
  if (v.includes(',') && v.includes('.')) {
    // EU: 10.000,5 -> 10000.5
    return v.replace(/\./g, '').replace(',', '.')
  }
  if (v.includes(',')) {
    // 10,5 -> 10.5
    return v.replace(',', '.')
  }
  if (v.includes('.')) {
    const parts = v.split('.')
    if (parts.length > 2) {
      // multiple dots -> treat as thousands
      return parts.join('')
    }
    const last = parts[parts.length - 1]
    if (last && last.length === 3 && parts.every(p => /^\d+$/.test(p))) {
      return parts.join('')
    }
  }
  return v
}

function parseAmountOrThrow(raw: string, decimals: number, label: string) {
  const v = normalizeAmount(raw)
  if (!v) throw new Error(`${label} fehlt`)
  return parseUnits(v, decimals)
}

async function buyFromModelWithApproval(modelId: number, qty: number) {
  if (approveExactMissing.value > 0n) {
    const ok = await ensurePayTokenForMiner(approveExactValue.value)
    if (!ok) return
  }
  await buyFromModel(modelId, qty)
}

async function upgradePowerWithApproval(tokenId: bigint, mebtcShareBps: number) {
  const cost = upgradeCosts.value.power
  if (cost > 0n) {
    const share = Math.max(0, Math.min(3000, Math.floor(mebtcShareBps)))
    const mebtcUsdc = (cost * BigInt(share)) / 10_000n
    const usdcPart = cost - mebtcUsdc
    if (usdcPart > 0n) {
      const ok = await ensurePayTokenForMiner(usdcPart)
      if (!ok) return
    }
    if (share > 0) {
      const mebtcAmount = calcMebtcAmountFromUsdc(mebtcUsdc)
      if (mebtcAmount && mebtcAmount > 0n) {
        const ok = await ensureMebtcForUpgrade(mebtcAmount)
        if (!ok) return
      }
    }
  }
  await requestUpgradePower(tokenId, mebtcShareBps)
}

async function upgradeHashWithApproval(tokenId: bigint, mebtcShareBps: number) {
  const cost = upgradeCosts.value.hash
  if (cost > 0n) {
    const share = Math.max(0, Math.min(3000, Math.floor(mebtcShareBps)))
    const mebtcUsdc = (cost * BigInt(share)) / 10_000n
    const usdcPart = cost - mebtcUsdc
    if (usdcPart > 0n) {
      const ok = await ensurePayTokenForMiner(usdcPart)
      if (!ok) return
    }
    if (share > 0) {
      const mebtcAmount = calcMebtcAmountFromUsdc(mebtcUsdc)
      if (mebtcAmount && mebtcAmount > 0n) {
        const ok = await ensureMebtcForUpgrade(mebtcAmount)
        if (!ok) return
      }
    }
  }
  await requestUpgradeHash(tokenId, mebtcShareBps)
}

async function upgradePowerBatchWithApproval(tokenIds: bigint[], mebtcShareBps: number, totalCost: bigint) {
  if (!tokenIds.length) throw new Error('keine tokenIds')
  const cost = totalCost
  if (cost > 0n) {
    const share = Math.max(0, Math.min(3000, Math.floor(mebtcShareBps)))
    const mebtcUsdc = (cost * BigInt(share)) / 10_000n
    const usdcPart = cost - mebtcUsdc
    if (usdcPart > 0n) {
      const ok = await ensurePayTokenForMiner(usdcPart)
      if (!ok) return
    }
    if (share > 0) {
      const mebtcAmount = calcMebtcAmountFromUsdc(mebtcUsdc)
      if (mebtcAmount && mebtcAmount > 0n) {
        const ok = await ensureMebtcForUpgrade(mebtcAmount)
        if (!ok) return
      }
    }
  }
  await requestUpgradePowerBatch(tokenIds, mebtcShareBps)
}

async function upgradeHashBatchWithApproval(tokenIds: bigint[], mebtcShareBps: number, totalCost: bigint) {
  if (!tokenIds.length) throw new Error('keine tokenIds')
  const cost = totalCost
  if (cost > 0n) {
    const share = Math.max(0, Math.min(3000, Math.floor(mebtcShareBps)))
    const mebtcUsdc = (cost * BigInt(share)) / 10_000n
    const usdcPart = cost - mebtcUsdc
    if (usdcPart > 0n) {
      const ok = await ensurePayTokenForMiner(usdcPart)
      if (!ok) return
    }
    if (share > 0) {
      const mebtcAmount = calcMebtcAmountFromUsdc(mebtcUsdc)
      if (mebtcAmount && mebtcAmount > 0n) {
        const ok = await ensureMebtcForUpgrade(mebtcAmount)
        if (!ok) return
      }
    }
  }
  await requestUpgradeHashBatch(tokenIds, mebtcShareBps)
}

async function claimWithApproval(mebtcShareBps: number) {
  const fee = totalFeeSelected.value
  const share = Math.max(0, Math.min(3000, Math.floor(mebtcShareBps)))
  const mebtcUsdc = (fee * BigInt(share)) / 10_000n
  const usdcPart = fee - mebtcUsdc

  if (usdcPart > 0n) {
    const ok = await ensurePayTokenForManager(usdcPart)
    if (!ok) return
  }

  if (share > 0) {
    const mebtcAmount = calcMebtcAmountFromUsdc(mebtcUsdc)
    if (mebtcAmount && mebtcAmount > 0n) {
      const ok = await ensureMebtcForManager(mebtcAmount)
      if (!ok) return
    }
  }

  await claim(mebtcShareBps)
}

async function addLiquidityWithApproval(usdcAmount: string, mebtcAmount: string) {
  const usdcParsed = parseAmountOrThrow(usdcAmount, TOKENS.usdc.decimals, 'USDC')
  const mebtcParsed = parseAmountOrThrow(mebtcAmount, TOKENS.mebtc.decimals, 'MeBTC')

  const okUsdc = await ensureRouterToken(usdcParsed, 'usdc')
  if (!okUsdc) return
  const okMebtc = await ensureRouterToken(mebtcParsed, 'mebtc')
  if (!okMebtc) return

  await addLiquidity(normalizeAmount(usdcAmount), normalizeAmount(mebtcAmount))
}

async function removeLiquidityWithApproval(lpAmount: string) {
  const lpParsed = parseAmountOrThrow(lpAmount, 18, 'LP')
  const okLp = await ensureRouterToken(lpParsed, 'lp')
  if (!okLp) return
  await removeLiquidity(normalizeAmount(lpAmount))
}

async function swapWithApproval(params: { direction: 'buy' | 'sell'; amountIn: string; minOut?: string }) {
  const decimals = params.direction === 'buy' ? TOKENS.usdc.decimals : TOKENS.mebtc.decimals
  const parsed = parseAmountOrThrow(params.amountIn, decimals, 'amount')
  const token = params.direction === 'buy' ? 'usdc' : 'mebtc'
  const ok = await ensureRouterToken(parsed, token)
  if (!ok) return
  await swapTokens(params)
}

const headerMeta = computed(() => {
  const twapText = twapPriceText.value === '-' ? '-' : `${twapPriceText.value} USDC`
  const poolText = poolPriceText.value === '-' ? '-' : `${poolPriceText.value} USDC`
  const feeFreshText = feePriceFresh.value ? 'ja' : 'nein'
  const priceValue = `Pool: ${poolText} | TWAP: ${twapText} | Fee fresh: ${feeFreshText}`
  const priceInfo = [
    'Pool Price: aktueller Spotpreis aus den Pair-Reserven (USDC/MeBTC). Reagiert sofort auf Trades.',
    'TWAP: zeitgewichteter Durchschnittspreis aus dem Oracle-Fenster. Stabiler, weniger sprunghaft.',
    'TWAP-Update: passiert bei Claim/Upgrade (max. alle 2h).',
    'Fee-Berechnung: Wenn Fee fresh = ja, wird TWAP fuer Gebühren genutzt; sonst Fallback auf Pool Price.'
  ].join('\n')
  return [
    { label: 'MeBTC', value: ADDRESSES.mebtc },
    { label: 'MinerNFT', value: ADDRESSES.minerNft },
    { label: 'Manager', value: ADDRESSES.miningManager },
    { label: 'Pair (USDC/MeBTC)', value: ADDRESSES.pair },
    { label: 'MeBTC price', value: priceValue, info: priceInfo }
  ]
})
</script>

<template>
  <div class="app-root">
    <main class="app-main">
      <Header
        title="MeBTC Dashboard"
        :meta="headerMeta"
        :iconUrl="ME_BTC_ICON_URL"
      >
        <template #right>
          <div class="ui-stack">
            <ThemeToggle />
            <div class="control-stack control-stack-grid">
              <div class="control-cell">
                <div class="ui-subtitle">Status</div>
                <MiningStatsDropdown
                  :totalMined="totalMined"
                  :totalStaked="totalStaked"
                  :feeVaultMebtc="feeVaultMebtc"
                  :demandVaultUsdc="demandVaultUsdc"
                  :poolMebtc="poolMebtc"
                  :poolUsdc="poolUsdc"
                  :totalEffectiveHash="totalEffectiveHash"
                  :soldMiners="soldMiners"
                  :mebtcDecimals="mebtcDecimals"
                  :firstMinerCreatedAt="firstMinerCreatedAt"
                  :blockTime="intervalsSinceFirst"
                  :nextSlotInSeconds="nextSlotInSeconds"
                  :loading="miningStatsLoading"
                  :error="miningStatsError"
                />
              </div>
              <div class="control-cell">
                <div class="ui-subtitle">Approvals</div>
                <AllowancesDropdown
                  :disabled="!isConnected || !onChain"
                  :loading="allowancesLoading"
                  :minerText="allowanceMinerText()"
                  :managerText="allowanceManagerText()"
                  :payTokenSymbol="payTokenSymbol"
                  :payTokenDecimals="payTokenDecimals"
                  :approveExactMissing="approveExactMissing"
                  :approveManagerExactMissing="approveManagerExactMissing"
                  :routerLoading="routerAllowancesLoading"
                  :routerUsdcAllowanceText="usdcAllowanceText()"
                  :routerMebtcAllowanceText="routerMebtcAllowanceText()"
                  :routerLpAllowanceText="lpAllowanceText()"
                  :mebtcLoading="mebtcAllowancesLoading"
                  :mebtcStakeAllowanceText="mebtcAllowanceText()"
                  :mebtcManagerAllowanceText="mebtcManagerAllowanceText()"
                  :mebtcUpgradeAllowanceText="mebtcUpgradeAllowanceText()"
                />
              </div>
              <div class="control-cell">
                <div class="ui-subtitle">Tools</div>
                <MinerScannerCard
                  :disabled="!isConnected || !onChain"
                  :busy="scanBusy"
                  :msg="scanMsg"
                  :error="scanError"
                  :owned="owned"
                  :onScan="rescan"
                  compact
                />
              </div>
              <div class="control-cell control-cell-critical">
                <div class="ui-subtitle">Protocol</div>
                <OracleActionsDropdown
                  :disabled="!isConnected || !onChain"
                  :busy="oracleBusy"
                  :error="oracleError"
                  :lastTx="oracleLastTx"
                  :onExecuteEpoch="executeEpoch"
                />
              </div>
            </div>
          </div>
        </template>
      </Header>

      <div v-if="!isConnected" class="notice">
        wallet nicht verbunden (oben rechts verbinden)
      </div>

      <div v-else-if="!onChain" class="notice">
        falsches netzwerk. bitte avalanche fuji auswählen
      </div>

      <div class="section-grid">
        <BalancesCard
          class="grid-span-2"
          :mebtc="mebtc"
          :payToken="payToken"
          :loading="balancesLoading"
          :mebtcDecimals="mebtcDecimals"
          :payTokenDecimals="payTokenDecimals"
          :payTokenSymbol="payTokenSymbol"
          :disabled="!isConnected || !onChain"
          :owned="owned"
          :stakeTier="stakeTier"
          :hashBonusBps="hashBonusBps"
          :powerBonusBps="powerBonusBps"
        />

        <ClaimCard
          class="grid-span-2"
          :disabled="!isConnected || !onChain"
          :owned="owned"
          :previewMap="previewMap"
          :selected="selected"
          :setSelected="setSelected"
          :busy="claimBusy"
          :error="claimError"
          :lastTx="claimLastTx"
          :lastApproveTx="lastApproveTx"
          :totalFeeSelected="totalFeeSelected"
          :allowanceManagerText="allowanceManagerText()"
          :mebtcAllowanceText="mebtcManagerAllowanceText()"
          :payTokenSymbol="payTokenSymbol"
          :payTokenDecimals="payTokenDecimals"
          :maxIdsPerTx="claimMaxIdsPerTx"
          :claimQueueStatus="claimQueueStatus"
          :onClaim="claimWithApproval"
        />

        <MinerPricingCard
          class="grid-span-2"
          :disabled="!isConnected || !onChain"
          :allowanceMiner="allowanceMiner"
          :actionBusy="actionBusy"
          :actionError="actionError"
          :actionLastTx="actionLastTx"
          :onBuyModel="buyFromModelWithApproval"
          :onUpgradePower="upgradePowerWithApproval"
          :onUpgradeHash="upgradeHashWithApproval"
          :onUpgradePowerBatch="upgradePowerBatchWithApproval"
          :onUpgradeHashBatch="upgradeHashBatchWithApproval"
          :mebtcUpgradeAllowanceText="mebtcUpgradeAllowanceText()"
          :payTokenSymbol="payTokenSymbol"
          :payTokenDecimals="payTokenDecimals"
          :owned="owned"
          :maxBuyQtyPerTx="maxBuyQtyPerTx"
          :buyQueueStatus="buyQueueStatus"
          :maxBatchIdsPerTx="maxBatchIdsPerTx"
          :batchQueueStatus="actionQueueStatus"
          @approve-stats="setApproveStats"
          @upgrade-costs="setUpgradeCosts"
        />

        <SwapCard
          class="grid-span-2"
          :disabled="!isConnected || !onChain"
          :busy="swapBusy || approveRouterBusy"
          :error="swapError || approveRouterError"
          :lastTx="swapLastTx || approveRouterLastTx"
          :poolUsdc="poolUsdc"
          :poolMebtc="poolMebtc"
          :usdcBalance="payToken"
          :mebtcBalance="mebtc"
          :onSwap="swapWithApproval"
        />

        <LiquidityCard
          class="grid-span-2"
          :disabled="!isConnected || !onChain"
          :busy="addLiquidityBusy || removeLiquidityBusy || approveRouterBusy || routerAllowancesLoading || lpPositionLoading"
          :error="addLiquidityError || removeLiquidityError || approveRouterError"
          :lastTx="addLiquidityLastTx || removeLiquidityLastTx || approveRouterLastTx"
          :lpBalanceText="lpBalanceText()"
          :lpPositionUsdcText="positionUsdcText()"
          :lpPositionMebtcText="positionMebtcText()"
          :lpShareText="shareText()"
          :poolUsdc="poolUsdc"
          :poolMebtc="poolMebtc"
          :onAddLiquidity="addLiquidityWithApproval"
          :onRemoveLiquidity="removeLiquidityWithApproval"
        />

        <StakingCard
          class="grid-span-2"
          :disabled="!isConnected || !onChain"
          :busy="stakeBusy || stakeLoading"
          :error="stakeError"
          :lastTx="stakeLastTx"
          :allowanceText="mebtcAllowanceText()"
          :stakedBalance="stakedBalance"
          :tier="stakeTier"
          :unlockAt="unlockAt"
          :hashBonusBps="hashBonusBps"
          :powerBonusBps="powerBonusBps"
          :mebtcDecimals="mebtcDecimals"
          :inputError="stakeInputError"
          :onStake="stakeFromInput"
          :onUnstake="unstakeFromInput"
        />
      </div>

      <ApprovalPrompt
        :open="!!approvalPrompt"
        :tokenSymbol="approvalPrompt?.tokenSymbol ?? ''"
        :spenderLabel="approvalPrompt?.spenderLabel ?? ''"
        :neededText="approvalPrompt?.neededText ?? ''"
        :allowanceText="approvalPrompt?.allowanceText ?? ''"
        :exactEnabled="approvalPrompt?.exactEnabled ?? false"
        :busy="approvalPromptBusy"
        :error="approvalPromptError"
        :onApproveExact="handleApprovalExact"
        :onApproveMax="handleApprovalMax"
        :onCancel="handleApprovalCancel"
      />
    </main>
  </div>
</template>
