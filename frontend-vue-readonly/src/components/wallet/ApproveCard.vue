<script setup lang="ts">
import Card from '../common/Card.vue'
import Button from '../common/Button.vue'
import ErrorPopup from '../common/ErrorPopup.vue'
import { useErrorPopup } from '../../composables/useErrorPopup'

const props = defineProps<{
  disabled: boolean
  busy: boolean
  error: string
  lastTx: string
  onApproveMiner: () => void
  onApproveManager: () => void
}>()

const { open, help, close } = useErrorPopup(() => props.error, 'Approve USDC')
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

    <ErrorPopup
      :open="open"
      :title="help.title"
      :message="help.message"
      :steps="help.steps"
      :raw="help.raw"
      :onClose="close"
    />
    <div v-if="lastTx" class="ui-muted" style="margin-top:10px;">tx: {{ lastTx }}</div>
  </Card>
</template>
