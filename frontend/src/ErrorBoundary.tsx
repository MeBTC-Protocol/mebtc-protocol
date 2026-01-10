 // src/ErrorBoundary.tsx
import { Component, type ReactNode } from 'react'
export class ErrorBoundary extends Component<{children:ReactNode},{e?:Error}> {
  state = { e: undefined as Error|undefined }
  static getDerivedStateFromError(e: Error){ return { e } }
  render(){ return this.state.e
    ? <div style={{padding:16}}><h2>Frontend-Fehler</h2><pre>{this.state.e.message}</pre></div>
    : this.props.children }
}

