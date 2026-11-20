import { useState, type ReactNode } from 'react';
import { Link, useParams } from 'react-router';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { edgeFunctionErrorMessage } from '@myworksapp/shared';
import { consolePermissions } from '../authAccess';
import { useAuth } from '../context/auth-store';
import { friendlyError } from '../lib/errors';
import { formatClp, formatDateTime, maskId, maskRut, statusLabel } from '../lib/format';
import { markTotpVerified, totpFresh } from '../lib/totp';
import { setSharedDevice, sharedDeviceEnabled } from '../lib/session';
import { supabase } from '../supabaseClient';
import { ConfirmDialog } from '../ui/ConfirmDialog';
import { Badge, Button, CopyId, EmptyState, ErrorState, SkeletonRows } from '../ui/kit';
import { useToast } from '../ui/toast-store';
import { PagedTable, type PageResult } from './table';

const PAGE = 25;

function clean(value: string): string {
  return value.replace(/[%_,]/g, '').slice(0, 60);
}

function Gate({ allow, children }: { allow: boolean; children: ReactNode }) {
  if (!allow) return <EmptyState title="Sin permiso" detail="Tu rol no incluye este módulo." />;
  return children;
}

async function reverify(code: string): Promise<boolean> {
  if (totpFresh()) return true;
  const listed = await supabase.auth.mfa.listFactors();
  const factor = listed.data?.totp.find((item) => item.status === 'verified');
  if (!factor) return false;
  const challenge = await supabase.auth.mfa.challenge({ factorId: factor.id });
  if (challenge.error || !challenge.data) return false;
  const verified = await supabase.auth.mfa.verify({
    factorId: factor.id,
    challengeId: challenge.data.id,
    code,
  });
  if (verified.error) return false;
  markTotpVerified();
  return true;
}

export function ResumenPage() {
  const { profile } = useAuth();
  const permissions = consolePermissions(profile?.role ?? '');
  const [days, setDays] = useState(7);
  const query = useQuery({
    queryKey: ['resumen', days],
    queryFn: async () => {
      const hasta = new Date();
      const desde = new Date(hasta.getTime() - days * 86_400_000);
      const prevHasta = new Date(desde.getTime());
      const prevDesde = new Date(prevHasta.getTime() - days * 86_400_000);
      const current = await supabase.rpc('consola_resumen_periodo', {
        p_desde: desde.toISOString(),
        p_hasta: hasta.toISOString(),
      });
      if (current.error) throw current.error;
      const previous = await supabase.rpc('consola_resumen_periodo', {
        p_desde: prevDesde.toISOString(),
        p_hasta: prevHasta.toISOString(),
      });
      return { current: current.data, previous: previous.data };
    },
  });
  const data = asRecord(query.data?.current);
  const prev = asRecord(asRecord(query.data?.previous).financiero);
  const financiero = asRecord(data.financiero);
  const colas = asRecord(data.colas);
  return (
    <section className="stack">
      <div className="spread">
        <div>
          <h1>Inicio</h1>
          <p className="muted">Zona America/Santiago. {days === 1 ? 'Últimas 24 horas' : `Últimos ${days} días`}.</p>
        </div>
        <div className="row">
          {[1, 7, 30, 90].map((value) => (
            <Button key={value} variant={days === value ? 'primary' : 'secondary'} onClick={() => setDays(value)}>
              {value === 1 ? '24 h' : `${value} días`}
            </Button>
          ))}
        </div>
      </div>
      {query.isLoading ? <SkeletonRows /> : null}
      {query.isError ? <ErrorState message="No se pudo cargar el resumen." onRetry={() => void query.refetch()} /> : null}
      {permissions.executive && financiero.gmv_clp != null ? (
        <div className="kpi-grid">
          <Kpi label="GMV" value={formatClp(num(financiero.gmv_clp))} delta={delta(num(financiero.gmv_clp), num(prev.gmv_clp))} />
          <Kpi label="Comisión" value={formatClp(num(financiero.comision_clp))} delta={delta(num(financiero.comision_clp), num(prev.comision_clp))} />
          <Kpi label="Ticket promedio" value={formatClp(num(financiero.ticket_promedio_clp))} delta="Según los pagos del período" />
          <Kpi label="CSAT" value={financiero.csat == null ? 'Sin reseñas en el período' : String(Number(financiero.csat).toFixed(2))} delta={`${num(financiero.n_resenas)} reseñas`} />
        </div>
      ) : null}
      {!permissions.executive ? <p className="muted">Tu rol ve las colas, no los indicadores de dinero.</p> : null}
      <div className="queue-grid">
        <Queue to="/disputas" label="Disputas abiertas" value={colas.disputas_abiertas} />
        {permissions.verifyPeople ? <Queue to="/profesionales" label="Verificaciones en revisión" value={colas.verificaciones_en_revision} /> : null}
        {permissions.viewMoney ? <Queue to="/pagos" label="Pagos retenidos" value={colas.pagos_retenidos} /> : null}
        {permissions.viewMoney ? <Queue to="/reembolsos" label="Reembolsos pendientes" value={colas.reembolsos_pendientes} /> : null}
        <Queue to="/tickets" label="Tickets sin resolver" value={colas.tickets_abiertos} />
        {permissions.viewErrors ? <Queue to="/errores" label="Errores nuevos" value={colas.errores_nuevos} /> : null}
      </div>
      <p className="muted">No hay fecha de término del trabajo en la base, así que este resumen no cuenta «completados».</p>
    </section>
  );
}

function Kpi({ label, value, delta }: { label: string; value: string; delta: string }) {
  return (
    <article className="card kpi">
      <span className="muted">{label}</span>
      <strong className="nums">{value}</strong>
      <span className="muted">{delta}</span>
    </article>
  );
}

function Queue({ to, label, value }: { to: string; label: string; value: unknown }) {
  return (
    <Link to={to} className="card">
      <span className="muted">{label}</span>
      <strong className="nums">{value == null ? '—' : String(value)}</strong>
    </Link>
  );
}

export function PedidosPage() {
  const { id } = useParams();
  return (
    <Gate allow={consolePermissions(useAuth().profile?.role ?? '').viewOrders}>
      <h1>Pedidos</h1>
      <PagedTable
        queryKey={['pedidos']}
        empty="Aún no hay pedidos con ese filtro."
        load={(page, search) => loadPage('trabajos', page, search, 'id, estado, direccion, creado_en, id_usuario')}
        columns={[
          { key: 'id', header: 'Pedido', cell: (row) => <CopyId value={row.id} />, csv: (row) => row.id },
          { key: 'estado', header: 'Estado', cell: (row) => <Badge value={String(row.estado)} />, csv: (row) => statusLabel(String(row.estado)) },
          { key: 'direccion', header: 'Dirección', cell: (row) => String(row.direccion ?? '—'), csv: (row) => row.direccion },
          { key: 'fecha', header: 'Creado', cell: (row) => formatDateTime(String(row.creado_en ?? '')), csv: (row) => row.creado_en },
        ]}
        onRow={(row) => { window.location.assign(`/pedidos/${row.id}`); }}
      />
      {id ? <PedidoFicha id={id} /> : null}
    </Gate>
  );
}

function PedidoFicha({ id }: { id: string }) {
  const query = useQuery({
    queryKey: ['pedido', id],
    queryFn: async () => {
      const job = await supabase.from('trabajos').select('id, estado, direccion, descripcion, creado_en, fecha_programada, id_usuario, id_trabajador').eq('id', id).maybeSingle();
      if (job.error) throw job.error;
      const pagos = await supabase.from('pagos').select('id, estado, monto, creado_en').eq('id_trabajo', id);
      return { job: job.data, pagos: pagos.data ?? [] };
    },
  });
  if (query.isLoading) return <SkeletonRows />;
  if (!query.data?.job) return <EmptyState title="No se encontró el pedido." />;
  const job = query.data.job;
  return (
    <article className="panel stack">
      <h2>Ficha del pedido</h2>
      <Badge value={job.estado} />
      <p>{job.descripcion || 'Sin descripción.'}</p>
      <p className="muted">{job.direccion}</p>
      <ol className="timeline">
        <li>Creado {formatDateTime(job.creado_en)}</li>
        <li>Estado actual: {statusLabel(job.estado)}</li>
        {query.data.pagos.map((pago) => (
          <li key={pago.id}>Pago {statusLabel(pago.estado)} · {formatClp(pago.monto)}</li>
        ))}
      </ol>
    </article>
  );
}

export function DisputasPage() {
  const { profile } = useAuth();
  const permissions = consolePermissions(profile?.role ?? '');
  const toast = useToast();
  const client = useQueryClient();
  const [decision, setDecision] = useState<{ id: string; decision: 'liberar' | 'reembolsar'; monto: string } | null>(null);
  const [busy, setBusy] = useState(false);
  const [tab, setTab] = useState<'abiertas' | 'resueltas'>('abiertas');
  const query = useQuery({
    queryKey: ['disputas', tab],
    queryFn: async () => {
      if (tab === 'resueltas') {
        const { data, error } = await supabase.rpc('consola_disputas_resueltas');
        if (error) throw error;
        return (data ?? []).map((row) => ({ ...row, decision_sugerida: null as string | null, motivo_regla: null as string | null, vence_en: null as string | null }));
      }
      const { data, error } = await supabase.rpc('consola_disputas_abiertas');
      if (error) throw error;
      return (data ?? []).map((row) => ({ ...row, resolucion: null as string | null, resuelta_en: null as string | null }));
    },
    refetchInterval: tab === 'abiertas' ? 30_000 : false,
  });
  return (
    <Gate allow={permissions.supportQueue}>
      <h1>Disputas</h1>
      <div className="tabs">
        <button type="button" className={tab === 'abiertas' ? 'is-active' : undefined} onClick={() => setTab('abiertas')}>Abiertas</button>
        <button type="button" className={tab === 'resueltas' ? 'is-active' : undefined} onClick={() => setTab('resueltas')}>Resueltas</button>
      </div>
      {query.isLoading ? <SkeletonRows /> : null}
      {query.isError ? <ErrorState message="No se pudo cargar la cola." onRetry={() => void query.refetch()} /> : null}
      {!query.isLoading && query.data?.length === 0 ? (
        <EmptyState title={tab === 'abiertas' ? 'No hay disputas que requieran una persona.' : 'Aún no hay disputas resueltas.'} />
      ) : null}
      <div className="stack">
        {(query.data ?? []).map((row) => (
          <article key={row.id} className="panel stack">
            <div className="spread">
              <strong>{row.motivo}</strong>
              <Badge value={row.estado} />
            </div>
            <p>{row.nombre_cliente} · {row.nombre_profesional} · {formatClp(row.monto_retenido)}</p>
            {tab === 'resueltas' ? (
              <p className="muted">Resolución: {row.resolucion || 'Sin texto de resolución.'} · {formatDateTime(row.resuelta_en)}</p>
            ) : (
              <p className="muted">Sugerencia: {statusLabel(row.decision_sugerida)} · {row.motivo_regla || 'Sin regla'} · vence {formatDateTime(row.vence_en)}</p>
            )}
            {permissions.disputeEvidence ? <Evidencia id={row.id} /> : <p className="muted">Tu rol no ve la evidencia.</p>}
            {tab === 'abiertas' && permissions.resolveDisputes ? (
              <div className="row">
                <Button onClick={() => setDecision({ id: row.id, decision: 'liberar', monto: formatClp(row.monto_retenido) })}>Liberar al profesional</Button>
                <Button variant="danger" onClick={() => setDecision({ id: row.id, decision: 'reembolsar', monto: formatClp(row.monto_retenido) })}>Devolver a la tarjeta</Button>
              </div>
            ) : null}
          </article>
        ))}
      </div>
      {decision ? (
        <ConfirmDialog
          title={decision.decision === 'liberar' ? 'Liberar el pago' : 'Devolver el pago'}
          summary={`${decision.monto}. ${decision.decision === 'liberar' ? 'El profesional cobra la garantía.' : 'El dinero vuelve a la tarjeta del cliente.'} Entorno Transbank: integración.`}
          irreversible
          requireTotp={!totpFresh()}
          busy={busy}
          onCancel={() => setDecision(null)}
          onConfirm={(motivo, code) => {
            setBusy(true);
            void (async () => {
              const ok = await reverify(code);
              if (!ok) {
                toast('El código no es válido.');
                setBusy(false);
                return;
              }
              const { error } = await supabase.functions.invoke('webpay-resolve-dispute', {
                body: { disputeId: decision.id, decision: decision.decision, resolution: motivo },
              });
              setBusy(false);
              if (error) {
                toast(await edgeFunctionErrorMessage(error, 'No se pudo resolver la disputa.'));
                return;
              }
              setDecision(null);
              toast('Disputa actualizada.');
              await client.invalidateQueries({ queryKey: ['disputas'] });
              await client.invalidateQueries({ queryKey: ['resumen'] });
              await client.invalidateQueries({ queryKey: ['pagos'] });
            })();
          }}
        />
      ) : null}
    </Gate>
  );
}

function Evidencia({ id }: { id: string }) {
  const query = useQuery({
    queryKey: ['evidencia', id],
    queryFn: async () => {
      const { data, error } = await supabase.rpc('evidencia_disputa', { p_id_disputa: id });
      if (error) throw error;
      return data ?? [];
    },
  });
  if (!query.data?.length) return <p className="muted">Sin fotos de evidencia.</p>;
  return (
    <div className="row">
      {query.data.map((photo) => (
        <img key={photo.id} alt="Evidencia del trabajo" width={120} height={90} src={`data:image/webp;base64,${photo.imagen_base64}`} />
      ))}
    </div>
  );
}

export function TicketsPage() {
  return (
    <section className="stack">
      <h1>Tickets de soporte</h1>
      <p className="muted">La tabla existe. Si la app aún no crea tickets, la lista queda vacía: no hay un hilo de mensajes propio de tickets.</p>
      <PagedTable
        queryKey={['tickets']}
        empty="Aún no hay tickets."
        load={(page, search) => loadPage('tickets_soporte', page, search, 'id, asunto, estado, nombre_cliente, nombre_trabajador, creado_en')}
        columns={[
          { key: 'asunto', header: 'Asunto', cell: (row) => String(row.asunto ?? '—'), csv: (row) => row.asunto },
          { key: 'estado', header: 'Estado', cell: (row) => <Badge value={String(row.estado ?? 'pendiente')} />, csv: (row) => statusLabel(String(row.estado ?? '')) },
          { key: 'cliente', header: 'Cliente', cell: (row) => String(row.nombre_cliente ?? '—'), csv: (row) => row.nombre_cliente },
        ]}
      />
    </section>
  );
}

export function ReportesPage() {
  const { profile } = useAuth();
  const admin = consolePermissions(profile?.role ?? '').people;
  const toast = useToast();
  const [target, setTarget] = useState<{ id: string; estado: string } | null>(null);
  return (
    <section className="stack">
      <h1>Reportes y abuso</h1>
      <PagedTable
        queryKey={['reportes']}
        empty="Aún no hay reportes."
        load={(page, search) => loadPage('reportes', page, search, 'id, motivo, estado, creado_en')}
        columns={[
          { key: 'motivo', header: 'Motivo', cell: (row) => String(row.motivo ?? '—'), csv: (row) => row.motivo },
          { key: 'estado', header: 'Estado', cell: (row) => <Badge value={String(row.estado)} />, csv: (row) => statusLabel(String(row.estado)) },
          { key: 'accion', header: 'Acción', cell: (row) => admin ? (
            <Button variant="secondary" onClick={(event) => { event.stopPropagation(); setTarget({ id: row.id, estado: 'descartado' }); }}>Descartar</Button>
          ) : 'Solo lectura', csv: () => '' },
        ]}
      />
      {target ? (
        <ConfirmDialog
          title="Descartar reporte"
          summary="El reporte queda como descartado. No se borra."
          onCancel={() => setTarget(null)}
          onConfirm={(motivo) => {
            void supabase.rpc('consola_resolver_reporte', { p_id: target.id, p_estado: target.estado, p_motivo: motivo })
              .then(({ error }) => {
                if (error) toast(friendlyError(error));
                else toast('Reporte actualizado.');
                setTarget(null);
              });
          }}
        />
      ) : null}
    </section>
  );
}

export function UsuariosPage() {
  const { id } = useParams();
  const { profile } = useAuth();
  const admin = consolePermissions(profile?.role ?? '').verifyPeople;
  return (
    <Gate allow={consolePermissions(profile?.role ?? '').viewPeople}>
      <h1>Clientes</h1>
      <PagedTable
        queryKey={['usuarios']}
        empty="Aún no hay clientes con ese filtro."
        load={async (page, search) => {
          const q = clean(search);
          let request = supabase.from('perfiles').select('id, nombre, rol, estado_cuenta, creado_en', { count: 'exact' }).eq('rol', 'usuario');
          if (q) request = request.ilike('nombre', `%${q}%`);
          const { data, error, count } = await request.order('creado_en', { ascending: false }).range(page * PAGE, page * PAGE + PAGE - 1);
          if (error) throw error;
          return { rows: data ?? [], total: count ?? 0 };
        }}
        columns={[
          { key: 'nombre', header: 'Nombre', cell: (row) => String(row.nombre), csv: (row) => row.nombre },
          { key: 'estado', header: 'Cuenta', cell: (row) => <Badge value={String(row.estado_cuenta)} />, csv: (row) => statusLabel(String(row.estado_cuenta)) },
        ]}
        onRow={(row) => { window.location.assign(`/usuarios/${row.id}`); }}
      />
      {id ? <EstadoCuenta id={id} enabled={admin} /> : null}
    </Gate>
  );
}

function EstadoCuenta({ id, enabled }: { id: string; enabled: boolean }) {
  const toast = useToast();
  const [estado, setEstado] = useState<'suspendido' | 'activo' | null>(null);
  return (
    <article className="panel stack">
      <h2>Cuenta</h2>
      <CopyId value={id} />
      {enabled ? (
        <div className="row">
          <Button variant="danger" onClick={() => setEstado('suspendido')}>Suspender</Button>
          <Button variant="secondary" onClick={() => setEstado('activo')}>Reactivar</Button>
        </div>
      ) : <p className="muted">Los datos sensibles quedan enmascarados para tu rol.</p>}
      {estado ? (
        <ConfirmDialog
          title={estado === 'suspendido' ? 'Suspender cuenta' : 'Reactivar cuenta'}
          summary="El cambio queda en la bitácora."
          onCancel={() => setEstado(null)}
          onConfirm={(motivo) => {
            void supabase.rpc('consola_fijar_estado_cuenta', { p_id: id, p_estado: estado, p_motivo: motivo }).then(({ error }) => {
              toast(error ? friendlyError(error) : 'Cuenta actualizada.');
              setEstado(null);
            });
          }}
        />
      ) : null}
    </article>
  );
}

export function ProfesionalesPage() {
  const { profile } = useAuth();
  const permissions = consolePermissions(profile?.role ?? '');
  const [estado, setEstado] = useState('todos');
  const [selected, setSelected] = useState<string | null>(useParams().id ?? null);
  return (
    <Gate allow={permissions.viewPeople}>
      <h1>Profesionales</h1>
      <label className="field">
        <span>Estado de verificación</span>
        <select value={estado} onChange={(event) => setEstado(event.target.value)}>
          <option value="todos">Todos, incluidos los rechazados</option>
          <option value="en_revision">En revisión</option>
          <option value="rechazado">Rechazados</option>
          <option value="verificado">Verificados</option>
          <option value="pendiente">Pendientes</option>
        </select>
      </label>
      <PagedTable
        queryKey={['profesionales', estado]}
        empty="No hay profesionales en este estado."
        load={async (page, search) => {
          const q = clean(search);
          let request = supabase.from('trabajadores').select('id_usuario, profesion, estado_verificacion, nota_verificacion, calificacion', { count: 'exact' });
          if (estado !== 'todos') request = request.eq('estado_verificacion', estado);
          if (q) request = request.ilike('profesion', `%${q}%`);
          const { data, error, count } = await request.range(page * PAGE, page * PAGE + PAGE - 1);
          if (error) throw error;
          return {
            rows: (data ?? []).map((row) => ({ ...row, id: row.id_usuario })),
            total: count ?? 0,
          };
        }}
        columns={[
          { key: 'oficio', header: 'Oficio', cell: (row) => String(row.profesion), csv: (row) => row.profesion },
          { key: 'estado', header: 'Verificación', cell: (row) => <Badge value={String(row.estado_verificacion)} />, csv: (row) => statusLabel(String(row.estado_verificacion)) },
          { key: 'nota', header: 'Nota', cell: (row) => String(row.calificacion ?? '—'), csv: (row) => row.calificacion },
        ]}
        onRow={(row) => setSelected(row.id)}
      />
      {selected ? <FichaProfesional id={selected} canAct={permissions.verifyPeople} onClose={() => setSelected(null)} /> : null}
    </Gate>
  );
}

function FichaProfesional({ id, canAct, onClose }: { id: string; canAct: boolean; onClose: () => void }) {
  const toast = useToast();
  const client = useQueryClient();
  const [action, setAction] = useState<'verificado' | 'rechazado' | 'en_revision' | null>(null);
  const [showRut, setShowRut] = useState(false);
  const query = useQuery({
    queryKey: ['profesional', id],
    queryFn: async () => {
      const worker = await supabase.from('trabajadores').select('id_usuario, profesion, estado_verificacion, nota_verificacion, descripcion').eq('id_usuario', id).maybeSingle();
      if (worker.error) throw worker.error;
      const events = await supabase.from('verificacion_eventos').select('id, estado, nota, creado_en').eq('id_usuario', id).order('creado_en', { ascending: false });
      const file = await supabase.storage.from('verificacion-profesional').createSignedUrl(`${id}/documento.jpg`, 60);
      const stats = await supabase.rpc('stats_profesionales', { p_ids: [id] });
      return { worker: worker.data, events: events.data ?? [], url: file.data?.signedUrl ?? null, stats: stats.data ?? [] };
    },
  });
  const note = query.data?.worker?.nota_verificacion ?? '';
  const visibleNote = showRut ? note : note.replace(/\b\d{1,2}\.?\d{3}\.?\d{3}-[\dkK]\b/g, (rut) => maskRut(rut));
  const stat = query.data?.stats?.[0];
  return (
    <aside className="drawer">
      <div className="spread">
        <h2>Ficha</h2>
        <Button variant="ghost" onClick={onClose}>Cerrar</Button>
      </div>
      {query.isLoading ? <SkeletonRows /> : null}
      {query.data?.worker ? (
        <div className="stack">
          <p>{query.data.worker.profesion}</p>
          <Badge value={query.data.worker.estado_verificacion} />
          <p>Nota de la fuente de verdad: {stat ? `${stat.calificacion} · ${stat.trabajos_completados} trabajos` : 'Sin estadísticas.'}</p>
          <p>{visibleNote || 'Sin nota de verificación.'}</p>
          {canAct ? (
            <Button variant="secondary" onClick={() => {
              void supabase.rpc('consola_registrar_vista_sensible', {
                p_entidad: 'trabajadores',
                p_id: id,
                p_motivo: 'Revisión del documento de identidad',
              }).then(({ error }) => {
                if (error) toast(friendlyError(error));
                else setShowRut(true);
              });
            }}>Mostrar dato enmascarado</Button>
          ) : null}
          {query.data.url ? <img className="doc-frame" alt="Documento enviado por el profesional" src={query.data.url} /> : <p className="muted">No hay documento en verificacion-profesional/{id}/documento.jpg.</p>}
          <ul className="timeline">
            {query.data.events.map((event) => (
              <li key={event.id}>{formatDateTime(event.creado_en)} · {statusLabel(event.estado)}</li>
            ))}
          </ul>
          {canAct ? (
            <div className="row">
              <Button onClick={() => setAction('verificado')}>Aprobar</Button>
              <Button variant="danger" onClick={() => setAction('rechazado')}>Rechazar</Button>
              <Button variant="secondary" onClick={() => setAction('en_revision')}>Pedir corrección</Button>
            </div>
          ) : null}
        </div>
      ) : null}
      {action ? (
        <ConfirmDialog
          title={action === 'rechazado' ? 'Rechazar verificación' : 'Actualizar verificación'}
          summary={action === 'rechazado' ? 'La nota se envía al profesional y queda en el historial. La fila sigue visible en Rechazados.' : 'El cambio queda en la bitácora.'}
          onCancel={() => setAction(null)}
          onConfirm={(motivo) => {
            void supabase.rpc('fijar_verificacion_profesional', {
              p_id_usuario: id,
              p_estado: action,
              p_nota: motivo,
            }).then(async ({ error }) => {
              if (error) toast(friendlyError(error));
              else {
                toast('Verificación actualizada.');
                await client.invalidateQueries({ queryKey: ['profesionales'] });
                await client.invalidateQueries({ queryKey: ['profesional', id] });
              }
              setAction(null);
            });
          }}
        />
      ) : null}
    </aside>
  );
}

export function PagosPage() {
  return (
    <Gate allow={consolePermissions(useAuth().profile?.role ?? '').viewMoney}>
      <h1>Pagos y escrow</h1>
      <p className="muted">Montos de la vista cobros_profesional. La comisión la calcula la base.</p>
      <PagedTable
        queryKey={['pagos']}
        empty="Aún no hay pagos."
        load={async (page, search) => {
          const q = clean(search);
          let request = supabase.from('cobros_profesional').select('id_pago, estado_pago, tipo_pago, bruto_clp, comision_clp, neto_clp, creado_en', { count: 'exact' });
          if (q) request = request.ilike('estado_pago', `%${q}%`);
          const { data, error, count } = await request.order('creado_en', { ascending: false }).range(page * PAGE, page * PAGE + PAGE - 1);
          if (error) throw error;
          return { rows: (data ?? []).map((row) => ({ ...row, id: String(row.id_pago) })), total: count ?? 0 };
        }}
        columns={[
          { key: 'estado', header: 'Estado', cell: (row) => <Badge value={String(row.estado_pago)} />, csv: (row) => statusLabel(String(row.estado_pago)) },
          { key: 'tipo', header: 'Tipo', cell: (row) => statusLabel(String(row.tipo_pago)), csv: (row) => statusLabel(String(row.tipo_pago)) },
          { key: 'bruto', header: 'Bruto', cell: (row) => <span className="nums">{formatClp(row.bruto_clp)}</span>, csv: (row) => row.bruto_clp },
          { key: 'comision', header: 'Comisión', cell: (row) => <span className="nums">{formatClp(row.comision_clp)}</span>, csv: (row) => row.comision_clp },
          { key: 'neto', header: 'Neto', cell: (row) => <span className="nums">{formatClp(row.neto_clp)}</span>, csv: (row) => row.neto_clp },
          { key: 'id', header: 'Pago', cell: (row) => maskId(row.id), csv: (row) => row.id },
        ]}
      />
    </Gate>
  );
}

export function LiquidacionesPage() {
  const toast = useToast();
  const [pago, setPago] = useState<{ id: string; neto: number; cuenta: boolean } | null>(null);
  const query = useQuery({
    queryKey: ['por-liquidar'],
    queryFn: async () => {
      const held = await supabase.from('cobros_profesional').select('id_pago, id_trabajador, neto_clp, estado_pago').eq('estado_pago', 'retenido').limit(100);
      if (held.error) throw held.error;
      const ids = [...new Set((held.data ?? []).map((row) => row.id_trabajador).filter(Boolean))] as string[];
      const accounts = ids.length
        ? await supabase.from('cuentas_bancarias').select('id_usuario, banco, tipo_cuenta').in('id_usuario', ids)
        : { data: [], error: null };
      if (accounts.error) throw accounts.error;
      const withAccount = new Set((accounts.data ?? []).map((row) => row.id_usuario));
      return (held.data ?? []).map((row) => ({
        id: String(row.id_pago),
        neto: row.neto_clp ?? 0,
        worker: row.id_trabajador,
        cuenta: row.id_trabajador ? withAccount.has(row.id_trabajador) : false,
      }));
    },
  });
  return (
    <Gate allow={consolePermissions(useAuth().profile?.role ?? '').viewMoney}>
      <h1>Liquidaciones</h1>
      <p className="muted">Khipu y Fintoc: no conectados. La liberación manual pide referencia y motivo.</p>
      {query.isLoading ? <SkeletonRows /> : null}
      {query.data?.length === 0 ? <EmptyState title="No hay pagos retenidos listos para liquidar." /> : null}
      <div className="stack">
        {(query.data ?? []).map((row) => (
          <article key={row.id} className="panel spread">
            <div>
              <strong className="nums">{formatClp(row.neto)}</strong>
              <p className="muted">{maskId(row.id)}</p>
              {row.cuenta ? <p>Cuenta de destino registrada.</p> : <p>El profesional no ha registrado su cuenta.</p>}
            </div>
            <Button disabled={!row.cuenta} onClick={() => setPago({ id: row.id, neto: row.neto, cuenta: row.cuenta })}>Liquidar</Button>
          </article>
        ))}
      </div>
      {pago ? (
        <ConfirmDialog
          title="Liquidar garantía"
          summary={`${formatClp(pago.neto)} se marca liberado cuando confirmas que la transferencia ya se hizo fuera de la app.`}
          irreversible
          requireTotp={!totpFresh()}
          onCancel={() => setPago(null)}
          onConfirm={(motivo, code) => {
            void (async () => {
              if (!(await reverify(code))) {
                toast('El código no es válido.');
                return;
              }
              const { error } = await supabase.functions.invoke('webpay-release', {
                body: {
                  paymentId: pago.id,
                  confirmExternal: true,
                  transferRef: motivo.slice(0, 40),
                  motivo,
                  provider: 'manual',
                },
              });
              if (error) toast(await edgeFunctionErrorMessage(error, 'No se pudo liquidar.'));
              else toast('Liquidación registrada.');
              setPago(null);
            })();
          }}
        />
      ) : null}
    </Gate>
  );
}

export function ReembolsosPage() {
  return (
    <Gate allow={consolePermissions(useAuth().profile?.role ?? '').viewMoney}>
      <h1>Reembolsos</h1>
      <PagedTable
        queryKey={['reembolsos']}
        empty="Aún no hay reembolsos."
        load={async (page) => {
          const { data, error, count } = await supabase
            .from('pagos')
            .select('id, estado, monto, reembolsado_en', { count: 'exact' })
            .eq('estado', 'reembolsado')
            .order('reembolsado_en', { ascending: false })
            .range(page * PAGE, page * PAGE + PAGE - 1);
          if (error) throw error;
          return { rows: data ?? [], total: count ?? 0 };
        }}
        columns={[
          { key: 'monto', header: 'Monto', cell: (row) => formatClp(Number(row.monto)), csv: (row) => row.monto },
          { key: 'fecha', header: 'Reembolsado', cell: (row) => formatDateTime(row.reembolsado_en ? String(row.reembolsado_en) : null), csv: (row) => row.reembolsado_en },
        ]}
      />
    </Gate>
  );
}

export function ConciliacionPage() {
  return (
    <section className="stack">
      <h1>Conciliación Transbank</h1>
      <p>Entorno de pagos: integración. Consultar el estado en Transbank no cobra ni libera.</p>
      <p className="muted">El reporte diario lo arma el cron mwa_webpay_reconcile. Su última ejecución está en Salud.</p>
    </section>
  );
}

export function FinanzasPage() {
  return (
    <Gate allow={consolePermissions(useAuth().profile?.role ?? '').executive}>
      <h1>Finanzas</h1>
      <ResumenPage />
      <p className="muted">
        La comisión sale de comision_servicio_clp: 5 % con mínimo de $1.000. El caso de uso CU-30 dice 15 %; este cambio no altera ese cálculo.
      </p>
    </Gate>
  );
}

export function ResenasPage() {
  const { profile } = useAuth();
  const permissions = consolePermissions(profile?.role ?? '');
  const toast = useToast();
  const [target, setTarget] = useState<{ id: string; estado: string } | null>(null);
  return (
    <section className="stack">
      <h1>Reseñas</h1>
      <PagedTable
        queryKey={['resenas']}
        empty="Aún no hay reseñas."
        load={(page, search) => loadPage('calificaciones', page, search, 'id, puntaje, estado_revision, comentario, creado_en')}
        columns={[
          { key: 'puntaje', header: 'Puntaje', cell: (row) => String(row.puntaje), csv: (row) => row.puntaje },
          { key: 'estado', header: 'Estado', cell: (row) => <Badge value={String(row.estado_revision)} />, csv: (row) => statusLabel(String(row.estado_revision)) },
          { key: 'comentario', header: 'Comentario', cell: (row) => String(row.comentario ?? '—'), csv: (row) => row.comentario },
          { key: 'accion', header: 'Acción', cell: (row) => permissions.moderateReviews || permissions.proposeReviews ? (
            <Button variant="secondary" onClick={(event) => {
              event.stopPropagation();
              setTarget({ id: row.id, estado: permissions.moderateReviews ? 'excluida' : 'en_revision' });
            }}>{permissions.moderateReviews ? 'Ocultar' : 'Proponer revisión'}</Button>
          ) : 'Solo lectura', csv: () => '' },
        ]}
      />
      {target ? (
        <ConfirmDialog
          title="Moderar reseña"
          summary="No se borra. Cambia el estado de revisión."
          onCancel={() => setTarget(null)}
          onConfirm={(motivo) => {
            void supabase.rpc('consola_moderar_resena', { p_id: target.id, p_estado: target.estado, p_motivo: motivo }).then(({ error }) => {
              toast(error ? friendlyError(error) : 'Reseña actualizada.');
              setTarget(null);
            });
          }}
        />
      ) : null}
    </section>
  );
}

export function CatalogoPage() {
  return (
    <Gate allow={consolePermissions(useAuth().profile?.role ?? '').manageCatalog}>
      <h1>Catálogo</h1>
      <PagedTable
        queryKey={['servicios']}
        empty="Aún no hay servicios."
        load={(page, search) => loadPage('servicios', page, search, 'id, nombre, categoria, activo')}
        columns={[
          { key: 'nombre', header: 'Servicio', cell: (row) => String(row.nombre), csv: (row) => row.nombre },
          { key: 'categoria', header: 'Categoría', cell: (row) => String(row.categoria), csv: (row) => row.categoria },
          { key: 'activo', header: 'Activo', cell: (row) => row.activo ? 'Sí' : 'No', csv: (row) => row.activo },
        ]}
      />
      <p className="muted">Si una categoría está en uso, se desactiva en vez de borrarse. Esta vista no borra filas.</p>
    </Gate>
  );
}

export function NotificacionesPage() {
  const { profile } = useAuth();
  const toast = useToast();
  const client = useQueryClient();
  const query = useQuery({
    queryKey: ['bandeja', profile?.id],
    enabled: Boolean(profile?.id),
    queryFn: async () => {
      const { data, error } = await supabase.from('notificaciones').select('id, titulo, cuerpo, leido, creado_en, tipo').eq('id_usuario', profile!.id).order('creado_en', { ascending: false }).limit(50);
      if (error) throw error;
      return data ?? [];
    },
  });
  return (
    <section className="stack">
      <h1>Notificaciones</h1>
      <p className="muted">Los avisos masivos no se simulan: el envío push depende del secreto de la función send-push, que esta pantalla no dispara.</p>
      {query.isLoading ? <SkeletonRows /> : null}
      {query.data?.length === 0 ? <EmptyState title="Aún no tienes notificaciones." /> : null}
      {(query.data ?? []).map((item) => (
        <article key={item.id} className="panel spread">
          <div>
            <strong>{item.titulo}</strong>
            <p>{item.cuerpo}</p>
            <p className="muted">{formatDateTime(item.creado_en)}</p>
          </div>
          {item.leido ? <Badge value="reconocido" /> : (
            <Button variant="secondary" onClick={() => {
              void supabase.from('notificaciones').update({ leido: 1 }).eq('id', item.id).then(async ({ error }) => {
                if (error) toast('No se pudo marcar como leída.');
                else await client.invalidateQueries({ queryKey: ['bandeja'] });
              });
            }}>Marcar leída</Button>
          )}
        </article>
      ))}
    </section>
  );
}

function inviteRoleLabel(rol: string): 'Admin' | 'Soporte' | 'QA' | null {
  if (rol === 'administrador') return 'Admin';
  if (rol === 'soporte') return 'Soporte';
  if (rol === 'qa') return 'QA';
  return null;
}

export function EquipoPage() {
  const { profile } = useAuth();
  const toast = useToast();
  const client = useQueryClient();
  const [form, setForm] = useState({ email: '', name: '', role: 'Soporte', message: '' });
  const [roles, setRoles] = useState<Record<string, string>>({});
  const [action, setAction] = useState<null | {
    kind: 'rol' | 'reenviar' | 'revocar' | 'cerrar';
    id: string;
    nombre: string;
    correo: string | null;
    rol: string;
  }>(null);
  const query = useQuery({
    queryKey: ['equipo'],
    queryFn: async () => {
      const { data, error } = await supabase.rpc('consola_listar_equipo');
      if (error) throw error;
      return data ?? [];
    },
  });
  const invite = useMutation({
    mutationFn: async () => {
      const { error } = await supabase.functions.invoke('invitar-colaborador', {
        body: { ...form, motivo: form.message, redirectTo: 'myworksapp-admin://auth/callback' },
      });
      if (error) throw new Error(await edgeFunctionErrorMessage(error, 'No se pudo invitar.'));
    },
    onSuccess: async () => {
      toast('Invitación enviada.');
      await client.invalidateQueries({ queryKey: ['equipo'] });
    },
    onError: (error: Error) => toast(error.message),
  });
  const runAction = async (motivo: string) => {
    if (!action) return;
    if (action.kind === 'rol') {
      const { error } = await supabase.rpc('consola_cambiar_rol', { p_id: action.id, p_rol: action.rol, p_motivo: motivo });
      if (error) throw new Error(friendlyError(error));
      return;
    }
    if (action.kind === 'revocar') {
      const { error } = await supabase.rpc('consola_revocar_invitacion', { p_id: action.id, p_motivo: motivo });
      if (error) throw new Error(friendlyError(error));
      return;
    }
    if (action.kind === 'cerrar') {
      const { error } = await supabase.rpc('consola_cerrar_sesiones', { p_id: action.id, p_motivo: motivo });
      if (error) throw new Error(friendlyError(error));
      return;
    }
    const label = inviteRoleLabel(action.rol);
    if (!action.correo || !label) throw new Error('Esa cuenta no tiene correo para reenviar.');
    const { error } = await supabase.functions.invoke('invitar-colaborador', {
      body: {
        email: action.correo,
        name: action.nombre,
        role: label,
        message: motivo,
        motivo,
        redirectTo: 'myworksapp-admin://auth/callback',
      },
    });
    if (error) throw new Error(await edgeFunctionErrorMessage(error, 'No se pudo reenviar la invitación.'));
  };
  return (
    <Gate allow={consolePermissions(profile?.role ?? '').people}>
      <h1>Equipo</h1>
      {query.isLoading ? <SkeletonRows /> : null}
      {query.isError ? <ErrorState message="No se pudo cargar el equipo." onRetry={() => void query.refetch()} /> : null}
      {query.data?.length === 0 ? <EmptyState title="No hay colaboradores con rol de consola." /> : null}
      <div className="table-wrap panel">
        <table className="data">
          <thead><tr><th>Nombre</th><th>Rol</th><th>Cuenta</th><th>Invitación</th><th>Acciones</th></tr></thead>
          <tbody>
            {(query.data ?? []).map((person) => {
              const nextRole = roles[person.id] ?? person.rol;
              const pending = Boolean(person.invitacion_pendiente);
              return (
                <tr key={person.id}>
                  <td>{person.nombre}</td>
                  <td>
                    <select
                      aria-label={`Rol de ${person.nombre}`}
                      value={nextRole}
                      onChange={(event) => setRoles({ ...roles, [person.id]: event.target.value })}
                    >
                      <option value="administrador">Administración</option>
                      <option value="soporte">Soporte</option>
                      <option value="qa">QA</option>
                    </select>
                  </td>
                  <td><Badge value={person.estado_cuenta} /></td>
                  <td>{pending ? 'Pendiente' : 'Aceptada'}</td>
                  <td>
                    <div className="row">
                      <Button
                        variant="secondary"
                        disabled={nextRole === person.rol}
                        onClick={() => setAction({ kind: 'rol', id: person.id, nombre: person.nombre, correo: person.correo, rol: nextRole })}
                      >Cambiar rol</Button>
                      <Button
                        variant="secondary"
                        disabled={!pending || !person.correo}
                        onClick={() => setAction({ kind: 'reenviar', id: person.id, nombre: person.nombre, correo: person.correo, rol: person.rol })}
                      >Reenviar</Button>
                      <Button
                        variant="danger"
                        disabled={!pending}
                        onClick={() => setAction({ kind: 'revocar', id: person.id, nombre: person.nombre, correo: person.correo, rol: person.rol })}
                      >Revocar</Button>
                      <Button
                        variant="secondary"
                        disabled={person.id === profile?.id}
                        onClick={() => setAction({ kind: 'cerrar', id: person.id, nombre: person.nombre, correo: person.correo, rol: person.rol })}
                      >Cerrar sesiones</Button>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
      {action ? (
        <ConfirmDialog
          title={
            action.kind === 'rol' ? 'Cambiar rol'
              : action.kind === 'reenviar' ? 'Reenviar invitación'
                : action.kind === 'revocar' ? 'Revocar invitación'
                  : 'Cerrar sesiones'
          }
          summary={
            action.kind === 'rol' ? `${action.nombre} pasará a ${statusLabel(action.rol)}.`
              : action.kind === 'reenviar' ? `Se vuelve a enviar la invitación a ${action.correo}.`
                : action.kind === 'revocar' ? `${action.nombre} todavía no aceptó. Se elimina la invitación.`
                  : `Se cierran las sesiones de ${action.nombre}. La cuenta sigue existiendo.`
          }
          irreversible={action.kind === 'revocar'}
          onCancel={() => setAction(null)}
          onConfirm={(motivo) => {
            void runAction(motivo).then(async () => {
              toast('Listo.');
              setAction(null);
              await client.invalidateQueries({ queryKey: ['equipo'] });
            }).catch((error: unknown) => {
              const message = error instanceof Error ? error.message : friendlyError(error as { message?: string });
              toast(message || 'No se pudo completar la acción.');
            });
          }}
        />
      ) : null}
      <form className="panel stack" onSubmit={(event) => { event.preventDefault(); invite.mutate(); }}>
        <h2>Invitar</h2>
        <p className="muted">El rol inicial es Soporte.</p>
        <label className="field"><span>Correo</span><input type="email" required value={form.email} onChange={(event) => setForm({ ...form, email: event.target.value })} /></label>
        <label className="field"><span>Nombre</span><input required minLength={2} value={form.name} onChange={(event) => setForm({ ...form, name: event.target.value })} /></label>
        <label className="field">
          <span>Rol</span>
          <select value={form.role} onChange={(event) => setForm({ ...form, role: event.target.value })}>
            <option>Soporte</option>
            <option>QA</option>
            <option>Admin</option>
          </select>
        </label>
        <label className="field"><span>Motivo</span><textarea required minLength={10} value={form.message} onChange={(event) => setForm({ ...form, message: event.target.value })} /></label>
        <Button type="submit" busy={invite.isPending}>Enviar invitación</Button>
      </form>
    </Gate>
  );
}

export function AuditoriaPage() {
  return (
    <Gate allow={consolePermissions(useAuth().profile?.role ?? '').viewAudit}>
      <h1>Auditoría</h1>
      <PagedTable
        queryKey={['auditoria']}
        empty="Aún no hay acciones registradas en la bitácora."
        load={async (page, search) => {
          const q = clean(search);
          let request = supabase.from('auditoria_consola').select('id, creado_en, accion, entidad, id_entidad, motivo, rol_actor', { count: 'exact' });
          if (q) request = request.ilike('accion', `%${q}%`);
          const { data, error, count } = await request.order('creado_en', { ascending: false }).range(page * PAGE, page * PAGE + PAGE - 1);
          if (error) throw error;
          return { rows: data ?? [], total: count ?? 0 };
        }}
        columns={[
          { key: 'cuando', header: 'Cuándo', cell: (row) => formatDateTime(String(row.creado_en)), csv: (row) => row.creado_en },
          { key: 'accion', header: 'Acción', cell: (row) => statusLabel(String(row.accion).replaceAll('_', ' ')) === 'Estado no reconocido' ? String(row.accion).replaceAll('_', ' ') : statusLabel(String(row.accion)), csv: (row) => row.accion },
          { key: 'entidad', header: 'Entidad', cell: (row) => `${row.entidad} ${row.id_entidad ?? ''}`, csv: (row) => row.entidad },
          { key: 'motivo', header: 'Motivo', cell: (row) => String(row.motivo ?? '—'), csv: (row) => row.motivo },
        ]}
      />
    </Gate>
  );
}

export function AjustesPage() {
  const toast = useToast();
  const query = useQuery({
    queryKey: ['config'],
    queryFn: async () => {
      const { data, error } = await supabase.from('app_config').select('clave, valor').order('clave');
      if (error) throw error;
      return data ?? [];
    },
  });
  const [drafts, setDrafts] = useState<Record<string, string>>({});
  const [pending, setPending] = useState<{ clave: string; valor: string; anterior: string } | null>(null);
  return (
    <Gate allow={consolePermissions(useAuth().profile?.role ?? '').manageCatalog}>
      <h1>Ajustes</h1>
      <p className="muted">admin_requiere_aal2 y demo_modo se muestran y no se editan aquí.</p>
      {(query.data ?? []).map((row) => {
        const locked = row.clave === 'admin_requiere_aal2' || row.clave === 'demo_modo';
        return (
          <article key={row.clave} className="panel spread">
            <label className="field">
              <span>{row.clave} · actual {row.valor}</span>
              <input
                value={drafts[row.clave] ?? row.valor}
                disabled={locked}
                onChange={(event) => setDrafts({ ...drafts, [row.clave]: event.target.value })}
              />
            </label>
            {locked ? <span className="muted">Solo lectura</span> : (
              <Button variant="secondary" onClick={() => setPending({
                clave: row.clave,
                valor: (drafts[row.clave] ?? row.valor).trim(),
                anterior: row.valor,
              })}>Guardar</Button>
            )}
          </article>
        );
      })}
      {pending ? (
        <ConfirmDialog
          title={`Cambiar ${pending.clave}`}
          summary={`De ${pending.anterior} a ${pending.valor}.`}
          onCancel={() => setPending(null)}
          onConfirm={(motivo) => {
            void supabase.rpc('consola_editar_config', { p_clave: pending.clave, p_valor: pending.valor, p_motivo: motivo }).then(({ error }) => {
              toast(error ? friendlyError(error) : 'Ajuste guardado.');
              setPending(null);
            });
          }}
        />
      ) : null}
    </Gate>
  );
}

export function SaludPage() {
  const query = useQuery({
    queryKey: ['cron'],
    queryFn: async () => {
      const { data, error } = await supabase.rpc('consola_cron_salud');
      if (error) throw error;
      return data;
    },
  });
  const body = asRecord(query.data);
  const jobs = Array.isArray(body.jobs) ? body.jobs : [];
  return (
    <Gate allow={consolePermissions(useAuth().profile?.role ?? '').security}>
      <h1>Salud</h1>
      <p className="muted">El interruptor de pagos vive en los secretos de las Edge Functions. Esta pantalla no lo simula ni lo cambia.</p>
      {query.isLoading ? <SkeletonRows /> : null}
      {query.isError ? <ErrorState message="No se pudo leer el estado de los cron." onRetry={() => void query.refetch()} /> : null}
      {body.disponible === false ? <EmptyState title="pg_cron no está visible" detail={String(body.nota ?? '')} /> : null}
      {jobs.map((job) => {
        const row = asRecord(job);
        return (
          <article key={String(row.jobname)} className="panel">
            <strong>{String(row.jobname ?? 'Cron')}</strong>
            <p>{row.status ? String(row.status) : 'Sin ejecuciones registradas'}</p>
            <p className="muted">{formatDateTime(row.start_time ? String(row.start_time) : null)}</p>
          </article>
        );
      })}
    </Gate>
  );
}

export function ErroresPage() {
  const toast = useToast();
  const [id, setId] = useState<string | null>(null);
  return (
    <Gate allow={consolePermissions(useAuth().profile?.role ?? '').viewErrors}>
      <h1>Errores de la app</h1>
      <PagedTable
        queryKey={['errores']}
        empty="No hay errores con este filtro."
        load={(page, search) => loadPage('registros_error_app', page, search, 'id, mensaje, plataforma, version_app, estado, creado_en')}
        columns={[
          { key: 'mensaje', header: 'Mensaje', cell: (row) => String(row.mensaje), csv: (row) => row.mensaje },
          { key: 'plataforma', header: 'Plataforma', cell: (row) => String(row.plataforma ?? '—'), csv: (row) => row.plataforma },
          { key: 'estado', header: 'Estado', cell: (row) => <Badge value={String(row.estado)} />, csv: (row) => statusLabel(String(row.estado)) },
          { key: 'accion', header: 'Acción', cell: (row) => (
            <Button variant="secondary" onClick={(event) => { event.stopPropagation(); setId(row.id); }}>Marcar revisado</Button>
          ), csv: () => '' },
        ]}
      />
      {id ? (
        <ConfirmDialog
          title="Marcar error como revisado"
          summary="Pasa a reconocido. No se borra."
          onCancel={() => setId(null)}
          onConfirm={(motivo) => {
            void supabase.rpc('consola_marcar_error', { p_id: id, p_motivo: motivo }).then(({ error }) => {
              toast(error ? friendlyError(error) : 'Error marcado.');
              setId(null);
            });
          }}
        />
      ) : null}
    </Gate>
  );
}

export function CuentaPage() {
  const { profile, logout } = useAuth();
  const [shared, setShared] = useState(sharedDeviceEnabled());
  const [password, setPassword] = useState('');
  const toast = useToast();
  return (
    <section className="stack">
      <h1>Mi cuenta</h1>
      <p>{profile?.name} · {profile?.email}</p>
      <p><Badge value={profile?.role} /></p>
      <label className="row">
        <input
          type="checkbox"
          checked={shared}
          onChange={(event) => {
            setShared(event.target.checked);
            setSharedDevice(event.target.checked);
          }}
        />
        Equipo compartido: cerrar la sesión al salir de la ventana
      </label>
      <form className="panel stack" onSubmit={(event) => {
        event.preventDefault();
        void supabase.auth.updateUser({ password }).then(({ error }) => {
          toast(error ? 'No se pudo cambiar la contraseña.' : 'Contraseña actualizada.');
          setPassword('');
        });
      }}>
        <label className="field"><span>Nueva contraseña</span><input type="password" value={password} onChange={(event) => setPassword(event.target.value)} autoComplete="new-password" /></label>
        <Button type="submit">Cambiar clave</Button>
      </form>
      <Button variant="secondary" onClick={() => void logout()}>Cerrar sesión</Button>
    </section>
  );
}

async function loadPage(
  table: 'trabajos' | 'tickets_soporte' | 'reportes' | 'calificaciones' | 'servicios' | 'registros_error_app',
  page: number,
  search: string,
  columns: string,
): Promise<PageResult<Record<string, unknown> & { id: string }>> {
  const q = clean(search);
  let request = supabase.from(table).select(columns, { count: 'exact' });
  if (q && table !== 'registros_error_app') {
    const column = table === 'tickets_soporte' ? 'asunto' : table === 'servicios' ? 'nombre' : table === 'calificaciones' ? 'comentario' : table === 'reportes' ? 'motivo' : 'direccion';
    request = request.ilike(column, `%${q}%`);
  }
  if (q && table === 'registros_error_app') request = request.ilike('mensaje', `%${q}%`);
  const { data, error, count } = await request.range(page * PAGE, page * PAGE + PAGE - 1);
  if (error) throw error;
  return { rows: (data ?? []) as unknown as Array<Record<string, unknown> & { id: string }>, total: count ?? 0 };
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === 'object' ? value as Record<string, unknown> : {};
}

function num(value: unknown): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

function delta(current: number, previous: number): string {
  if (!previous) return 'Sin comparación del período anterior';
  const diff = current - previous;
  return `${diff >= 0 ? '+' : ''}${formatClp(diff)} frente al período anterior`;
}
