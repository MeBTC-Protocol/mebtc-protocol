<script setup lang="ts">
import Button from './Button.vue'
import { useTheme } from '../../composables/useTheme'

const { themeLabel, toggleTheme } = useTheme()
</script>

<template>
  <Button size="sm" variant="ghost" @click="toggleTheme">
    Theme: {{ themeLabel }}
  </Button>
</template>
