import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { friendlyError } from '../lib/errors';
import { formatDateTime } from '../lib/format';
import { callRpc } from '../lib/rpc';
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
type RespaldoAccion = { id: string; kind: 'restaurar' } | { kind: 'crear' } | { id: string; kind: 'ip' } | { id: string; kind: 'liberar-ip' };

export function SeguridadHerramientas() {
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

  return (
    <>
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

      <article className="panel stack" id="defensa">
        <h2>Defensa</h2>
        <p className="muted">El modo bloqueo pausa pagos, liberaciones, altas y escrituras sensibles. Se revierte con la frase LIBERAR. La app y las functions leen las mismas claves de app_config.</p>
        <div className="row">
          <Flag label="Modo bloqueo" on={flags.defensa_bloqueo === true} onActivate={() => setDefensaAccion({ clave: 'defensa_bloqueo', activo: true, frase: 'BLOQUEAR' })} onRelease={() => setDefensaAccion({ clave: 'defensa_bloqueo', activo: false, frase: 'LIBERAR' })} />
          <Flag label="Solo lectura" on={flags.defensa_solo_lectura === true} onActivate={() => setDefensaAccion({ clave: 'defensa_solo_lectura', activo: true, frase: 'BLOQUEAR' })} onRelease={() => setDefensaAccion({ clave: 'defensa_solo_lectura', activo: false, frase: 'LIBERAR' })} />
          <Flag label="Pausar pagos" on={flags.defensa_pausar_pagos === true} onActivate={() => setDefensaAccion({ clave: 'defensa_pausar_pagos', activo: true, frase: 'BLOQUEAR' })} onRelease={() => setDefensaAccion({ clave: 'defensa_pausar_pagos', activo: false, frase: 'LIBERAR' })} />
          <Flag label="Pausar registros" on={flags.defensa_pausar_registros === true} onActivate={() => setDefensaAccion({ clave: 'defensa_pausar_registros', activo: true, frase: 'BLOQUEAR' })} onRelease={() => setDefensaAccion({ clave: 'defensa_pausar_registros', activo: false, frase: 'LIBERAR' })} />
          <Flag label="Automático por umbral" on={flags.defensa_automatica === true} onActivate={() => setDefensaAccion({ clave: 'defensa_automatica', activo: true, frase: 'BLOQUEAR' })} onRelease={() => setDefensaAccion({ clave: 'defensa_automatica', activo: false, frase: 'LIBERAR' })} />
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

      <article className="panel stack" id="respaldos">
        <h2>Respaldos</h2>
        <p className="muted">Copia lógica de configuración, umbrales, banderas y catálogo. Se guardan como máximo 5 archivos y 40 MB, muy por debajo del gigabyte de Storage. No incluye contraseñas ni el service role. La restauración exige la frase RESTAURAR y se comprueba el hash antes de escribir.</p>
        <Button onClick={() => setRespaldoAccion({ kind: 'crear' })}>Crear respaldo</Button>
        {(respaldos.data ?? []).length === 0 ? <EmptyState title="No hay respaldos todavía." /> : null}
        {(respaldos.data ?? []).map((row) => (
          <div key={asText(row.id)} className="spread">
            <div>
              <strong className="nums">{formatBytes(asNum(row.tamano_bytes))}</strong>
              <p className="muted">{formatDateTime(asText(row.creado_en, ''))} · {asText(row.estado)} · {asText(row.sha256).slice(0, 12)}</p>
            </div>
            <div className="row">
              <Button variant="secondary" onClick={() => void callRpc('consola_verificar_respaldo', { p_id: row.id }).then((data) => {
                const ok = Boolean((data as { ok?: boolean }).ok);
                toast(ok ? 'El hash coincide.' : 'El hash no coincide.');
              }).catch((error: unknown) => toast(mensaje(error)))}>Verificar</Button>
              <Button variant="danger" onClick={() => setRespaldoAccion({ id: asText(row.id, ''), kind: 'restaurar' })}>Restaurar</Button>
            </div>
          </div>
        ))}
      </article>

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
              ? callRpc('consola_crear_respaldo', { p_motivo: motivo })
              : respaldoAccion.kind === 'restaurar'
                ? callRpc('consola_restaurar_respaldo', { p_id: respaldoAccion.id, p_frase: frase, p_motivo: motivo })
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

function Flag({ label, on, onActivate, onRelease }: { label: string; on: boolean; onActivate: () => void; onRelease: () => void }) {
  return (
    <div className="stack">
      <span>{label}: {on ? 'activo' : 'apagado'}</span>
      <Button variant={on ? 'secondary' : 'danger'} onClick={on ? onRelease : onActivate}>{on ? 'Desactivar' : 'Activar'}</Button>
    </div>
  );
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
  return `${(bytes / 1024).toFixed(1)} KB`;
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
  if (kind === 'crear') return 'Se guarda una copia de la configuración y del catálogo. No incluye contraseñas.';
  if (kind === 'restaurar') return 'Sobrescribe ajustes, umbrales, banderas y el activo del catálogo con esta copia, solo si el hash coincide.';
  if (kind === 'ip') return 'Las functions de pago rechazan esa IP mientras el bloqueo siga activo.';
  return 'La IP vuelve a poder llamar a las functions.';
}
