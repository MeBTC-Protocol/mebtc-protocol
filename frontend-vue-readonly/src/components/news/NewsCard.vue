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
    <div v-if="!items || items.length === 0" class="ui-muted">keine news</div>
    <div v-else class="news-list">
      <div v-for="(item, idx) in items" :key="idx" class="news-item">
        <div class="news-title">
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
        <div v-if="item.summary" class="ui-muted" style="font-size:12px;">
          {{ item.summary }}
        </div>
        <div v-if="item.date" class="ui-muted" style="font-size:11px;">
          {{ item.date }}
        </div>
      </div>
    </div>
  </Card>
</template>
