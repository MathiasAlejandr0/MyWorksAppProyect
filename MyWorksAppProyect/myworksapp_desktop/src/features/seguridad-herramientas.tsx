import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { friendlyError } from '../lib/errors';
import { formatDateTime } from '../lib/format';
import { edgeFunctionErrorMessage } from '@myworksapp/shared';
import { callRpc } from '../lib/rpc';
import { supabase } from '../supabaseClient';
import { ConfirmDialog } from '../ui/ConfirmDialog';
import { Badge, Button, EmptyState } from '../ui/kit';
import { useToast } from '../ui/toast-store';
import { evaluarCors, evaluarSecretos, type Hallazgo } from './seguridad-checks';
import { asNum, asRows, asText } from './seguridad-model';

const PRUEBAS = [
  ['rls', 'RLS'],
  ['advisors', 'Advisors'],
  ['funciones_sin_auth', 'Functions sin JWT'],
  ['fuerza_bruta', 'Intentos de acceso'],
  ['salud', 'Salud'],
] as const;

type DefensaAccion = { clave: string; activo: boolean; frase: 'BLOQUEAR' | 'LIBERAR' };
type RespaldoAccion = { id: string; kind: 'restaurar'; tabla: string } | { kind: 'crear' } | { id: string; kind: 'ip' } | { id: string; kind: 'liberar-ip' };

export function SeguridadHerramientas({ tab }: { tab: 'pruebas' | 'defensa' | 'respaldos' }) {
  const toast = useToast();
  const client = useQueryClient();
  const [ultimo, setUltimo] = useState<Record<string, unknown> | null>(null);
  const [defensaAccion, setDefensaAccion] = useState<DefensaAccion | null>(null);
  const [respaldoAccion, setRespaldoAccion] = useState<RespaldoAccion | null>(null);
  const [ip, setIp] = useState('');
  const [horas, setHoras] = useState('24');
  const defensa = useQuery({
    queryKey: ['defensa'],
    queryFn: () => callRpc<Record<string, unknown>>('consola_estado_defensa'),
  });
  const historial = useQuery({
    queryKey: ['pruebas-seguridad'],
    queryFn: () => callRpc<Array<{
      id: string;
      creado_en: string;
      tipo: string;
      origen: string;
      resultado: string;
      severidad: string;
      resumen: string;
      recomendacion: string;
    }>>('consola_listar_pruebas'),
  });
  const respaldos = useQuery({
    queryKey: ['respaldos'],
    queryFn: () => callRpc<Array<Record<string, unknown>>>('consola_listar_respaldos'),
  });

  const correr = async (tipo: string) => {
    const data = await callRpc<Record<string, unknown>>('consola_ejecutar_prueba', { p_tipo: tipo });
    setUltimo(data);
    await client.invalidateQueries({ queryKey: ['pruebas-seguridad'] });
    await client.invalidateQueries({ queryKey: ['auditoria'] });
  };

  const correrNavegador = async (tipo: 'cors' | 'secretos_cliente', hallazgo: Hallazgo) => {
    await callRpc('consola_guardar_prueba', {
      p_tipo: tipo,
      p_resultado: hallazgo.resultado,
      p_severidad: hallazgo.severidad,
      p_resumen: hallazgo.resumen,
      p_recomendacion: hallazgo.recomendacion,
      p_detalle: hallazgo.detalle,
    });
    setUltimo({ tipo, ...hallazgo });
    await client.invalidateQueries({ queryKey: ['pruebas-seguridad'] });
  };

  const flags = defensa.data ?? {};
  const ips = asRows(flags.ips);

  const bloqueo = flags.defensa_bloqueo === true;
  return (
    <>
      {tab === 'pruebas' ? (
      <article className="panel stack" id="pruebas-seguridad">
        <h2>Herramientas de testeo</h2>
        <p className="muted">Cada corrida deja resultado, severidad y recomendación en el historial. No prueba contraseñas ni muestra secretos.</p>
        <div className="row">
          {PRUEBAS.map(([tipo, label]) => (
            <Button key={tipo} variant="secondary" onClick={() => void correr(tipo).catch((error: unknown) => toast(mensaje(error)))}>{label}</Button>
          ))}
          <Button variant="secondary" onClick={() => void revisarCors().then((hallazgo) => correrNavegador('cors', hallazgo)).catch((error: unknown) => toast(mensaje(error)))}>CORS</Button>
          <Button variant="secondary" onClick={() => void correrNavegador('secretos_cliente', evaluarSecretos(import.meta.env as Record<string, string | undefined>)).catch((error: unknown) => toast(mensaje(error)))}>Secretos del cliente</Button>
        </div>
        {ultimo ? (
          <div className="stack">
            <div className="row">
              <Badge value={asText(ultimo.resultado)} />
              <Badge value={asText(ultimo.severidad)} />
              <strong>{asText(ultimo.tipo)}</strong>
            </div>
            <p>{asText(ultimo.resumen)}</p>
            <p className="muted">{asText(ultimo.recomendacion)}</p>
          </div>
        ) : null}
        <h3>Historial</h3>
        {(historial.data ?? []).length === 0 ? <EmptyState title="Todavía no hay pruebas guardadas." /> : null}
        <ul className="timeline">
          {(historial.data ?? []).map((row) => (
            <li key={row.id}>{formatDateTime(row.creado_en)} · {row.tipo} · {row.resultado} · {row.severidad} · {row.resumen}</li>
          ))}
        </ul>
      </article>
      ) : null}

      {tab === 'defensa' ? (
      <article className="panel stack" id="defensa">
        <div className="spread">
          <h2>Defensa</h2>
          <Button variant={bloqueo ? 'secondary' : 'danger'} onClick={() => setDefensaAccion({ clave: 'defensa_bloqueo', activo: !bloqueo, frase: bloqueo ? 'LIBERAR' : 'BLOQUEAR' })}>
            {bloqueo ? 'Quitar bloqueo total' : 'Modo bloqueo total'}
          </Button>
        </div>
        <div className="stack">
          <Interruptor titulo="Solo lectura" detalle="Congela disputas, tickets, reportes y catálogo." on={flags.defensa_solo_lectura === true} onToggle={() => setDefensaAccion({ clave: 'defensa_solo_lectura', activo: flags.defensa_solo_lectura !== true, frase: flags.defensa_solo_lectura === true ? 'LIBERAR' : 'BLOQUEAR' })} />
          <Interruptor titulo="Pausar pagos" detalle="No libera ni reembolsa." on={flags.defensa_pausar_pagos === true} onToggle={() => setDefensaAccion({ clave: 'defensa_pausar_pagos', activo: flags.defensa_pausar_pagos !== true, frase: flags.defensa_pausar_pagos === true ? 'LIBERAR' : 'BLOQUEAR' })} />
          <Interruptor titulo="Pausar registros" detalle="No hay altas nuevas." on={flags.defensa_pausar_registros === true} onToggle={() => setDefensaAccion({ clave: 'defensa_pausar_registros', activo: flags.defensa_pausar_registros !== true, frase: flags.defensa_pausar_registros === true ? 'LIBERAR' : 'BLOQUEAR' })} />
          <Interruptor titulo="Automático" detalle="Un incidente alto enciende el bloqueo." on={flags.defensa_automatica === true} onToggle={() => setDefensaAccion({ clave: 'defensa_automatica', activo: flags.defensa_automatica !== true, frase: flags.defensa_automatica === true ? 'LIBERAR' : 'BLOQUEAR' })} />
        </div>
        <div className="row">
          <label className="field"><span>IP</span><input aria-label="IP a bloquear" value={ip} onChange={(event) => setIp(event.target.value)} placeholder="203.0.113.10" /></label>
          <label className="field"><span>Horas</span><input aria-label="Horas de bloqueo" value={horas} onChange={(event) => setHoras(event.target.value)} inputMode="numeric" /></label>
          <Button variant="danger" onClick={() => setRespaldoAccion({ id: '', kind: 'ip' })}>Bloquear IP</Button>
        </div>
        {ips.length === 0 ? <p className="muted">No hay IPs bloqueadas.</p> : null}
        {ips.map((row) => (
          <div key={asText(row.id)} className="spread">
            <span>{asText(row.ip)} · hasta {formatDateTime(asText(row.hasta, ''))}</span>
            <Button variant="secondary" onClick={() => setRespaldoAccion({ id: asText(row.id, ''), kind: 'liberar-ip' })}>Quitar</Button>
          </div>
        ))}
      </article>
      ) : null}

      {tab === 'respaldos' ? (
      <article className="panel stack" id="respaldos">
        <div className="spread">
          <h2>Respaldos</h2>
          <Button onClick={() => setRespaldoAccion({ kind: 'crear' })}>Crear respaldo</Button>
        </div>
        <p className="muted nums">{usoTexto(respaldos.data?.[0])}</p>
        {(respaldos.data ?? []).length === 0 ? <EmptyState title="No hay respaldos todavía." /> : null}
        {(respaldos.data ?? []).map((row) => {
          const tablas = Array.isArray(row.tablas) ? row.tablas.map(String) : [];
          return (
            <div key={asText(row.id)} className="spread">
              <div>
                <strong className="nums">{formatBytes(asNum(row.tamano_bytes))}</strong>
                <p className="muted">{formatDateTime(asText(row.creado_en, ''))} · {asText(row.origen, 'manual')} · {asText(row.sha256).slice(0, 12)}</p>
                <p className="muted">{resumenFilas(row.filas)} · {tablas.length} tablas</p>
              </div>
              <div className="row">
                <Button variant="secondary" onClick={() => void invocar('verificar', { id: row.id }).then((data) => {
                  toast(data.ok ? 'El hash coincide.' : 'El hash no coincide.');
                }).catch((error: unknown) => toast(mensaje(error)))}>Verificar</Button>
                <Button variant="secondary" onClick={() => void invocar('firmar', { id: row.id }).then((data) => {
                  if (data.url) window.open(String(data.url), '_blank', 'noopener');
                }).catch((error: unknown) => toast(mensaje(error)))}>Descargar</Button>
                <Button variant="danger" onClick={() => setRespaldoAccion({ id: asText(row.id, ''), kind: 'restaurar', tabla: 'todas' })}>Restaurar</Button>
              </div>
            </div>
          );
        })}
      </article>
      ) : null}

      {defensaAccion ? (
        <ConfirmDialog
          title={defensaAccion.activo ? 'Activar defensa' : 'Desactivar defensa'}
          summary={defensaAccion.clave === 'defensa_bloqueo'
            ? 'El modo bloqueo enciende solo lectura, pausa de pagos y pausa de registros.'
            : `Cambia ${defensaAccion.clave}.`}
          irreversible={defensaAccion.activo && defensaAccion.clave !== 'defensa_automatica'}
          confirmPhrase={defensaAccion.frase}
          onCancel={() => setDefensaAccion(null)}
          onConfirm={(motivo) => {
            void callRpc('consola_fijar_defensa', {
              p_clave: defensaAccion.clave,
              p_activo: defensaAccion.activo,
              p_frase: defensaAccion.frase,
              p_motivo: motivo,
            }).then(async () => {
              toast('Defensa actualizada.');
              setDefensaAccion(null);
              await client.invalidateQueries({ queryKey: ['defensa'] });
              await client.invalidateQueries({ queryKey: ['auditoria'] });
              await client.invalidateQueries({ queryKey: ['config'] });
            }).catch((error: unknown) => toast(mensaje(error)));
          }}
        />
      ) : null}
      {respaldoAccion ? (
        <ConfirmDialog
          title={tituloRespaldo(respaldoAccion.kind)}
          summary={resumenRespaldo(respaldoAccion.kind)}
          irreversible={respaldoAccion.kind === 'restaurar' || respaldoAccion.kind === 'ip'}
          confirmPhrase={
            respaldoAccion.kind === 'restaurar' ? 'RESTAURAR'
              : respaldoAccion.kind === 'liberar-ip' ? 'LIBERAR'
                : respaldoAccion.kind === 'ip' ? 'BLOQUEAR'
                  : undefined
          }
          onCancel={() => setRespaldoAccion(null)}
          onConfirm={(motivo) => {
            const frase = respaldoAccion.kind === 'restaurar' ? 'RESTAURAR' : respaldoAccion.kind === 'liberar-ip' ? 'LIBERAR' : 'BLOQUEAR';
            const trabajo = respaldoAccion.kind === 'crear'
              ? invocar('crear', { motivo })
              : respaldoAccion.kind === 'restaurar'
                ? invocar('restaurar', { id: respaldoAccion.id, frase, motivo, tablas: respaldoAccion.tabla === 'todas' ? null : [respaldoAccion.tabla] })
                : respaldoAccion.kind === 'ip'
                  ? callRpc('consola_bloquear_ip', { p_ip: ip, p_horas: Number(horas), p_frase: frase, p_motivo: motivo })
                  : callRpc('consola_desbloquear_ip', { p_id: respaldoAccion.id, p_frase: frase, p_motivo: motivo });
            void trabajo.then(async () => {
              toast('Listo.');
              setRespaldoAccion(null);
              await client.invalidateQueries({ queryKey: ['respaldos'] });
              await client.invalidateQueries({ queryKey: ['defensa'] });
              await client.invalidateQueries({ queryKey: ['auditoria'] });
            }).catch((error: unknown) => toast(mensaje(error)));
          }}
        />
      ) : null}
    </>
  );
}

function Interruptor({ titulo, detalle, on, onToggle }: { titulo: string; detalle: string; on: boolean; onToggle: () => void }) {
  return (
    <div className="switch-row">
      <span>
        <strong>{titulo}</strong>
        <span className="muted">{detalle}</span>
      </span>
      <button type="button" role="switch" aria-label={titulo} aria-checked={on} className={on ? 'switch is-on' : 'switch'} onClick={onToggle}>
        {on ? 'Activo' : 'Inactivo'}
      </button>
    </div>
  );
}

async function invocar(accion: string, body: Record<string, unknown>): Promise<Record<string, unknown>> {
  const { data, error } = await supabase.functions.invoke('consola-respaldo', { body: { accion, ...body } });
  if (error) throw new Error(await edgeFunctionErrorMessage(error, 'No se pudo completar el respaldo.'));
  return (data ?? {}) as Record<string, unknown>;
}

async function revisarCors(): Promise<Hallazgo> {
  const url = (import.meta.env.VITE_SUPABASE_URL as string | undefined)?.replace(/\/$/, '');
  if (!url) return evaluarCors(null, 0);
  try {
    const response = await fetch(`${url}/auth/v1/health`, { method: 'GET' });
    return evaluarCors(response.headers.get('access-control-allow-origin'), response.status);
  } catch {
    return evaluarCors(null, 0);
  }
}

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
}

function usoTexto(row: Record<string, unknown> | undefined): string {
  if (!row) return '0 B de 1 GB';
  return `${formatBytes(asNum(row.uso_bytes))} de ${formatBytes(asNum(row.limite_bytes) || 1073741824)}`;
}

function resumenFilas(value: unknown): string {
  if (!value || typeof value !== 'object') return 'Sin conteo';
  return Object.entries(value as Record<string, unknown>)
    .filter(([, count]) => asNum(count) > 0)
    .slice(0, 4)
    .map(([tabla, count]) => `${tabla} ${asNum(count)}`)
    .join(' · ') || 'Sin filas';
}

function mensaje(error: unknown): string {
  if (error && typeof error === 'object' && 'message' in error) return friendlyError(error as { message?: string });
  return 'No se pudo completar la acción.';
}

function tituloRespaldo(kind: RespaldoAccion['kind']): string {
  if (kind === 'crear') return 'Crear respaldo';
  if (kind === 'restaurar') return 'Restaurar respaldo';
  if (kind === 'ip') return 'Bloquear IP';
  return 'Quitar bloqueo de IP';
}

function resumenRespaldo(kind: RespaldoAccion['kind']): string {
  if (kind === 'crear') return 'Copia el negocio en gzip a Storage privado. No incluye tokens ni contraseñas.';
  if (kind === 'restaurar') return 'Borra y vuelve a cargar las tablas del respaldo. Mientras tanto queda el modo bloqueo. Hace falta la frase RESTAURAR.';
  if (kind === 'ip') return 'Las functions de pago rechazan esa IP mientras el bloqueo siga activo.';
  return 'La IP vuelve a poder llamar a las functions.';
}
