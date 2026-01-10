<script setup lang="ts">
defineProps<{ title: string }>()
</script>

<template>
  <div style="border:1px solid #999;border-radius:14px;padding:12px;">
    <div style="font-size:16px;margin-bottom:10px;">{{ title }}</div>
    <div style="display:grid;gap:6px;">
      <slot />
    </div>
  </div>
</template>

