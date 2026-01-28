<script setup lang="ts">
import Card from '../common/Card.vue'
import Button from '../common/Button.vue'

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
    <div class="ui-row">
      <Button :disabled="disabled || busy" @click="onApproveMiner">
        approve für MinerNFT (max)
      </Button>
      <Button :disabled="disabled || busy" @click="onApproveManager">
        approve für Manager (max)
      </Button>
    </div>

    <div v-if="error" style="margin-top:10px;">error: {{ error }}</div>
    <div v-if="lastTx" class="ui-muted" style="margin-top:10px;">tx: {{ lastTx }}</div>
  </Card>
</template>
