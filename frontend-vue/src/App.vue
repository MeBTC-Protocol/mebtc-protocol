<script setup lang="ts">
import { computed, ref } from 'vue'
import Header from './components/layout/Header.vue'
import WalletCard from './components/wallet/WalletCard.vue'
import BalancesCard from './components/wallet/BalancesCard.vue'
import MinerScannerCard from './components/miner/MinerScannerCard.vue'
import ClaimCard from './components/miner/ClaimCard.vue'
import MinerPricingCard from './components/miner/MinerPricingCard.vue'
import NewsCard from './components/news/NewsCard.vue'
import MiningStatsDropdown from './components/miner/MiningStatsDropdown.vue'

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

// wallet
const { isConnected, address, chainId, onChain } = useWallet()
useWalletAutoRefresh()

// balances
const { mebtc, usdc, loading: balancesLoading, mebtcDecimals, usdcDecimals } = useBalances()
const {
  totalMined,
  soldMiners,
  firstMinerCreatedAt,
  intervalsSinceFirst,
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
</script>

<template>
  <div style="max-width:1150px;margin:0 auto;padding:16px;font-family:ui-sans-serif,system-ui;">
    <Header
      title="MeBTC Dashboard"
      :subtitle="`MinerNFT: ${ADDRESSES.minerNft}\nManager: ${ADDRESSES.miningManager}`"
      :iconUrl="ME_BTC_ICON_URL"
    >
      <template #right>
        <div style="min-width:220px;">
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
        <div style="display:flex;flex-direction:column;gap:8px;align-items:flex-start;">
          <WalletCard :connected="isConnected" :address="address" :chainId="chainId" :onChain="onChain" />
          <MiningStatsDropdown
            :totalMined="totalMined"
            :soldMiners="soldMiners"
            :mebtcDecimals="mebtcDecimals"
            :firstMinerCreatedAt="firstMinerCreatedAt"
            :blockTime="intervalsSinceFirst"
            :loading="miningStatsLoading"
            :error="miningStatsError"
          />
        </div>
      </template>
    </Header>

    <div v-if="!isConnected" style="margin-top:16px;padding:12px;border:1px solid #999;border-radius:10px;">
      wallet nicht verbunden (oben rechts verbinden)
    </div>

    <div v-else-if="!onChain" style="margin-top:16px;padding:12px;border:1px solid #999;border-radius:10px;">
      falsches netzwerk. bitte avalanche fuji auswählen
    </div>

    <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-top:16px;">
      <BalancesCard
        style="grid-column:1 / span 2;"
        :mebtc="mebtc"
        :usdc="usdc"
        :loading="balancesLoading"
        :mebtcDecimals="mebtcDecimals"
        :usdcDecimals="usdcDecimals"
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
        :owned="owned"
        @approve-stats="setApproveStats"
      />

      <NewsCard
        style="grid-column:2;max-width:420px;justify-self:end;width:100%;"
        :items="newsItems"
      />
    </div>

    <div style="margin-top:12px;">
      <ClaimCard
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
        :onClaim="claim"
      />
    </div>
  </div>
</template>
