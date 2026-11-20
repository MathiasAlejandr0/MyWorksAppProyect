import { Link } from 'react-router-dom';
import { APP_COMMIT, PUBLIC_SITE_URL } from '../site';

/** Pie con enlaces reales. El texto legal largo lo publica el responsable; aquí no se redactan cláusulas. */
export function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="container site-footer-grid">
        <div>
          <strong>MyWorksApp</strong>
          <p>Servicios del hogar con pago protegido.</p>
          <p>
            <a href={PUBLIC_SITE_URL}>{PUBLIC_SITE_URL.replace('https://', '')}</a>
          </p>
        </div>
        <nav aria-label="Información">
          <Link to="/terminos">Términos y condiciones</Link>
          <Link to="/privacidad">Política de privacidad</Link>
          <Link to="/trabaja">Trabaja con nosotros</Link>
          <Link to="/cuenta">Mi cuenta</Link>
        </nav>
        <p className="site-footer-version">Versión {APP_COMMIT}</p>
      </div>
    </footer>
  );
}
