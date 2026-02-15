import { watch, type Ref } from 'vue'
import { emitUiRpcError } from '../monitoring/runtimeTelemetry'

type MonitoringSource = {
  context: string
  error: Ref<string>
}

export function useUiRpcMonitoring(sources: MonitoringSource[]) {
  for (const source of sources) {
    watch(
      source.error,
      (next) => {
        const msg = next.trim()
        if (!msg) return
        emitUiRpcError(source.context, msg)
      },
      { flush: 'post' }
    )
  }
}
