import { useEffect, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { consolePermissions } from "../authAccess";
import { useAuth } from "../context/auth-store";
import { friendlyError } from "../lib/errors";
import { formatDateTime } from "../lib/format";
import { callRpc } from "../lib/rpc";
import { supabase } from "../supabaseClient";
import { ConfirmDialog } from "../ui/ConfirmDialog";
import { Badge, Button, EmptyState, ErrorState, SkeletonRows } from "../ui/kit";
import { useToast } from "../ui/toast-store";
import { leerModeracion, type MarcaModeracion } from "./ia-consola";

export function ModeracionPage() {
  const permisos = consolePermissions(useAuth().profile?.role ?? "");
  const admin = permisos.viewPeople;
  const decide = permisos.people;
  const toast = useToast();
  const client = useQueryClient();
  const [marca, setMarca] = useState<{ fila: MarcaModeracion; estado: "confirmado" | "descartado" } | null>(null);
  const lista = useQuery({
    queryKey: ["moderacion-ia"],
    enabled: admin,
    refetchInterval: 15_000,
    queryFn: async () => leerModeracion(await callRpc("consola_listar_moderacion", { p_limite: 40 })),
  });

  useEffect(() => {
    if (!admin) return;
    const channel = supabase
      .channel("cola-moderacion")
      .on("postgres_changes", { event: "*", schema: "public", table: "cola_moderacion" }, () => {
        void client.invalidateQueries({ queryKey: ["moderacion-ia"] });
      })
      .subscribe();
    return () => {
      void supabase.removeChannel(channel);
    };
  }, [admin, client]);

  if (!admin) return <EmptyState title="Sin permiso" detail="La cola de moderación es para administración." />;

  return (
    <section className="stack">
      <div>
        <h1>Moderación</h1>
        <p className="muted">La IA marca el mensaje y avisa. No lo borra. Confirmar o descartar queda en la bitácora.</p>
      </div>
      {lista.isLoading ? <SkeletonRows /> : null}
      {lista.isError ? <ErrorState message="La cola todavía no está en esta base. Aplica la migración de IA en local." onRetry={() => void lista.refetch()} /> : null}
      {!lista.isLoading && !lista.isError && (lista.data ?? []).length === 0 ? (
        <EmptyState title="No hay mensajes marcados." detail="Teléfono, correo, cuenta, pago por fuera, insulto o un caso dudoso aparecen aquí." />
      ) : null}
      {(lista.data ?? []).map((fila) => (
        <article key={fila.id} className="panel stack">
          <div className="spread">
            <strong>{fila.motivo || "marca"}</strong>
            <span className="row">
              <Badge value={fila.estado || "pendiente"} />
              {fila.veredicto ? <Badge value={fila.veredicto} /> : null}
            </span>
          </div>
          <p>{fila.extracto || "Sin extracto."}</p>
          <p className="muted">{formatDateTime(fila.cuando)} · {fila.detalle || "regla"}</p>
          {decide && fila.estado === "pendiente" ? (
            <div className="row">
              <Button onClick={() => setMarca({ fila, estado: "confirmado" })}>Confirmar marca</Button>
              <Button variant="secondary" onClick={() => setMarca({ fila, estado: "descartado" })}>Descartar</Button>
            </div>
          ) : null}
        </article>
      ))}
      {marca ? (
        <ConfirmDialog
          title={marca.estado === "confirmado" ? "Confirmar la marca" : "Descartar la marca"}
          summary="El mensaje sigue en el chat. Esta acción solo registra tu revisión."
          irreversible={false}
          onCancel={() => setMarca(null)}
          onConfirm={(motivo) => {
            void callRpc("consola_revisar_moderacion", {
              p_id: marca.fila.id,
              p_estado: marca.estado,
              p_motivo: motivo,
            }).then(async () => {
              toast("Revisión guardada en la bitácora.");
              setMarca(null);
              await client.invalidateQueries({ queryKey: ["moderacion-ia"] });
            }).catch((error: unknown) => {
              toast(error instanceof Error ? error.message : friendlyError(error as { message?: string }));
            });
          }}
        />
      ) : null}
    </section>
  );
}
