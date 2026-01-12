<script setup lang="ts">
import Card from '../common/Card.vue'

type NewsItem = {
  title: string
  summary?: string
  url?: string
  date?: string
}

defineProps<{ items: NewsItem[] }>()
</script>

<template>
  <Card title="News">
    <div v-if="!items || items.length === 0" style="opacity:.7;">keine news</div>
    <div v-else style="display:flex;flex-direction:column;gap:10px;">
      <div v-for="(item, idx) in items" :key="idx" style="display:flex;flex-direction:column;gap:4px;">
        <div style="font-weight:600;line-height:1.2;">
          <a
            v-if="item.url"
            :href="item.url"
            target="_blank"
            rel="noreferrer"
            style="color:inherit;text-decoration:underline;"
          >
            {{ item.title }}
          </a>
          <span v-else>{{ item.title }}</span>
        </div>
        <div v-if="item.summary" style="opacity:.75;font-size:13px;">
          {{ item.summary }}
        </div>
        <div v-if="item.date" style="opacity:.6;font-size:12px;">
          {{ item.date }}
        </div>
      </div>
    </div>
  </Card>
</template>
