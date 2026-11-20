import { Link } from 'react-router-dom';
import { usePageMeta } from '../hooks/usePageMeta';
import { SiteFooter } from '../components/SiteFooter';

export function NotFoundPage() {
  usePageMeta('Página no encontrada', 'Esta dirección no existe en MyWorksApp.', true);
  return (
    <div className="min-h-screen app-shell">
      <main className="container legal-page">
        <h1>No encontramos esa página</h1>
        <p>La dirección no corresponde a un servicio, un profesional ni un pedido.</p>
        <Link className="btn-primary" to="/">Volver al inicio</Link>
      </main>
      <SiteFooter />
    </div>
  );
}
