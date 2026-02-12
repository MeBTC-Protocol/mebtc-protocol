<script setup lang="ts">
import Button from '../common/Button.vue'
import ErrorPopupInline from '../common/ErrorPopupInline.vue'

defineProps<{
  disabled: boolean
  busy: boolean
  error: string
  lastTx: string
  feePriceFresh: boolean
  onExecuteEpoch: () => void
}>()

function safeCall(fn: () => Promise<unknown> | unknown) {
  Promise.resolve(fn()).catch(() => {})
}

function formatFresh(value: boolean) {
  return value ? 'ja' : 'nein'
}
</script>

<template>
  <details class="ui-dropdown" style="width:fit-content;">
    <summary>
      <span>Oracle/Engine</span>
    </summary>
    <div style="margin-top:8px;">
      <div class="ui-muted" style="margin-bottom:8px;">
        TWAP-Update passiert bei Claim/Upgrade (max. alle 2h). Execute Epoch reinvestiert
        Vaults in den Pool und fuehrt Auto-Compound aus.
      </div>
      <div class="ui-muted" style="margin-bottom:8px;">
        Fee-Preis fresh: <b>{{ formatFresh(feePriceFresh) }}</b>
      </div>
      <div class="ui-row">
        <Button :disabled="disabled || busy" @click="() => safeCall(onExecuteEpoch)">
          Execute Epoch
        </Button>
      </div>
      <ErrorPopupInline :error="error" context="Oracle/Engine" />
      <div v-if="lastTx" class="ui-muted" style="margin-top:10px;">
        tx: {{ lastTx }}
      </div>
    </div>
  </details>
</template>
