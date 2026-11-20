import { Link } from 'react-router-dom';
import { ACADEMIC_BANNER_TEXT } from '../legal/academicCopy';
import { APP_COMMIT, PUBLIC_SITE_URL } from '../site';

export function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="container">
        <p className="site-footer-notice">{ACADEMIC_BANNER_TEXT}</p>
        <div className="site-footer-grid">
          <div>
            <strong>MyWorksApp</strong>
            <p>Proyecto de título · Duoc UC, sede Puerto Montt.</p>
            <p>
              <a href={PUBLIC_SITE_URL}>{PUBLIC_SITE_URL.replace('https://', '')}</a>
            </p>
          </div>
          <nav aria-label="Información">
            <Link to="/aviso-legal">Aviso legal</Link>
            <Link to="/terminos">Términos y condiciones</Link>
            <Link to="/privacidad">Política de privacidad</Link>
            <Link to="/trabaja">Trabaja con nosotros</Link>
            <Link to="/cuenta">Mi cuenta</Link>
          </nav>
          <p className="site-footer-version">Versión {APP_COMMIT}</p>
        </div>
      </div>
    </footer>
  );
}
