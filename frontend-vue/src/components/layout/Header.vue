<script setup lang="ts">
import { computed } from 'vue'
import { useAppKit } from '@reown/appkit/vue'
import Button from '../common/Button.vue'
import { shortAddr } from '../../utils/format'
import { useWallet } from '../../composables/useWallet'

type HeaderMeta = { label: string; value: string; info?: string }

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
            <span v-if="item.info" class="meta-info-wrap">
              <button type="button" class="meta-info-btn" aria-label="Preisinfo">
                i
              </button>
              <span class="meta-info-popover">
                <span
                  v-for="line in item.info.split('\n')"
                  :key="line"
                  class="meta-info-line"
                >
                  {{ line }}
                </span>
              </span>
            </span>
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
              <span class="wallet-connect-icon">
                <img src="/Geldbörse.png" alt="Wallet" />
              </span>
            </template>
            <span :class="['wallet-connect-label', isConnected ? 'wallet-address-label' : '']">
              {{ buttonLabel }}
            </span>
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
  font-family: 'Work Sans', sans-serif;
  font-weight: 600;
  letter-spacing: 0.2px;
}

.wallet-address-label {
  color: #111111;
  font-weight: 700;
}

.meta-info-wrap {
  position: relative;
  display: inline-flex;
  align-items: center;
}

.meta-info-btn {
  border: var(--ui-border-width) solid var(--ui-border);
  background: var(--ui-panel);
  color: var(--ui-text-muted);
  width: 16px;
  height: 16px;
  border-radius: 999px;
  font-size: 10px;
  font-weight: 700;
  line-height: 1;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  cursor: default;
}

.meta-info-popover {
  position: absolute;
  top: calc(100% + 8px);
  right: 0;
  width: min(420px, 82vw);
  background: var(--ui-panel);
  border: var(--ui-border-width) solid var(--ui-border);
  border-radius: var(--ui-radius-md);
  box-shadow: 0 16px 30px -24px var(--ui-shadow-color);
  padding: 10px 12px;
  opacity: 0;
  transform: translateY(-4px);
  pointer-events: none;
  transition: opacity 120ms ease, transform 120ms ease;
  z-index: 10;
}

.meta-info-wrap:hover .meta-info-popover,
.meta-info-wrap:focus-within .meta-info-popover {
  opacity: 1;
  transform: translateY(0);
}

.meta-info-line {
  display: block;
  color: var(--ui-text-muted);
  font-size: 11px;
  line-height: 1.35;
}

.meta-info-line + .meta-info-line {
  margin-top: 8px;
}
</style>
