import { Component, type ReactNode } from 'react';
import { Button } from './kit';

interface State { error: string | null }

export class RouteErrorBoundary extends Component<{ children: ReactNode }, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: unknown): State {
    return { error: error instanceof Error ? error.message : 'Error inesperado' };
  }

  render() {
    if (this.state.error) {
      return (
        <div className="error-box">
          <p>Esta pantalla falló al mostrarse.</p>
          <Button variant="secondary" onClick={() => this.setState({ error: null })}>Reintentar</Button>
        </div>
      );
    }
    return this.props.children;
  }
}
