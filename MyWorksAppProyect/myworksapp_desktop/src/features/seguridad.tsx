import { useEffect, useState, type KeyboardEvent as ReactKeyboardEvent } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { consolePermissions } from '../authAccess';
import { useAuth } from '../context/auth-store';
import { friendlyError } from '../lib/errors';
import { formatDateTime } from '../lib/format';
import { callRpc } from '../lib/rpc';
import { supabase } from '../supabaseClient';
import { ConfirmDialog } from '../ui/ConfirmDialog';
import { Badge, Button, EmptyState, ErrorState, SkeletonRows } from '../ui/kit';
import { useToast } from '../ui/toast-store';
import { asNum, asRows, asText } from './seguridad-model';
import { SeguridadHerramientas } from './seguridad-herramientas';
import { Banda } from './premium/Banda';

type Accion =
  | { kind: 'umbral'; clave: string; valor: number }
  | { kind: 'incidente'; id: string }
  | { kind: 'suspender' | 'reactivar' | 'bloquear' | 'desbloquear' | 'sesiones' | 'reset'; id: string };

export function SeguridadPage() {
  const admin = consolePermissions(useAuth().profile?.role ?? '').people;
  const toast = useToast();
  const client = useQueryClient();
  const [accion, setAccion] = useState<Accion | null>(null);
  const [persona, setPersona] = useState('');
  const [tab, setTab] = useState<Pestana>('resumen');
  const [drafts, setDrafts] = useState<Record<string, string>>({});
  const panel = useQuery({
    queryKey: ['seguridad'],
    enabled: admin,
    refetchInterval: 8_000,
    queryFn: () => callRpc<Record<string, unknown>>('consola_seguridad_ciclo'),
  });
  const ficha = useQuery({
    queryKey: ['seguridad-usuario', persona],
    enabled: admin && persona.trim().length >= 8,
    queryFn: () => callRpc<Record<string, unknown>>('consola_seguridad_usuario', { p_id: persona.trim() }),
  });

  useEffect(() => {
    if (!admin) return;
    const channel = supabase
      .channel('incidentes-seguridad')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'incidentes_seguridad' }, () => {
        void client.invalidateQueries({ queryKey: ['seguridad'] });
      })
      .subscribe();
    return () => {
      void supabase.removeChannel(channel);
    };
  }, [admin, client]);

  if (!admin) return <EmptyState title="Sin permiso" detail="El panel de seguridad es solo para administración." />;

  const data = panel.data ?? {};
  const umbrales = asRows(data.umbrales);
  const incidentes = asRows(data.incidentes);
  const auth = asRows(data.auditoria_auth);
  const mfa = asRows(data.mfa);
  const sesiones = asRows(data.sesiones_consola);
  const abuso = asRows(data.reportes_abuso);
  const rls = Array.isArray(data.rls_sin_politica) ? data.rls_sin_politica.map(String) : [];
  const servicio = data.servicio && typeof data.servicio === 'object' ? data.servicio as Record<string, unknown> : {};

  const confirmar = async (motivo: string) => {
    if (!accion) return;
    if (accion.kind === 'umbral') {
      await callRpc('consola_editar_umbral', { p_clave: accion.clave, p_valor: accion.valor, p_motivo: motivo });
      return;
    }
    if (accion.kind === 'incidente') {
      await callRpc('consola_reconocer_incidente', { p_id: accion.id, p_motivo: motivo });
      return;
    }
    if (accion.kind === 'suspender' || accion.kind === 'reactivar') {
      const { error } = await supabase.rpc('consola_fijar_estado_cuenta', {
        p_id: accion.id,
        p_estado: accion.kind === 'suspender' ? 'suspendido' : 'activo',
        p_motivo: motivo,
      });
      if (error) throw error;
      return;
    }
    if (accion.kind === 'bloquear' || accion.kind === 'desbloquear') {
      await callRpc('consola_bloquear_cuenta', {
        p_id: accion.id,
        p_bloquear: accion.kind === 'bloquear',
        p_motivo: motivo,
      });
      return;
    }
    if (accion.kind === 'sesiones') {
      await callRpc('consola_cerrar_sesion_persona', { p_id: accion.id, p_motivo: motivo });
      return;
    }
    await callRpc('consola_forzar_reset', { p_id: accion.id, p_motivo: motivo });
  };

  return (
    <section className="stack">
      <div className="spread">
        <div>
          <h1>Seguridad</h1>
          <p className="muted">Se actualiza cada 8 segundos. Los incidentes también llegan por Realtime.</p>
        </div>
        <span className="muted nums">{panel.data ? `Actualizado ${formatDateTime(asText(data.generado_en, ''))}` : 'Esperando datos'}</span>
      </div>
      <Banda seccion="seguridad" />
      {panel.isLoading ? <SkeletonRows /> : null}
      {panel.isError ? <ErrorState message="No se pudo leer el panel de seguridad." onRetry={() => void panel.refetch()} /> : null}
      <div className="tablist" role="tablist" aria-label="Seguridad" onKeyDown={(event) => moverPestana(event, tab, setTab)}>
        {PESTANAS.map(([id, label]) => (
          <button
            key={id}
            type="button"
            role="tab"
            id={`pestana-${id}`}
            aria-selected={tab === id}
            aria-controls={`panel-${id}`}
            className={tab === id ? 'is-active' : undefined}
            onClick={() => setTab(id)}
          >
            {label}
          </button>
        ))}
      </div>
      <div role="tabpanel" id={`panel-${tab}`} aria-labelledby={`pestana-${tab}`} className="stack">
      {tab === 'resumen' ? (
      <>
      <div className="kpi-grid">
        <Meter label="Accesos fallidos" value={asNum(data.logins_fallidos)} />
        <Meter label="Errores en la ventana" value={asNum(data.errores)} />
        <Meter label="Disputas en la ventana" value={asNum(data.disputas_activas_ventana)} />
        <Meter label="Altas recientes" value={asNum(data.altas)} />
        <Meter label="Pagos retenidos viejos" value={asNum(data.pagos_retenidos_viejos)} />
      </div>

      <article className="panel stack">
        <h2>Servicio</h2>
        <p>Base de datos: {asText(servicio.base)}</p>
        <p className="muted">{asText(servicio.edge)}</p>
        <p>{asText(data.turnstile)}</p>
        {rls.length === 0 ? <p className="muted">No hay tablas con RLS y cero políticas en este corte.</p> : (
          <ul className="timeline">
            {rls.map((name) => <li key={name}>RLS sin política: {name}</li>)}
          </ul>
        )}
      </article>

      </>
      ) : null}
      {tab === 'actividad' ? (
      <>
      <article className="panel stack">
        <h2>Actividad reciente de acceso</h2>
        {auth.length === 0 ? <EmptyState title="Sin eventos de Auth en las últimas 24 horas." detail="Los intentos fallidos de esta consola se suman aunque GoTrue no los guarde." /> : null}
        <ul className="timeline">
          {auth.map((row, index) => (
            <li key={`${asText(row.cuando)}-${index}`}>{formatDateTime(asText(row.cuando, ''))} · {asText(row.accion)} · {asText(row.correo)} · {asText(row.ip)}</li>
          ))}
        </ul>
      </article>

      <div className="split">
        <article className="panel stack">
          <h2>MFA</h2>
          {mfa.length === 0 ? <p className="muted">Sin cambios de factores en 24 horas.</p> : null}
          <ul className="timeline">
            {mfa.map((row, index) => (
              <li key={`${asText(row.usuario)}-${index}`}>{asText(row.tipo)} · {asText(row.estado)} · {formatDateTime(asText(row.cuando, ''))}</li>
            ))}
          </ul>
        </article>
        <article className="panel stack">
          <h2>Sesiones de la consola</h2>
          {sesiones.length === 0 ? <p className="muted">No hay sesiones nuevas de administración, soporte o QA.</p> : null}
          <ul className="timeline">
            {sesiones.map((row, index) => (
              <li key={`${asText(row.usuario)}-${index}`}>{asText(row.nombre)} · {asText(row.rol)} · {formatDateTime(asText(row.cuando, ''))}</li>
            ))}
          </ul>
        </article>
      </div>

      <article className="panel stack">
        <h2>Abuso de reportes</h2>
        {abuso.length === 0 ? <EmptyState title="Nadie supera el umbral de reportes." /> : null}
        {abuso.map((row) => (
          <div key={asText(row.usuario)} className="spread">
            <span>{asText(row.usuario)} · {asNum(row.cantidad)} reportes</span>
            <Button variant="secondary" onClick={() => setPersona(asText(row.usuario, ''))}>Ver persona</Button>
          </div>
        ))}
      </article>

      <article className="panel stack">
        <h2>Incidentes</h2>
        {incidentes.length === 0 ? <EmptyState title="No hay incidentes en el historial." detail="Se abren solos cuando un conteo cruza su umbral." /> : null}
        {incidentes.map((row) => (
          <div key={asText(row.id)} className="spread">
            <div>
              <strong>{asText(row.resumen)}</strong>
              <p className="muted">{formatDateTime(asText(row.cuando, ''))} · {asText(row.tipo)}</p>
            </div>
            <div className="row">
              <Badge value={asText(row.severidad)} />
              <Badge value={asText(row.estado)} />
              {asText(row.estado) === 'abierto' ? (
                <Button variant="secondary" onClick={() => setAccion({ kind: 'incidente', id: asText(row.id, '') })}>Reconocer</Button>
              ) : null}
            </div>
          </div>
        ))}
      </article>

      </>
      ) : null}
      {tab === 'umbrales' ? (
      <article className="panel stack">
        <h2>Umbrales</h2>
        {umbrales.map((row) => {
          const clave = asText(row.clave, '');
          return (
            <div key={clave} className="spread">
              <label className="field">
                <span>{asText(row.descripcion)} · ventana {asNum(row.ventana_minutos)} min · actual {asNum(row.valor)}</span>
                <input
                  inputMode="numeric"
                  aria-label={`Umbral ${clave}`}
                  value={drafts[clave] ?? String(asNum(row.valor))}
                  onChange={(event) => setDrafts({ ...drafts, [clave]: event.target.value })}
                />
              </label>
              <Button variant="secondary" onClick={() => {
                const valor = Number(drafts[clave] ?? row.valor);
                if (!Number.isInteger(valor)) {
                  toast('El umbral tiene que ser un entero.');
                  return;
                }
                setAccion({ kind: 'umbral', clave, valor });
              }}>Guardar</Button>
            </div>
          );
        })}
      </article>
      ) : null}
      {tab === 'pruebas' || tab === 'defensa' || tab === 'respaldos' ? <SeguridadHerramientas tab={tab} /> : null}
      {tab === 'actividad' ? (
      <article className="panel stack">
        <h2>Persona</h2>
        <label className="field">
          <span>Identificador</span>
          <input value={persona} onChange={(event) => setPersona(event.target.value)} placeholder="uuid" aria-label="Identificador de la persona" />
        </label>
        {ficha.isError ? <ErrorState message="No se pudo leer a esa persona." onRetry={() => void ficha.refetch()} /> : null}
        {ficha.data ? (
          <div className="stack">
            <p>{asText(ficha.data.nombre)} · {asText(ficha.data.correo)} · <Badge value={asText(ficha.data.estado_cuenta)} /></p>
            <p className="muted">Reportes {asNum(ficha.data.reportes)} · errores {asNum(ficha.data.errores)} · sesiones {asNum(ficha.data.sesiones_abiertas)}</p>
            <div className="row">
              <Button variant="danger" onClick={() => setAccion({ kind: 'suspender', id: persona.trim() })}>Suspender</Button>
              <Button variant="secondary" onClick={() => setAccion({ kind: 'reactivar', id: persona.trim() })}>Reactivar</Button>
              <Button variant="danger" onClick={() => setAccion({ kind: 'bloquear', id: persona.trim() })}>Bloquear acceso</Button>
              <Button variant="secondary" onClick={() => setAccion({ kind: 'desbloquear', id: persona.trim() })}>Quitar bloqueo</Button>
              <Button variant="secondary" onClick={() => setAccion({ kind: 'sesiones', id: persona.trim() })}>Cerrar sesiones</Button>
              <Button variant="danger" onClick={() => setAccion({ kind: 'reset', id: persona.trim() })}>Forzar reset</Button>
            </div>
          </div>
        ) : null}
      </article>
      ) : null}
      </div>

      {accion ? (
        <ConfirmDialog
          title={tituloAccion(accion)}
          summary={resumenAccion(accion)}
          irreversible={accion.kind === 'bloquear' || accion.kind === 'reset' || accion.kind === 'sesiones'}
          onCancel={() => setAccion(null)}
          onConfirm={(motivo) => {
            void confirmar(motivo).then(async () => {
              toast('Acción registrada en la bitácora.');
              setAccion(null);
              await client.invalidateQueries({ queryKey: ['seguridad'] });
              await client.invalidateQueries({ queryKey: ['seguridad-usuario'] });
              await client.invalidateQueries({ queryKey: ['auditoria'] });
            }).catch((error: unknown) => {
              toast(error instanceof Error ? error.message : friendlyError(error as { message?: string }));
            });
          }}
        />
      ) : null}
    </section>
  );
}

const PESTANAS = [
  ['resumen', 'Resumen'],
  ['actividad', 'Actividad'],
  ['pruebas', 'Pruebas'],
  ['defensa', 'Defensa'],
  ['respaldos', 'Respaldos'],
  ['umbrales', 'Umbrales'],
] as const;

type Pestana = (typeof PESTANAS)[number][0];

function moverPestana(event: ReactKeyboardEvent, actual: Pestana, setTab: (tab: Pestana) => void) {
  const ids = PESTANAS.map(([id]) => id);
  const index = ids.indexOf(actual);
  if (event.key === 'ArrowRight') setTab(ids[(index + 1) % ids.length]);
  if (event.key === 'ArrowLeft') setTab(ids[(index - 1 + ids.length) % ids.length]);
}

function Meter({ label, value }: { label: string; value: number }) {
  return (
    <article className="card kpi">
      <span className="muted">{label}</span>
      <strong className="nums">{value}</strong>
    </article>
  );
}

function tituloAccion(accion: Accion): string {
  switch (accion.kind) {
    case 'umbral': return `Cambiar umbral ${accion.clave}`;
    case 'incidente': return 'Reconocer incidente';
    case 'suspender': return 'Suspender cuenta';
    case 'reactivar': return 'Reactivar cuenta';
    case 'bloquear': return 'Bloquear acceso';
    case 'desbloquear': return 'Quitar bloqueo';
    case 'sesiones': return 'Cerrar sesiones';
    case 'reset': return 'Forzar cambio de clave';
    default: return 'Confirmar';
  }
}

function resumenAccion(accion: Accion): string {
  if (accion.kind === 'umbral') return `El umbral ${accion.clave} pasará a ${accion.valor}.`;
  if (accion.kind === 'reset') return 'Se cierran las sesiones y la cuenta queda marcada para recuperar la clave. No se envía un correo desde aquí.';
  if (accion.kind === 'bloquear') return 'La persona no podrá iniciar sesión y su cuenta queda suspendida.';
  if (accion.kind === 'sesiones') return 'Se cierran las sesiones abiertas. La cuenta sigue existiendo.';
  return 'El cambio queda en la bitácora.';
}
