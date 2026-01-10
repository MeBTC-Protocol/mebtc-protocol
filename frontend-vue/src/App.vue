<script setup lang="ts">
import Header from './components/layout/Header.vue'
import WalletCard from './components/wallet/WalletCard.vue'
import BalancesCard from './components/wallet/BalancesCard.vue'
import AllowancesCard from './components/wallet/AllowancesCard.vue'
import MinerScannerCard from './components/miner/MinerScannerCard.vue'
import ClaimCard from './components/miner/ClaimCard.vue'
import MinerPricingCard from './components/miner/MinerPricingCard.vue'

import { ADDRESSES } from './contracts/addresses'
import { useWallet } from './composables/useWallet'
import { useBalances } from './composables/useBalances'
import { useAllowances } from './composables/useAllowances'
import { useApproveUSDC } from './composables/useApproveUSDC'
import { useOwnedMinerTokenIds } from './composables/useOwnedMinerTokenIds'
import { useMinerPreviews } from './composables/useMinerPreviews'
import { useClaimSelected } from './composables/useClaimSelected'
import { useMinerActions } from './composables/useMinerActions'

// wallet
const { isConnected, address, chainId, onChain } = useWallet()

// balances
const { mebtc, usdc, loading: balancesLoading, mebtcDecimals, usdcDecimals } = useBalances()

// allowances
const {
  loading: allowancesLoading,
  allowanceMiner,
  allowanceMinerText,
  allowanceManagerText
} = useAllowances()

// approve (nur noch für MinerPricingCard nötig)
const {
  busy: approveBusy,
  error: approveError,
  lastTx: approveLastTx,
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

function setSelected(next: Record<string, boolean>) {
  selected.value = next
}
</script>

<template>
  <div style="max-width:1150px;margin:0 auto;padding:16px;font-family:ui-sans-serif,system-ui;">
    <Header
      title="MeBTC Dashboard (Vue + Reown + Ethers)"
      :subtitle="`MinerNFT: ${ADDRESSES.minerNft} | Manager: ${ADDRESSES.miningManager}`"
    />

    <div v-if="!isConnected" style="margin-top:16px;padding:12px;border:1px solid #999;border-radius:10px;">
      wallet nicht verbunden (oben rechts verbinden)
    </div>

    <div v-else-if="!onChain" style="margin-top:16px;padding:12px;border:1px solid #999;border-radius:10px;">
      falsches netzwerk. bitte avalanche fuji auswählen
    </div>

    <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-top:16px;">
      <WalletCard :connected="isConnected" :address="address" :chainId="chainId" :onChain="onChain" />

      <BalancesCard
        :mebtc="mebtc"
        :usdc="usdc"
        :loading="balancesLoading"
        :mebtcDecimals="mebtcDecimals"
        :usdcDecimals="usdcDecimals"
        :disabled="!isConnected || !onChain"
        :owned="owned"
      />

      <AllowancesCard
        :disabled="!isConnected || !onChain"
        :loading="allowancesLoading"
        :busy="approveBusy"
        :minerText="allowanceMinerText()"
        :managerText="allowanceManagerText()"
        :error="approveError"
        :lastTx="approveLastTx"
        :onApproveMiner="approveMinerMax"
        :onApproveManager="approveManagerMax"
      />

      <MinerScannerCard
        :disabled="!isConnected || !onChain"
        :busy="scanBusy"
        :msg="scanMsg"
        :error="scanError"
        :owned="owned"
        :onScan="rescan"
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
