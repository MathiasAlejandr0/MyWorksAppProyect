import { Link } from 'react-router-dom';
import { SiteFooter } from '../components/SiteFooter';
import { usePageMeta } from '../hooks/usePageMeta';

export function WorkWithUsPage() {
  usePageMeta(
    'Trabaja con nosotros',
    'Los profesionales usan la app de MyWorksApp. Esta web es para clientes.',
  );
  return (
    <div className="min-h-screen app-shell">
      <main className="container legal-page">
        <h1>Trabaja con nosotros</h1>
        <p>
          Si ofreces un oficio, entra con la app móvil de MyWorksApp. Esta web es solo para
          clientes: si una cuenta de profesional o de administración llega aquí, se cierra la sesión
          y se muestra ese aviso.
        </p>
        <p>El equipo interno usa la consola de escritorio, no este sitio.</p>
        <Link to="/">Volver al inicio</Link>
      </main>
      <SiteFooter />
    </div>
  );
}
