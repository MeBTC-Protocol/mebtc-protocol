<script setup lang="ts">
import Card from '../common/Card.vue'
import { shortAddr } from '../../utils/format'

defineProps<{
  connected: boolean
  address?: string
  chainId: number
  onChain: boolean
}>()
</script>

<template>
  <Card title="wallet">
    <div>connected: {{ String(connected) }}</div>
    <div>address: {{ shortAddr(address) }}</div>
    <div>chainId: {{ chainId }}</div>
    <div>on fuji: {{ String(onChain) }}</div>
  </Card>
</template>

