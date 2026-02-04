<script setup lang="ts">
import ErrorPopup from './ErrorPopup.vue'
import { useErrorPopup } from '../../composables/useErrorPopup'

const props = defineProps<{
  error: string
  context?: string
}>()

const { open, help, close } = useErrorPopup(() => props.error, props.context)
</script>

<template>
  <ErrorPopup
    :open="open"
    :title="help.title"
    :message="help.message"
    :steps="help.steps"
    :raw="help.raw"
    :onClose="close"
  />
</template>
