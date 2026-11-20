import { Link } from 'react-router-dom';
import { SiteFooter } from '../components/SiteFooter';
import { usePageMeta } from '../hooks/usePageMeta';

type Kind = 'terminos' | 'privacidad';

const COPY: Record<Kind, { title: string; lead: string }> = {
  terminos: {
    title: 'Términos y condiciones',
    lead: 'El texto oficial de los términos todavía no está publicado en el sitio.',
  },
  privacidad: {
    title: 'Política de privacidad',
    lead: 'El texto oficial de la política de privacidad todavía no está publicado en el sitio.',
  },
};

/** No redacta cláusulas. El responsable del tratamiento publica el texto. */
export function LegalPage({ kind }: { kind: Kind }) {
  const page = COPY[kind];
  usePageMeta(page.title, page.lead);
  return (
    <div className="min-h-screen app-shell">
      <main className="container legal-page">
        <h1>{page.title}</h1>
        <p>{page.lead}</p>
        <p>
          Mientras no esté cargado, esta página no agrega obligaciones. El tratamiento de datos
          personales se rige por la Ley 19.628 y la Ley 21.719. Para pedir el texto o ejercer un
          derecho, usa Mi cuenta si ya entraste, o el correo de contacto que publique el responsable.
        </p>
        <Link to="/">Volver al inicio</Link>
      </main>
      <SiteFooter />
    </div>
  );
}
