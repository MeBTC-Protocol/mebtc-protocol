import { ref } from 'vue'

const refreshKey = ref(0)

export function useMinerStatsRefresh() {
  function triggerRefresh() {
    refreshKey.value += 1
  }

  return {
    refreshKey,
    triggerRefresh
  }
}
