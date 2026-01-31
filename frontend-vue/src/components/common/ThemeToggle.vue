<script setup lang="ts">
import { useTheme } from '../../composables/useTheme'

const { theme, themes } = useTheme()
</script>

<template>
  <div class="ui-row">
    <span class="ui-subtitle" style="margin:0;">Theme</span>
    <select v-model="theme" class="ui-select" style="min-width:180px;" aria-label="Theme">
      <option v-for="option in themes" :key="option.id" :value="option.id">
        {{ option.label }}
      </option>
    </select>
  </div>
</template>
