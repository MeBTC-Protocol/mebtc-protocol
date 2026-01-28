<script setup lang="ts">
defineProps<{ title: string; compact?: boolean }>()
</script>

<template>
  <div :class="['card', compact ? 'card-compact' : '']">
    <div :class="['card-title', compact ? 'card-title-compact' : '']">
      {{ title }}
    </div>
    <div class="card-body">
      <slot />
    </div>
  </div>
</template>
