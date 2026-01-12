<script setup lang="ts">
import Button from '../common/Button.vue'

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
  <details style="border:1px solid #999;border-radius:10px;padding:6px 8px;background:#f7f7f7;box-shadow:0 2px 4px rgba(0,0,0,0.08);">
    <summary style="cursor:pointer;list-style:none;font-size:12px;display:flex;align-items:center;gap:8px;padding:6px 8px;border-radius:8px;background:#fff;border:1px solid #ddd;">
      <span>Miner scan</span>
      <span v-if="busy" :style="compact ? 'opacity:.75;font-size:11px;' : 'opacity:.75;'">loading…</span>
    </summary>

    <div style="margin-top:8px;display:flex;gap:8px;align-items:center;flex-wrap:wrap;">
      <Button
        :disabled="disabled || busy"
        @click="onScan"
        :size="compact ? 'sm' : 'md'"
      >
        neu scannen
      </Button>
      <div :style="compact ? 'opacity:.75;font-size:11px;' : 'opacity:.75;'">{{ msg }}</div>
    </div>

    <div v-if="error" :style="compact ? 'margin-top:6px;font-size:11px;' : 'margin-top:10px;'">
      error: {{ error }}
    </div>

    <div :style="compact ? 'margin-top:6px;opacity:.75;font-size:11px;' : 'margin-top:10px;opacity:.75;'">
      tokenIds:
    </div>
    <div :style="compact ? 'display:flex;gap:4px;flex-wrap:wrap;margin-top:4px;' : 'display:flex;gap:6px;flex-wrap:wrap;margin-top:6px;'">
      <span v-if="owned.length===0">-</span>
      <span
        v-for="id in owned"
        :key="id.toString()"
        :style="compact
          ? 'padding:2px 6px;border:1px solid #999;border-radius:999px;font-size:10px;'
          : 'padding:4px 8px;border:1px solid #999;border-radius:999px;'"
      >
        #{{ id.toString() }}
      </span>
    </div>
  </details>
</template>
