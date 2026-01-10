<script setup lang="ts">
import Card from '../common/Card.vue'

defineProps<{
  disabled: boolean
  busy: boolean
  error: string
  lastTx: string
  onApproveMiner: () => void
  onApproveManager: () => void
}>()
</script>

<template>
  <Card title="approve usdc">
    <div style="display:flex;gap:8px;flex-wrap:wrap;">
      <button :disabled="disabled || busy" @click="onApproveMiner" style="padding:10px 12px;border-radius:12px;border:1px solid #999;background:transparent;cursor:pointer;">
        approve für MinerNFT (max)
      </button>
      <button :disabled="disabled || busy" @click="onApproveManager" style="padding:10px 12px;border-radius:12px;border:1px solid #999;background:transparent;cursor:pointer;">
        approve für Manager (max)
      </button>
    </div>

    <div v-if="error" style="margin-top:10px;opacity:.9;">error: {{ error }}</div>
    <div v-if="lastTx" style="margin-top:10px;opacity:.8;">tx: {{ lastTx }}</div>
  </Card>
</template>

