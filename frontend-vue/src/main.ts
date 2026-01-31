import { createApp } from 'vue'
import App from './App.vue'
import { initAppKit } from './appkit/initAppKit'
import { getInitialTheme } from './composables/useTheme'
import './style.css'

initAppKit()

document.documentElement.dataset.theme = getInitialTheme()

createApp(App).mount('#app')
