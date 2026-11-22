import { sugerenciaDesdeTexto } from "@myworksapp/shared";
import { Badge } from "../ui/kit";

const sugerencia = sugerenciaDesdeTexto("se rompió una cañería y hay una fuga hoy en Puerto Montt");

/** Pantalla fija para las capturas. No se muestra si VITE_IA_PREVIEW no está en 1. */
export function IaVista() {
  return (
    <main className="stack" style={{ padding: 24, maxWidth: 960, margin: "0 auto" }}>
      <h1>IA en MyWorksApp</h1>
      <article className="panel stack" id="busqueda">
        <h2>Búsqueda híbrida</h2>
        <p className="muted">Búsqueda híbrida. Si falla, volvemos al catálogo.</p>
        <p><strong>Gasfiter cerca</strong> · nota 4,8 · similitud 0,82</p>
        <p><strong>Gasfiter centro</strong> · nota 4,6 · similitud 0,74</p>
      </article>
      <article className="panel stack" id="asistente">
        <h2>Sugerencia de la IA</h2>
        <p>{sugerencia.aviso}</p>
        <p>Categoría {sugerencia.categoria}. Urgencia {sugerencia.urgencia}.</p>
        <p>Rango ${sugerencia.precio_min_clp.toLocaleString("es-CL")} a ${sugerencia.precio_max_clp.toLocaleString("es-CL")}.</p>
      </article>
      <article className="panel stack" id="moderacion">
        <h2>Cola de moderación</h2>
        <p className="muted">La IA marca el mensaje y avisa. No lo borra.</p>
        <div className="spread">
          <strong>pago por fuera</strong>
          <Badge value="pendiente" />
        </div>
        <p>¿Me puedes pagar por fuera de la app?</p>
        <p className="muted">Un administrador confirma o descarta. El mensaje sigue en el chat.</p>
      </article>
      <article className="panel stack" id="alertas">
        <h2>Alertas de IA</h2>
        <p className="muted">Son propuestas. Reconocer no bloquea la cuenta.</p>
        <div className="spread">
          <strong>Cambió la cuenta bancaria y hubo un retiro en la ventana</strong>
          <Badge value="alta" />
        </div>
        <p>Isolation Forest: apagado, solo reglas.</p>
      </article>
    </main>
  );
}
