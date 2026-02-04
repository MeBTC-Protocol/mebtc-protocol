<script setup lang="ts">
import Button from '../common/Button.vue'
import ErrorPopupInline from '../common/ErrorPopupInline.vue'

defineProps<{
  disabled: boolean
  busy: boolean
  msg: string
  error: string
  owned: bigint[]
  onScan: () => void
  compact?: boolean
}>()
</script>

<template>
  <details class="ui-dropdown">
    <summary>
      <span>Miner scan</span>
      <span v-if="busy" :style="compact ? 'opacity:.75;font-size:11px;' : 'opacity:.75;'">loading…</span>
    </summary>

    <div class="ui-row" style="margin-top:8px;">
      <Button
        :disabled="disabled || busy"
        @click="onScan"
        :size="compact ? 'sm' : 'md'"
      >
        neu scannen
      </Button>
      <div :style="compact ? 'opacity:.75;font-size:11px;' : 'opacity:.75;'">{{ msg }}</div>
    </div>

    <ErrorPopupInline :error="error" context="Miner Scan" />

    <div :style="compact ? 'margin-top:6px;opacity:.75;font-size:11px;' : 'margin-top:10px;opacity:.75;'">
      tokenIds:
    </div>
    <div :class="compact ? 'ui-row' : 'ui-row'" :style="compact ? 'gap:4px;margin-top:4px;' : 'gap:6px;margin-top:6px;'">
      <span v-if="owned.length===0">-</span>
      <span
        v-for="id in owned"
        :key="id.toString()"
        :class="['ui-pill', compact ? 'ui-pill-sm' : '']"
      >
        #{{ id.toString() }}
      </span>
    </div>
  </details>
</template>
