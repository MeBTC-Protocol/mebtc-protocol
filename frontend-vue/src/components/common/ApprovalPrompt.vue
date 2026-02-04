<script setup lang="ts">
import Card from './Card.vue'
import Button from './Button.vue'
import ErrorPopupInline from './ErrorPopupInline.vue'

defineProps<{
  open: boolean
  tokenSymbol: string
  spenderLabel: string
  neededText: string
  allowanceText: string
  exactEnabled: boolean
  busy: boolean
  error: string
  onApproveExact: () => void
  onApproveMax: () => void
  onCancel: () => void
}>()
</script>

<template>
  <div v-if="open" class="ui-modal-backdrop">
    <div class="ui-modal">
      <Card title="Approval needed">
        <div class="ui-stack">
          <div class="ui-muted">
            Token: <b>{{ tokenSymbol }}</b>
          </div>
          <div class="ui-muted">
            Spender: <b>{{ spenderLabel }}</b>
          </div>
          <div class="ui-muted">
            Needed: <b>{{ neededText }} {{ tokenSymbol }}</b>
          </div>
          <div class="ui-muted">
            Current allowance: <b>{{ allowanceText }} {{ tokenSymbol }}</b>
          </div>
        </div>

        <div class="ui-row" style="margin-top:12px;">
          <Button
            :disabled="busy || !exactEnabled"
            size="sm"
            @click="onApproveExact"
          >
            Approve exact
          </Button>
          <Button
            :disabled="busy"
            size="sm"
            @click="onApproveMax"
          >
            Approve max
          </Button>
          <Button
            :disabled="busy"
            size="sm"
            @click="onCancel"
          >
            Cancel
          </Button>
        </div>

        <ErrorPopupInline :error="error" context="Approval" />
      </Card>
    </div>
  </div>
</template>
