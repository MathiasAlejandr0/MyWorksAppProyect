import { Link } from 'react-router-dom';
import { SiteFooter } from '../components/SiteFooter';
import { openTestingSurvey } from '../components/testingSurveyEvents';
import { usePageMeta } from '../hooks/usePageMeta';
import {
  ACADEMIC_BANNER_TEXT,
  ACADEMIC_META_DESCRIPTION,
  TRANSBANK_TEST_CARDS_URL,
} from '../legal/academicCopy';

type Kind = 'aviso' | 'terminos' | 'privacidad';

const TITLES: Record<Kind, string> = {
  aviso: 'Aviso legal',
  terminos: 'Términos y condiciones',
  privacidad: 'Política de privacidad',
};

export function LegalPage({ kind }: { kind: Kind }) {
  usePageMeta(TITLES[kind], ACADEMIC_META_DESCRIPTION);
  return (
    <div className="min-h-screen app-shell">
      <main className="container legal-page">
        <p className="section-kicker">PROYECTO DE TÍTULO</p>
        <h1>{TITLES[kind]}</h1>
        <p>{ACADEMIC_BANNER_TEXT}</p>
        {kind === 'privacidad' ? <PrivacyBody /> : <TermsBody />}
        <p>
          <Link to="/">Volver al inicio</Link>
        </p>
      </main>
      <SiteFooter />
    </div>
  );
}

function TermsBody() {
  return (
    <>
      <h2>Naturaleza académica</h2>
      <p>
        MyWorksApp es un prototipo de título de la carrera Ingeniería en Informática de Duoc UC,
        sede Puerto Montt. Se publica con fines educativos y sin fines de lucro. No es un servicio
        comercial.
      </p>
      <h2>Sin empresa ni relación comercial</h2>
      <p>
        No existe una empresa constituida detrás de este sitio. Visitarlo, crear una cuenta de
        demostración o recorrer un pedido no genera una relación comercial, un contrato de
        prestación de servicios ni una obligación de pago real.
      </p>
      <h2>Contenido de demostración</h2>
      <p>
        Los profesionales, perfiles, reseñas, valoraciones y cifras son ficticios o de demostración.
        No representan personas, oficios ni resultados reales.
      </p>
      <h2>Pagos</h2>
      <p>
        Webpay y Oneclick operan en el ambiente de integración de Transbank. Los pagos se realizan
        con tarjetas de prueba; ninguna transacción es real y no se cobra dinero real. No ingreses
        datos de tarjetas reales. Las tarjetas públicas de ese ambiente están en la documentación de
        Transbank:{' '}
        <a href={TRANSBANK_TEST_CARDS_URL} rel="noopener noreferrer">
          tarjetas de prueba
        </a>
        .
      </p>
      <h2>Limitación de responsabilidad</h2>
      <p>
        El equipo del proyecto de título MyWorksApp ofrece el sitio tal cual, como material
        académico. No responde por decisiones tomadas al creer que es un servicio comercial, ni por
        pérdidas derivadas del uso del prototipo.
      </p>
      <h2>Duoc UC</h2>
      <p>
        Duoc UC no es responsable del contenido de este sitio, de los datos que se ingresen ni de
        los pedidos de demostración. El proyecto lo desarrolla el equipo del proyecto de título
        MyWorksApp.
      </p>
      <h2>Marcas de terceros</h2>
      <p>
        Transbank, Google y Cloudflare aparecen solo como integración técnica: el cobro con tarjeta,
        el inicio de sesión y la verificación anti-robots. No hay auspicio, patrocinio ni relación
        comercial con esas marcas.
      </p>
      <ContactBlock />
    </>
  );
}

function PrivacyBody() {
  return (
    <>
      <h2>Responsable</h2>
      <p>
        El responsable del tratamiento es el equipo del proyecto de título MyWorksApp. No hay una
        empresa ni una persona designada con un cargo comercial. Duoc UC no es responsable de estos
        datos ni del contenido del sitio.
      </p>
      <h2>Qué datos se recogen y para qué</h2>
      <p>
        Los datos se usan solo para operar este prototipo educativo y la encuesta de pruebas. No
        forman una base comercial.
      </p>
      <ul>
        <li>Cuenta: nombre, correo y contraseña (la guarda el servicio de acceso, no en texto plano), para entrar.</li>
        <li>Ficha: teléfono y direcciones, para simular una visita.</li>
        <li>Pedido: descripción, horario, dirección y, si usas el mapa o el GPS, coordenadas.</li>
        <li>Chat del pedido, fotos de evidencia y valoraciones de demostración.</li>
        <li>Encuesta de testing: rol, plataforma, respuestas y comentarios, para el informe de pruebas.</li>
        <li>Verificación anti-robots de Cloudflare (Turnstile): un token de que no eres un robot.</li>
        <li>
          Si entras con Google, ese proveedor entrega la identidad de la cuenta. El número de la
          tarjeta de prueba se escribe en Transbank, en su ambiente de integración. Este sitio no
          pide ni guarda el número ni el código de seguridad. Si inscribes una tarjeta de prueba,
          solo pueden quedar visibles los últimos cuatro dígitos. Ninguna transacción mueve dinero
          real.
        </li>
      </ul>
      <h2>Ley 19.628</h2>
      <p>
        El tratamiento se limita a lo necesario para el prototipo, conforme a la Ley 19.628 sobre
        protección de la vida privada. Puedes pedir la eliminación de tus datos. Si tienes cuenta,
        entra a <Link to="/cuenta">Mi cuenta</Link> y usa «Solicitar eliminación»: anonimiza el
        nombre y el correo, borra el teléfono, la foto y las direcciones, y marca la cuenta como
        eliminada. Si no puedes entrar, o esa acción no está disponible, usa la encuesta de testing.
        La revisa el equipo del proyecto de título MyWorksApp.
      </p>
      <p>Los datos de prueba se borran periódicamente.</p>
      <h2>Pagos y marcas</h2>
      <p>
        Webpay y Oneclick operan en el ambiente de integración de Transbank. Los pagos se realizan
        con tarjetas de prueba; ninguna transacción es real y no se cobra dinero real. No ingreses
        datos de tarjetas reales. Transbank, Google y Cloudflare se usan solo como integración
        técnica. Las tarjetas públicas están en la documentación de Transbank:{' '}
        <a href={TRANSBANK_TEST_CARDS_URL} rel="noopener noreferrer">
          tarjetas de prueba
        </a>
        .
      </p>
      <ContactBlock />
    </>
  );
}

function ContactBlock() {
  return (
    <>
      <h2>Contacto académico</h2>
      <p>
        No hay un correo personal publicado para este proyecto. Para una consulta académica o para
        pedir la eliminación de datos de prueba, usa la encuesta de testing de este sitio o, si ya
        tienes cuenta, <Link to="/cuenta">Mi cuenta</Link>.
      </p>
      <p>
        <button type="button" className="btn-outline-orange" onClick={openTestingSurvey}>
          Abrir la encuesta de testing
        </button>
      </p>
    </>
  );
}
