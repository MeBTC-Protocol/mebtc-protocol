<script setup lang="ts">
defineProps<{ title: string; compact?: boolean }>()
</script>

<template>
  <div :style="compact ? 'border:1px solid #999;border-radius:10px;padding:8px;' : 'border:1px solid #999;border-radius:14px;padding:12px;'">
    <div :style="compact ? 'font-size:14px;margin-bottom:6px;' : 'font-size:16px;margin-bottom:10px;'">
      {{ title }}
    </div>
    <div style="display:grid;gap:6px;">
      <slot />
    </div>
  </div>
</template>
