import { createApp } from 'vue'
import App from './App.vue'
import { initAppKit } from './appkit/initAppKit'

initAppKit()

createApp(App).mount('#app')

