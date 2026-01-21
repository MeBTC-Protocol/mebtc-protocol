<script setup lang="ts">
import { computed, ref } from 'vue'
import { parseUnits } from 'ethers'
import Header from './components/layout/Header.vue'
import ThemeToggle from './components/common/ThemeToggle.vue'
import WalletCard from './components/wallet/WalletCard.vue'
import BalancesCard from './components/wallet/BalancesCard.vue'
import MinerScannerCard from './components/miner/MinerScannerCard.vue'
import ClaimCard from './components/miner/ClaimCard.vue'
import MinerPricingCard from './components/miner/MinerPricingCard.vue'
import NewsCard from './components/news/NewsCard.vue'
import MiningStatsDropdown from './components/miner/MiningStatsDropdown.vue'
import StakingCard from './components/staking/StakingCard.vue'
import LiquidityCard from './components/liquidity/LiquidityCard.vue'

import { ADDRESSES } from './contracts/addresses'
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

// wallet
const { isConnected, address, chainId, onChain } = useWallet()
useWalletAutoRefresh()

// balances
const { mebtc, payToken, loading: balancesLoading, mebtcDecimals, payTokenDecimals, payTokenSymbol } = useBalances()
const { priceText: mebtcPriceText, sourceText: mebtcPriceSource } = useMebtcPrice()
const {
  totalMined,
  totalStaked,
  feeVaultMebtc,
  demandVaultUsdc,
  poolMebtc,
  poolUsdc,
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
  busy: approveBusy,
  error: approveError,
  lastTx: approveLastTx,
  approveManagerExact,
  approveMinerExact,
  approveMinerMax,
  approveManagerMax
} = useApproveUSDC()

const {
  busy: actionBusy,
  error: actionError,
  lastTx: actionLastTx,
  buyFromModel,
  requestUpgradePower,
  requestUpgradeHash
} = useMinerActions()

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

const { allowanceText: mebtcAllowanceText } = useMebtcAllowance()
const { allowanceText: mebtcUpgradeAllowanceText } = useMebtcUpgradeAllowance()
const { allowanceText: mebtcManagerAllowanceText } = useMebtcManagerAllowance()
const {
  busy: approveMebtcBusy,
  error: approveMebtcError,
  lastTx: approveMebtcLastTx,
  approveMax: approveMebtcMax
} = useApproveMebtc()
const {
  busy: approveMebtcUpgradeBusy,
  error: approveMebtcUpgradeError,
  lastTx: approveMebtcUpgradeLastTx,
  approveMax: approveMebtcUpgradeMax
} = useApproveMebtcForMiner()
const {
  busy: approveMebtcManagerBusy,
  error: approveMebtcManagerError,
  lastTx: approveMebtcManagerLastTx,
  approveMax: approveMebtcManagerMax
} = useApproveMebtcForManager()

// liquidity
const {
  loading: routerAllowancesLoading,
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
  approveLp
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

const approveManagerExactMissing = computed(() => {
  return totalFeeSelected.value > allowanceManager.value
    ? totalFeeSelected.value - allowanceManager.value
    : 0n
})
const approveManagerExactValue = computed(() => {
  return allowanceManager.value + approveManagerExactMissing.value
})

const newsItems = ref([
  {
    title: 'Dashboard update',
    summary: 'News sidebar added for quick updates.',
    date: '2024-05-12'
  },
  {
    title: 'Fuji maintenance',
    summary: 'Possible delays in transactions during scheduled downtime.'
  }
])

function setSelected(next: Record<string, boolean>) {
  selected.value = next
}

function setApproveStats(payload: { missing: bigint; endValue: bigint }) {
  approveExactMissing.value = payload.missing
  approveExactValue.value = payload.endValue
}

async function stakeFromInput(amount: string) {
  const v = amount.trim()
  if (!v) throw new Error('betrag fehlt')
  const amt = parseUnits(v, mebtcDecimals.value ?? TOKENS.mebtc.decimals)
  await stake(amt)
}

async function unstakeFromInput(amount: string) {
  const v = amount.trim()
  if (!v) throw new Error('betrag fehlt')
  const amt = parseUnits(v, mebtcDecimals.value ?? TOKENS.mebtc.decimals)
  await unstake(amt)
}

const headerMeta = computed(() => {
  const priceValue = mebtcPriceText.value === '-'
    ? '-'
    : `${mebtcPriceText.value} USDC (${mebtcPriceSource.value})`
  return [
    { label: 'MinerNFT', value: ADDRESSES.minerNft },
    { label: 'Manager', value: ADDRESSES.miningManager },
    { label: 'MeBTC price', value: priceValue }
  ]
})
</script>

<template>
  <div class="app-root">
    <div class="app-shell">
      <aside class="app-aside">
        <div class="app-aside-inner">
          <NewsCard :items="newsItems" />
        </div>
      </aside>

      <main class="app-main">
        <Header
          title="MeBTC Dashboard"
          :meta="headerMeta"
          :iconUrl="ME_BTC_ICON_URL"
        >
          <template #right>
            <div class="ui-stack">
              <ThemeToggle />
              <div class="control-stack">
                <div class="ui-stack" style="min-width:220px;">
                  <MinerScannerCard
                    :disabled="!isConnected || !onChain"
                    :busy="scanBusy"
                    :msg="scanMsg"
                    :error="scanError"
                    :owned="owned"
                    :onScan="rescan"
                    compact
                  />
                  <MiningStatsDropdown
                    :totalMined="totalMined"
                    :totalStaked="totalStaked"
                    :feeVaultMebtc="feeVaultMebtc"
                    :demandVaultUsdc="demandVaultUsdc"
                    :poolMebtc="poolMebtc"
                    :poolUsdc="poolUsdc"
                    :soldMiners="soldMiners"
                    :mebtcDecimals="mebtcDecimals"
                    :firstMinerCreatedAt="firstMinerCreatedAt"
                    :blockTime="intervalsSinceFirst"
                    :nextSlotInSeconds="nextSlotInSeconds"
                    :loading="miningStatsLoading"
                    :error="miningStatsError"
                  />
                </div>
                <WalletCard :connected="isConnected" :address="address" :chainId="chainId" :onChain="onChain" />
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
            :allowancesLoading="allowancesLoading"
            :allowancesBusy="approveBusy"
            :allowanceMinerText="allowanceMinerText()"
            :allowanceManagerText="allowanceManagerText()"
            :approveError="approveError"
            :approveLastTx="approveLastTx"
            :onApproveMiner="approveMinerMax"
            :onApproveManager="approveManagerMax"
            :approveExactMissing="approveExactMissing"
            :approveExactValue="approveExactValue"
            :onApproveExact="approveMinerExact"
            :approveManagerExactMissing="approveManagerExactMissing"
            :approveManagerExactValue="approveManagerExactValue"
            :onApproveManagerExact="approveManagerExact"
          />

          <MinerPricingCard
            :disabled="!isConnected || !onChain"
            :allowanceMiner="allowanceMiner"
            :approveBusy="approveBusy"
            :approveError="approveError"
            :approveLastTx="approveLastTx"
            :actionBusy="actionBusy"
            :actionError="actionError"
            :actionLastTx="actionLastTx"
            :onApproveExact="approveMinerExact"
            :onBuyModel="buyFromModel"
            :onUpgradePower="requestUpgradePower"
            :onUpgradeHash="requestUpgradeHash"
            :onApproveMebtcUpgrade="approveMebtcUpgradeMax"
            :mebtcUpgradeAllowanceText="mebtcUpgradeAllowanceText()"
            :mebtcUpgradeApproveBusy="approveMebtcUpgradeBusy"
            :mebtcUpgradeApproveError="approveMebtcUpgradeError"
            :mebtcUpgradeApproveLastTx="approveMebtcUpgradeLastTx"
            :payTokenSymbol="payTokenSymbol"
            :payTokenDecimals="payTokenDecimals"
            :owned="owned"
            @approve-stats="setApproveStats"
          />

          <StakingCard
            class="grid-col-2"
            :disabled="!isConnected || !onChain"
            :busy="stakeBusy || approveMebtcBusy || stakeLoading"
            :error="stakeError || approveMebtcError"
            :lastTx="stakeLastTx || approveMebtcLastTx"
            :allowanceText="mebtcAllowanceText()"
            :stakedBalance="stakedBalance"
            :tier="stakeTier"
            :unlockAt="unlockAt"
            :hashBonusBps="hashBonusBps"
            :powerBonusBps="powerBonusBps"
            :mebtcDecimals="mebtcDecimals"
            :onApprove="approveMebtcMax"
            :onStake="stakeFromInput"
            :onUnstake="unstakeFromInput"
          />

          <LiquidityCard
            :disabled="!isConnected || !onChain"
            :busy="addLiquidityBusy || removeLiquidityBusy || approveRouterBusy || routerAllowancesLoading || lpPositionLoading"
            :error="addLiquidityError || removeLiquidityError || approveRouterError"
            :lastTx="addLiquidityLastTx || removeLiquidityLastTx || approveRouterLastTx"
            :usdcAllowanceText="usdcAllowanceText()"
            :mebtcAllowanceText="routerMebtcAllowanceText()"
            :lpAllowanceText="lpAllowanceText()"
            :lpBalanceText="lpBalanceText()"
            :lpPositionUsdcText="positionUsdcText()"
            :lpPositionMebtcText="positionMebtcText()"
            :lpShareText="shareText()"
            :onApproveUsdc="approveUsdc"
            :onApproveMebtc="approveMebtc"
            :onApproveLp="approveLp"
            :onAddLiquidity="addLiquidity"
            :onRemoveLiquidity="removeLiquidity"
          />

          <ClaimCard
            class="grid-col-2"
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
            :mebtcApproveBusy="approveMebtcManagerBusy"
            :mebtcApproveError="approveMebtcManagerError"
            :mebtcApproveLastTx="approveMebtcManagerLastTx"
            :payTokenSymbol="payTokenSymbol"
            :payTokenDecimals="payTokenDecimals"
            :onApproveMebtc="approveMebtcManagerMax"
            :onClaim="claim"
          />
        </div>
      </main>
    </div>
  </div>
</template>
