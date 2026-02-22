<script setup lang="ts">
import { computed, ref } from "vue"

const props = withDefaults(defineProps<{
  title: string
  compact?: boolean
  titleInfo?: string
  collapsible?: boolean
  defaultOpen?: boolean
}>(), {
  compact: false,
  titleInfo: "",
  collapsible: false,
  defaultOpen: true
})

const isOpen = ref(props.defaultOpen)
const isCollapsed = computed(() => props.collapsible && !isOpen.value)
const useCompactStyle = computed(() => props.compact && !isCollapsed.value)

function toggleOpen() {
  isOpen.value = !isOpen.value
}
</script>

<template>
  <div :class="['card', useCompactStyle ? 'card-compact' : '', isCollapsed ? 'card-collapsed' : '']">
    <div :class="['card-title', useCompactStyle ? 'card-title-compact' : '']">
      <span class="card-title-left">
        <span>{{ title }}</span>
        <span v-if="props.titleInfo" class="card-title-info-wrap">
          <button type="button" class="card-title-info-btn" aria-label="Info">
            i
          </button>
          <span class="card-title-info-popover">
            <span v-for="line in props.titleInfo.split('\n')" :key="line" class="card-title-info-line">
              {{ line }}
            </span>
          </span>
        </span>
      </span>
      <button
        v-if="props.collapsible"
        type="button"
        class="card-collapse-btn"
        :aria-expanded="isOpen"
        :aria-label="isOpen ? 'Einklappen' : 'Aufklappen'"
        @click="toggleOpen"
      >
        <span :class="['card-collapse-icon', isOpen ? 'is-open' : '']">
          v
        </span>
      </button>
    </div>
    <div v-if="!props.collapsible || isOpen" class="card-body">
      <slot />
    </div>
  </div>
</template>

<style scoped>
.card-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.card-title-left {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
}

.card-collapse-btn {
  border: var(--ui-border-width) solid var(--ui-border);
  background: var(--ui-panel);
  color: var(--ui-text-muted);
  width: 22px;
  height: 22px;
  border-radius: 999px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  cursor: pointer;
  flex: 0 0 auto;
}

.card-collapse-icon {
  font-size: 11px;
  line-height: 1;
  transform: rotate(-90deg);
  transition: transform 120ms ease;
}

.card-collapse-icon.is-open {
  transform: rotate(0deg);
}

.card-title-info-wrap {
  position: relative;
  display: inline-flex;
  align-items: center;
}

.card-title-info-btn {
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

.card-title-info-popover {
  position: absolute;
  top: calc(100% + 8px);
  left: 0;
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

.card-title-info-wrap:hover .card-title-info-popover,
.card-title-info-wrap:focus-within .card-title-info-popover {
  opacity: 1;
  transform: translateY(0);
}

.card-title-info-line {
  display: block;
  color: var(--ui-text-muted);
  font-size: 11px;
  line-height: 1.35;
  text-transform: none;
  letter-spacing: 0;
  font-family: var(--ui-font-body);
}

.card-title-info-line + .card-title-info-line {
  margin-top: 8px;
}

.card-collapsed .card-title-left {
  max-width: calc(100% - 30px);
}

.card-collapsed .card-title-left > span:first-child {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
</style>
