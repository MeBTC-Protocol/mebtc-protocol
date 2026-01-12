import { ref } from 'vue'

const refreshKey = ref(0)
const lastReason = ref('')
const rescanOwned = ref(false)

export function useGlobalRefresh() {
  function triggerRefresh(reason: string, opts?: { rescanOwned?: boolean }) {
    lastReason.value = reason
    rescanOwned.value = !!opts?.rescanOwned
    refreshKey.value += 1
  }

  return {
    refreshKey,
    lastReason,
    rescanOwned,
    triggerRefresh
  }
}
