<script setup lang="ts">
import { computed } from 'vue'

defineOptions({ inheritAttrs: false })

type Size = 'sm' | 'md'
type Variant = 'ghost' | 'solid'

const props = withDefaults(defineProps<{
  size?: Size
  variant?: Variant
  disabled?: boolean
  type?: 'button' | 'submit' | 'reset'
}>(), {
  size: 'md',
  variant: 'ghost',
  disabled: false,
  type: 'button'
})

const classes = computed(() => {
  return [
    'btn',
    props.size === 'sm' ? 'btn-sm' : 'btn-md',
    props.variant === 'ghost' ? 'btn-ghost' : 'btn-solid',
    props.disabled ? 'btn-disabled' : ''
  ]
})
</script>

<template>
  <button
    :type="type"
    :disabled="disabled"
    :class="classes"
    v-bind="$attrs"
  >
    <slot name="icon" />
    <slot />
  </button>
</template>
