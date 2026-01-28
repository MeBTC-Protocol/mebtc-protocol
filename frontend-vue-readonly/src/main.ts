import { createApp } from 'vue'
import App from './App.vue'
import { initAppKit } from './appkit/initAppKit'
import './style.css'

initAppKit()

const savedTheme = localStorage.getItem('ui-theme')
document.documentElement.dataset.theme = savedTheme ?? 'neutral'

createApp(App).mount('#app')
