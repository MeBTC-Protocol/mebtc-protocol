import { computed, ref, watch } from 'vue'

const themes = ['neutral', 'retro'] as const
type Theme = (typeof themes)[number]

function getInitialTheme(): Theme {
  const saved = localStorage.getItem('ui-theme')
  if (saved === 'neutral' || saved === 'retro') return saved
  return 'neutral'
}

const theme = ref<Theme>(getInitialTheme())

watch(theme, (next) => {
  document.documentElement.dataset.theme = next
  localStorage.setItem('ui-theme', next)
}, { immediate: true })

const themeLabel = computed(() => (theme.value === 'neutral' ? 'Neutral' : 'Retro'))

function toggleTheme() {
  theme.value = theme.value === 'neutral' ? 'retro' : 'neutral'
}

export function useTheme() {
  return {
    theme,
    themeLabel,
    toggleTheme
  }
}
