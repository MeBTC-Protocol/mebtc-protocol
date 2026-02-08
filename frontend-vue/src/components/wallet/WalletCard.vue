<script setup lang="ts">
import { shortAddr } from '../../utils/format'

defineProps<{
  connected: boolean
  address?: string
  chainId?: number
  onChain: boolean
}>()
</script>

<template>
  <div style="min-width:220px;">
    <details class="ui-dropdown">
      <summary>
        <span class="ui-row">
          <svg
            viewBox="0 0 24 24"
            width="14"
            height="14"
            aria-hidden="true"
            style="display:block"
          >
            <path
              d="M4 6.5C4 5.7 4.7 5 5.5 5h12.8a1.7 1.7 0 0 1 1.7 1.7v1.1H7.2c-1.7 0-3.2 1.3-3.2 3v3.4c0 .8.7 1.5 1.5 1.5H20v1.1c0 1-.8 1.7-1.7 1.7H5.5A1.5 1.5 0 0 1 4 17V6.5Z"
              fill="currentColor"
            />
            <path
              d="M7.2 9.3h11.8c.6 0 1 .4 1 1v3.4c0 .6-.4 1-1 1H7.2c-.9 0-1.7-.8-1.7-1.7v-2c0-.9.8-1.7 1.7-1.7Z"
              fill="currentColor"
            />
            <circle cx="16.8" cy="12" r="1.2" fill="#fff" />
          </svg>
          <span>Wallet</span>
        </span>
        <span class="ui-dot" :style="`background:${connected ? '#0a0' : '#b00'};`" />
      </summary>
      <div style="margin-top:8px;">
        <div class="ui-meta">
          <div>connectet: {{ String(connected) }}</div>
          <div>address: {{ shortAddr(address) }}</div>
          <div v-if="connected">chain: {{ chainId }}</div>
          <div v-if="connected">on target: {{ String(onChain) }}</div>
        </div>
      </div>
    </details>
  </div>
</template>
