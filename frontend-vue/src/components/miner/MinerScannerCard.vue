<script setup lang="ts">
import Card from '../common/Card.vue'

defineProps<{
  disabled: boolean
  busy: boolean
  msg: string
  error: string
  owned: bigint[]
  onScan: () => void
}>()
</script>

<template>
  <Card title="miner scan">
    <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;">
      <button :disabled="disabled || busy" @click="onScan" style="padding:10px 12px;border-radius:12px;border:1px solid #999;background:transparent;cursor:pointer;">
        neu scannen
      </button>
      <div style="opacity:.75;">{{ msg }}</div>
    </div>

    <div v-if="error" style="margin-top:10px;">error: {{ error }}</div>

    <div style="margin-top:10px;opacity:.75;">tokenIds:</div>
    <div style="display:flex;gap:6px;flex-wrap:wrap;margin-top:6px;">
      <span v-if="owned.length===0">-</span>
      <span v-for="id in owned" :key="id.toString()" style="padding:4px 8px;border:1px solid #999;border-radius:999px;">
        #{{ id.toString() }}
      </span>
    </div>
  </Card>
</template>

