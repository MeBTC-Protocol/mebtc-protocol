<script setup lang="ts">
defineProps<{
  open: boolean
  title: string
  message: string
  steps: string[]
  raw: string
  onClose: () => void
}>()
</script>

<template>
  <div v-if="open" class="error-popup" role="alert">
    <div class="error-popup-head">
      <div class="error-popup-title">{{ title }}</div>
      <button type="button" class="error-popup-close" @click="onClose">x</button>
    </div>
    <div class="error-popup-msg">{{ message }}</div>
    <div class="error-popup-steps">
      <div class="error-popup-steps-title">Was kann ich tun?</div>
      <ul>
        <li v-for="(step, idx) in steps" :key="idx">{{ step }}</li>
      </ul>
    </div>
    <details class="error-popup-raw">
      <summary>Technische Details</summary>
      <div class="error-popup-raw-text">{{ raw }}</div>
    </details>
  </div>
</template>
