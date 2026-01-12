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

const style = computed(() => {
  const sm = props.size === 'sm'
  const padding = sm ? '6px 10px' : '10px 12px'
  const radius = sm ? '10px' : '12px'
  const font = sm ? '11px' : '12px'
  const bg = props.variant === 'solid' ? '#f7f7f7' : 'transparent'
  const opacity = props.disabled ? '0.6' : '1'
  const cursor = props.disabled ? 'not-allowed' : 'pointer'
  return [
    `padding:${padding}`,
    `border-radius:${radius}`,
    'border:1px solid #999',
    `background:${bg}`,
    `cursor:${cursor}`,
    `font-size:${font}`,
    'display:inline-flex',
    'align-items:center',
    'gap:6px',
    `opacity:${opacity}`
  ].join(';')
})
</script>

<template>
  <button
    :type="type"
    :disabled="disabled"
    :style="style"
    v-bind="$attrs"
  >
    <slot name="icon" />
    <slot />
  </button>
</template>
