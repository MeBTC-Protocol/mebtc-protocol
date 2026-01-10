<script setup lang="ts">
import Card from '../common/Card.vue'

defineProps<{
  disabled: boolean
  loading: boolean
  busy: boolean
  minerText: string
  managerText: string
  error: string
  lastTx: string
  onApproveMiner: () => void
  onApproveManager: () => void
}>()
</script>

<template>
  <Card title="usdc allowances">
    <div v-if="loading">loading…</div>
    <div v-else>
      <div>für miner (buy/upgrade): {{ minerText }}</div>
      <div>für manager (claim fee): {{ managerText }}</div>
      <div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:8px;">
        <button
          :disabled="disabled || busy"
          @click="onApproveMiner"
          style="padding:8px 10px;border-radius:10px;border:1px solid #999;background:transparent;cursor:pointer;"
        >
          approve USDC für MinerNFT (max)
        </button>
        <button
          :disabled="disabled || busy"
          @click="onApproveManager"
          style="padding:8px 10px;border-radius:10px;border:1px solid #999;background:transparent;cursor:pointer;"
        >
          approve USDC für Manager (max)
        </button>
      </div>
      <div v-if="error" style="margin-top:8px;">approve error: {{ error }}</div>
      <div v-if="lastTx" style="margin-top:6px;opacity:.8;">approve tx: {{ lastTx }}</div>
    </div>
  </Card>
</template>
