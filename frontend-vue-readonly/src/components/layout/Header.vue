<script setup lang="ts">
import { computed } from 'vue'
import { useAppKit, useAppKitAccount } from '@reown/appkit/vue'
import Button from '../common/Button.vue'
import { shortAddr } from '../../utils/format'

type HeaderMeta = { label: string; value: string }

defineProps<{ title: string; meta?: HeaderMeta[]; iconUrl?: string }>()

const { open } = useAppKit()
const account = useAppKitAccount({ namespace: 'eip155' })
const isConnected = computed(() => Boolean(account.value?.isConnected))
const address = computed(() => account.value?.address)
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
