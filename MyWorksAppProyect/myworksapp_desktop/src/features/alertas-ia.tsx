import { useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { friendlyError } from "../lib/errors";
import { formatDateTime } from "../lib/format";
import { callRpc } from "../lib/rpc";
import { ConfirmDialog } from "../ui/ConfirmDialog";
import { Badge, Button, EmptyState, ErrorState } from "../ui/kit";
import { useToast } from "../ui/toast-store";
import { leerAlertasIa } from "./ia-consola";

export function AlertasIaPanel() {
  const toast = useToast();
  const client = useQueryClient();
  const [incidente, setIncidente] = useState<string | null>(null);
  const [bandera, setBandera] = useState<boolean | null>(null);
  const panel = useQuery({
    queryKey: ["alertas-ia"],
    queryFn: async () => leerAlertasIa(await callRpc("consola_alertas_ia")),
  });

  if (panel.isError) {
    return <ErrorState message="Las alertas de IA llegan con la migración local. El resto de Seguridad sigue igual." onRetry={() => void panel.refetch()} />;
  }

  const alertas = panel.data?.alertas ?? [];
  const activa = panel.data?.bandera === true;

  return (
    <div className="stack">
      <article className="panel stack">
        <h2>Alertas de IA</h2>
        <p className="muted">Son propuestas. Reconocer no bloquea la cuenta ni frena un retiro. Eso se hace, si corresponde, en Actividad.</p>
        <p>Isolation Forest: {activa ? "activo" : "apagado, solo reglas"}.</p>
        <Button variant="secondary" onClick={() => setBandera(!activa)}>
          {activa ? "Apagar el modelo" : "Activar el modelo"}
        </Button>
      </article>
      {alertas.length === 0 ? <EmptyState title="No hay alertas de IA." detail="Las reglas miran reseñas, dispositivos, accesos, disputas y cambios de cuenta." /> : null}
      {alertas.map((alerta) => (
        <article key={alerta.id} className="panel stack">
          <div className="spread">
            <strong>{alerta.resumen}</strong>
            <span className="row">
              <Badge value={alerta.severidad} />
              <Badge value={alerta.estado || "abierto"} />
            </span>
          </div>
          <p className="muted">{formatDateTime(alerta.cuando)} · {alerta.tipo}</p>
          {alerta.detalle ? <p>{alerta.detalle}</p> : null}
          {alerta.estado === "abierto" ? (
            <Button variant="secondary" onClick={() => setIncidente(alerta.id)}>Reconocer propuesta</Button>
          ) : null}
        </article>
      ))}
      {incidente ? (
        <ConfirmDialog
          title="Reconocer alerta"
          summary="Queda en la bitácora. No suspende ni bloquea a nadie."
          irreversible={false}
          onCancel={() => setIncidente(null)}
          onConfirm={(motivo) => {
            void callRpc("consola_reconocer_incidente", { p_id: incidente, p_motivo: motivo }).then(async () => {
              toast("Alerta reconocida.");
              setIncidente(null);
              await client.invalidateQueries({ queryKey: ["alertas-ia"] });
              await client.invalidateQueries({ queryKey: ["seguridad"] });
            }).catch((error: unknown) => {
              toast(error instanceof Error ? error.message : friendlyError(error as { message?: string }));
            });
          }}
        />
      ) : null}
      {bandera != null ? (
        <ConfirmDialog
          title={bandera ? "Activar Isolation Forest" : "Dejar solo las reglas"}
          summary="Con pocos eventos el job no escribe alertas aunque la bandera esté activa."
          irreversible={false}
          onCancel={() => setBandera(null)}
          onConfirm={(motivo) => {
            void callRpc("consola_fijar_bandera_ia", {
              p_clave: "anomalias_isolation_forest",
              p_activa: bandera,
              p_motivo: motivo,
            }).then(async () => {
              toast("Bandera actualizada.");
              setBandera(null);
              await client.invalidateQueries({ queryKey: ["alertas-ia"] });
            }).catch((error: unknown) => {
              toast(error instanceof Error ? error.message : friendlyError(error as { message?: string }));
            });
          }}
        />
      ) : null}
    </div>
  );
}
