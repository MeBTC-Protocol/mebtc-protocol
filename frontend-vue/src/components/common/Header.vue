<script setup lang="ts">
defineProps<{ title: string; subtitle?: string }>()
</script>

<template>
  <div style="display:flex;justify-content:space-between;align-items:center;gap:12px;">
    <div>
      <div style="font-size:24px;">{{ title }}</div>
      <div v-if="subtitle" style="opacity:.7;margin-top:4px;">{{ subtitle }}</div>
    </div>
    <div style="display:flex;gap:10px;align-items:center;">
      <appkit-button />
    </div>
  </div>
</template>

