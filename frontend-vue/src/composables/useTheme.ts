import { computed, ref, watch } from 'vue'

const themeOptions = [
  { id: 'neutral', label: 'Nordic Minimal' },
  { id: 'neo-brutal', label: 'Neo-Brutal' },
  { id: 'dark-steel', label: 'Fintech Dark Steel' },
  { id: 'retro', label: 'Retro Classic' },
  { id: 'retro-terminal', label: 'Retro Terminal' },
  { id: 'papercraft', label: 'Papercraft' },
  { id: 'data-viz', label: 'Data-Viz Focus' },
  { id: 'warm-clay', label: 'Warm Clay' },
  { id: 'oceanic', label: 'Oceanic' }
] as const

type Theme = (typeof themeOptions)[number]['id']

const themeLabelMap = new Map(themeOptions.map((option) => [option.id, option.label]))
const defaultTheme: Theme = 'neutral'

function isTheme(value: string | null): value is Theme {
  return themeOptions.some((option) => option.id === value)
}

export function getInitialTheme(): Theme {
  const saved = localStorage.getItem('ui-theme')
  return isTheme(saved) ? saved : defaultTheme
}

const theme = ref<Theme>(getInitialTheme())

watch(theme, (next) => {
  document.documentElement.dataset.theme = next
  localStorage.setItem('ui-theme', next)
}, { immediate: true })

const themeLabel = computed(() => themeLabelMap.get(theme.value) ?? 'Theme')

function setTheme(next: Theme) {
  theme.value = next
}

export function useTheme() {
  return {
    theme,
    themeLabel,
    themes: themeOptions,
    setTheme
  }
}
