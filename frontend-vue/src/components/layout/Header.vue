<script setup lang="ts">
import { computed } from 'vue'
import { useAppKit, useAppKitAccount } from '@reown/appkit/vue'
import { shortAddr } from '../../utils/format'

defineProps<{ title: string; subtitle?: string; iconUrl?: string }>()

const { open } = useAppKit()
const account = useAppKitAccount({ namespace: 'eip155' })
const isConnected = computed(() => Boolean(account.value?.isConnected))
const address = computed(() => account.value?.address)
const buttonLabel = computed(() =>
  isConnected.value && address.value ? shortAddr(address.value) : 'Wallet verbinden'
)
</script>

<template>
  <div style="display:flex;justify-content:space-between;align-items:flex-start;gap:12px;">
    <div style="display:flex;align-items:flex-start;gap:16px;">
      <img v-if="iconUrl" :src="iconUrl" alt="" style="width:160px;height:160px;border-radius:12px;" />
      <div>
        <div style="font-size:24px;">{{ title }}</div>
        <div v-if="subtitle" style="opacity:.7;margin-top:4px;white-space:pre-line;">
          {{ subtitle }}
        </div>
      </div>
    </div>
    <div style="display:flex;gap:10px;align-items:flex-start;">
      <slot name="right" />
      <div style="display:flex;flex-direction:column;gap:8px;align-items:flex-end;">
        <button class="wallet-connect-btn" type="button" @click="open()">
          <span class="wallet-connect-icon" aria-hidden="true">
            <svg viewBox="0 0 24 24" width="16" height="16">
              <path
                d="M5.5 6A2.5 2.5 0 0 0 3 8.5v7A2.5 2.5 0 0 0 5.5 18h13a2.5 2.5 0 0 0 2.5-2.5v-1h-9a3 3 0 0 1 0-6h9V8.5A2.5 2.5 0 0 0 18.5 6h-13Z"
                fill="currentColor"
              />
              <circle cx="16.5" cy="11.5" r="1.3" fill="#fff" />
            </svg>
          </span>
          <span class="wallet-connect-label">{{ buttonLabel }}</span>
        </button>
        <slot name="wallet-extra" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.wallet-connect-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  border: 1px solid #d0d5dd;
  background: #ffffff;
  color: #101828;
  border-radius: 10px;
  padding: 8px 12px;
  font-size: 12px;
  font-family: ui-sans-serif, system-ui;
  cursor: pointer;
  box-shadow: 0 4px 10px rgba(16, 24, 40, 0.08);
}

.wallet-connect-btn:hover {
  background: #f8fafc;
  border-color: #c7ced6;
}

.wallet-connect-btn:active {
  background: #eef2f7;
}

.wallet-connect-icon {
  width: 20px;
  height: 20px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 6px;
  border: 1px solid #e4e7ec;
  background: #fff;
  color: #0f172a;
}

.wallet-connect-icon img {
  width: 16px;
  height: 16px;
  object-fit: contain;
}

.wallet-connect-label {
  font-weight: 600;
  letter-spacing: 0.2px;
}
</style>
