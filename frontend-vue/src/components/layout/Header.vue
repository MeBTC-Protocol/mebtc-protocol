<script setup lang="ts">
import { computed } from 'vue'
import { useAppKit } from '@reown/appkit/vue'
import Button from '../common/Button.vue'
import { shortAddr } from '../../utils/format'
import { useWallet } from '../../composables/useWallet'

type HeaderMeta = { label: string; value: string }

defineProps<{ title: string; meta?: HeaderMeta[]; iconUrl?: string }>()

const { open } = useAppKit()
const { isConnected, address, chainId, onChain } = useWallet()
const buttonLabel = computed(() =>
  isConnected.value && address.value ? shortAddr(address.value) : 'Wallet verbinden'
)
</script>

<template>
  <div class="header-root">
    <div class="header-left">
      <div v-if="iconUrl" class="hero-icon-wrap">
        <img :src="iconUrl" alt="" class="hero-icon" />
      </div>
      <div>
        <div class="title-graffiti">{{ title }}</div>
        <div v-if="meta?.length" class="meta-list">
          <div v-for="item in meta" :key="item.label" class="meta-item">
            <span class="meta-label">{{ item.label }}</span>
            <span class="meta-value">{{ item.value }}</span>
          </div>
        </div>
      </div>
    </div>
    <div class="header-right">
      <slot name="right" />
      <div class="header-wallet">
        <div class="wallet-button-wrap">
          <Button size="sm" variant="solid" @click="open()">
            <template #icon>
              <svg viewBox="0 0 24 24" width="16" height="16">
                <path
                  d="M5.5 6A2.5 2.5 0 0 0 3 8.5v7A2.5 2.5 0 0 0 5.5 18h13a2.5 2.5 0 0 0 2.5-2.5v-1h-9a3 3 0 0 1 0-6h9V8.5A2.5 2.5 0 0 0 18.5 6h-13Z"
                  fill="currentColor"
                />
                <circle cx="16.5" cy="11.5" r="1.3" fill="#fff" />
              </svg>
            </template>
            {{ buttonLabel }}
          </Button>
          <div class="wallet-status-popover">
            <div class="ui-meta">
              <div>connected: {{ String(isConnected) }}</div>
              <div>address: {{ shortAddr(address) }}</div>
              <div v-if="isConnected">chain: {{ chainId }}</div>
              <div v-if="isConnected">on target: {{ String(onChain) }}</div>
            </div>
          </div>
        </div>
        <slot name="wallet-extra" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.header-root {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
}

.header-left {
  display: flex;
  align-items: flex-start;
  gap: 16px;
}

.header-right {
  display: flex;
  gap: 10px;
  align-items: flex-start;
}

.header-wallet {
  display: flex;
  flex-direction: column;
  gap: 8px;
  align-items: flex-end;
}

.wallet-button-wrap {
  position: relative;
}

.wallet-status-popover {
  position: absolute;
  top: calc(100% + 6px);
  right: 0;
  min-width: 220px;
  padding: 10px 12px;
  background: var(--ui-panel);
  border: var(--ui-border-width) solid var(--ui-border);
  border-radius: var(--ui-radius-md);
  box-shadow: 0 16px 30px -24px var(--ui-shadow-color);
  opacity: 0;
  transform: translateY(-4px);
  pointer-events: none;
  transition: opacity 120ms ease, transform 120ms ease;
  z-index: 5;
}

.wallet-button-wrap:hover .wallet-status-popover,
.wallet-button-wrap:focus-within .wallet-status-popover {
  opacity: 1;
  transform: translateY(0);
  pointer-events: auto;
}

.title-graffiti {
  font-size: 32px;
  color: var(--ui-accent);
  font-family: var(--ui-font-display);
  letter-spacing: 0.4px;
}

.hero-icon-wrap {
  padding: 6px;
  border-radius: var(--ui-radius-lg);
  background: var(--ui-panel);
  border: var(--ui-border-width) solid var(--ui-border);
  box-shadow: 0 16px 30px -24px var(--ui-shadow-color);
}

.hero-icon {
  width: 120px;
  height: 120px;
  border-radius: var(--ui-radius-md);
  display: block;
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
