<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import Header from './components/layout/Header.vue'
import ThemeToggle from './components/common/ThemeToggle.vue'
import WalletCard from './components/wallet/WalletCard.vue'
import BalancesCard from './components/wallet/BalancesCard.vue'
import AllowancesDropdown from './components/wallet/AllowancesDropdown.vue'
import MinerScannerCard from './components/miner/MinerScannerCard.vue'
import MinerPricingCard from './components/miner/MinerPricingCard.vue'
import ExternalClaimCard from './components/miner/ExternalClaimCard.vue'
import NewsCard from './components/news/NewsCard.vue'
import MiningStatsDropdown from './components/miner/MiningStatsDropdown.vue'
import StakingCard from './components/staking/StakingCard.vue'
import LiquidityCard from './components/liquidity/LiquidityCard.vue'
import SwapCard from './components/swap/SwapCard.vue'

import { ADDRESSES } from './contracts/addresses'
import { ME_BTC_ICON_URL } from './contracts/assets'
import { TARGET_CHAIN } from './contracts/chain'
import { useWallet } from './composables/useWallet'
import { useBalances } from './composables/useBalances'
import { useAllowances } from './composables/useAllowances'
import { useOwnedMinerTokenIds } from './composables/useOwnedMinerTokenIds'
import { useMinerPreviews } from './composables/useMinerPreviews'
import { useWalletAutoRefresh } from './composables/useWalletAutoRefresh'
import { useMiningStats } from './composables/useMiningStats'
import { useStakeInfo } from './composables/useStakeInfo'
import { useMebtcAllowance } from './composables/useMebtcAllowance'
import { useMebtcUpgradeAllowance } from './composables/useMebtcUpgradeAllowance'
import { useMebtcManagerAllowance } from './composables/useMebtcManagerAllowance'
import { useRouterAllowances } from './composables/useRouterAllowances'
import { useLpPosition } from './composables/useLpPosition'
import { useMebtcPrice } from './composables/useMebtcPrice'

// wallet
const { isConnected, address, chainId, onChain } = useWallet()
useWalletAutoRefresh()

// balances
const {
  mebtc,
  payToken,
  loading: balancesLoading,
  mebtcDecimals,
  payTokenDecimals,
  payTokenSymbol,
  payTokenAddress
} = useBalances()
const { priceUsdc: mebtcPriceUsdc, priceText: mebtcPriceText, sourceText: mebtcPriceSource } = useMebtcPrice()
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

// allowances (read-only)
const {
  loading: allowancesLoading,
  allowanceMiner,
  allowanceManager,
  allowanceMinerText,
  allowanceManagerText
} = useAllowances()

// miners
const { owned, busy: scanBusy, msg: scanMsg, error: scanError, rescan } = useOwnedMinerTokenIds()

// previews
const { previewMap } = useMinerPreviews(() => owned.value)

// selection (read-only)
const selected = ref<Record<string, boolean>>({})
watch(
  () => owned.value.map(id => id.toString()),
  () => {
    const next: Record<string, boolean> = {}
    for (const id of owned.value) {
      const k = id.toString()
      next[k] = selected.value[k] ?? true
    }
    selected.value = next
  },
  { immediate: true }
)

const selectedIds = computed(() => {
  return owned.value.filter(id => selected.value[id.toString()])
})

const totalFeeSelected = computed(() => {
  const m = previewMap.value
  let sum = 0n
  for (const id of selectedIds.value) {
    const p = m.get(id.toString())
    if (p) sum += p.fee
  }
  return sum
})

// staking info (read-only)
const {
  balance: stakedBalance,
  tier: stakeTier,
  unlockAt,
  hashBonusBps,
  powerBonusBps
} = useStakeInfo()

const {
  allowanceText: mebtcAllowanceText,
  loading: mebtcAllowanceLoading
} = useMebtcAllowance()
const {
  allowanceText: mebtcUpgradeAllowanceText,
  loading: mebtcUpgradeAllowanceLoading
} = useMebtcUpgradeAllowance()
const {
  allowanceText: mebtcManagerAllowanceText,
  loading: mebtcManagerAllowanceLoading
} = useMebtcManagerAllowance()

// router allowances (read-only)
const {
  loading: routerAllowancesLoading,
  usdcAllowanceText,
  mebtcAllowanceText: routerMebtcAllowanceText,
  lpAllowanceText
} = useRouterAllowances()

const {
  lpBalance,
  positionUsdc,
  positionMebtc,
  lpBalanceText,
  positionUsdcText,
  positionMebtcText,
  shareText
} = useLpPosition()

const mebtcAllowancesLoading = computed(() => {
  return mebtcAllowanceLoading.value || mebtcManagerAllowanceLoading.value || mebtcUpgradeAllowanceLoading.value
})

const approveExactMissing = ref<bigint>(0n)
const approveManagerExactMissing = computed(() => {
  const diff = totalFeeSelected.value - allowanceManager.value
  return diff > 0n ? diff : 0n
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
                <div class="ui-stack">
                  <WalletCard :connected="isConnected" :address="address" :chainId="chainId" :onChain="onChain" />
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

          <MinerPricingCard
            :disabled="!isConnected || !onChain"
            :allowanceMiner="allowanceMiner"
            :payTokenSymbol="payTokenSymbol"
            :payTokenDecimals="payTokenDecimals"
            :mebtcDecimals="mebtcDecimals"
            :mebtcPriceUsdc="mebtcPriceUsdc ?? 0n"
            :owned="owned"
            :payTokenAddress="payTokenAddress"
            :minerNftAddress="ADDRESSES.minerNft"
            :blockExplorerBase="TARGET_CHAIN.blockExplorer"
          />

          <StakingCard
            class="grid-col-2"
            :disabled="!isConnected || !onChain"
            :allowanceText="mebtcAllowanceText()"
            :stakedBalance="stakedBalance"
            :tier="stakeTier"
            :unlockAt="unlockAt"
            :hashBonusBps="hashBonusBps"
            :powerBonusBps="powerBonusBps"
            :mebtcDecimals="mebtcDecimals"
            :stakeVaultAddress="ADDRESSES.stakeVault"
            :blockExplorerBase="TARGET_CHAIN.blockExplorer"
            :userAddress="address ?? ''"
          />

          <LiquidityCard
            :disabled="!isConnected || !onChain"
            :lpBalanceText="lpBalanceText()"
            :lpPositionUsdcText="positionUsdcText()"
            :lpPositionMebtcText="positionMebtcText()"
            :lpShareText="shareText()"
            :poolUsdc="poolUsdc"
            :poolMebtc="poolMebtc"
            :lpBalance="lpBalance"
            :positionUsdc="positionUsdc"
            :positionMebtc="positionMebtc"
            :userAddress="address ?? ''"
            :routerAddress="ADDRESSES.router"
            :pairAddress="ADDRESSES.pair"
            :blockExplorerBase="TARGET_CHAIN.blockExplorer"
          />

          <SwapCard
            :disabled="!isConnected || !onChain"
            :poolUsdc="poolUsdc"
            :poolMebtc="poolMebtc"
            :usdcBalance="payToken"
            :mebtcBalance="mebtc"
            :userAddress="address ?? ''"
            :routerAddress="ADDRESSES.router"
            :blockExplorerBase="TARGET_CHAIN.blockExplorer"
          />

          <ExternalClaimCard
            class="grid-col-2"
            :disabled="!isConnected || !onChain"
            :owned="owned"
            :previewMap="previewMap"
            :selected="selected"
            :setSelected="setSelected"
            :totalFeeSelected="totalFeeSelected"
            :allowanceManagerText="allowanceManagerText()"
            :payTokenSymbol="payTokenSymbol"
            :payTokenDecimals="payTokenDecimals"
            :payTokenAddress="payTokenAddress"
            :miningManagerAddress="ADDRESSES.miningManager"
            :blockExplorerBase="TARGET_CHAIN.blockExplorer"
          />
        </div>
      </main>
    </div>
  </div>
</template>
