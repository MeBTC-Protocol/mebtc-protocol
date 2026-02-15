import { createApp } from 'vue'
import App from './App.vue'
import { initAppKit } from './appkit/initAppKit'
import { getInitialTheme } from './composables/useTheme'
import { installGlobalRuntimeMonitoring } from './monitoring/runtimeTelemetry'
import './style.css'

initAppKit()
installGlobalRuntimeMonitoring()

document.documentElement.dataset.theme = getInitialTheme()

createApp(App).mount('#app')
