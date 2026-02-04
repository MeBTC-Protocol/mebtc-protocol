import { computed, ref, watch } from 'vue'
import { explainError } from '../utils/errorExplain'

export function useErrorPopup(getError: () => string, context?: string) {
  const dismissed = ref('')
  const error = computed(() => (getError() || '').trim())
  const help = computed(() => explainError(error.value, context))
  const open = computed(() => !!error.value && error.value !== dismissed.value)

  watch(error, (next) => {
    if (!next) dismissed.value = ''
  })

  function close() {
    dismissed.value = error.value
  }

  return { open, help, close }
}
