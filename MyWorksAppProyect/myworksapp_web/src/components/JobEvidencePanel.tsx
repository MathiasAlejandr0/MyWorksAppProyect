import { useEffect, useState } from 'react';
import { byteaHex, sha256Hex } from '@myworksapp/shared';

/** La base solo acepta fotos WebP en imagen_webp. El video sigue igual. */
async function imageFileToWebp(file: File): Promise<File> {
  if (file.type === 'image/webp') return file;
  const bitmap = await createImageBitmap(file);
  const canvas = document.createElement('canvas');
  canvas.width = bitmap.width;
  canvas.height = bitmap.height;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('No se pudo preparar la foto');
  ctx.drawImage(bitmap, 0, 0);
  bitmap.close();
  const blob = await new Promise<Blob>((resolve, reject) => {
    canvas.toBlob(
      (value) => (value ? resolve(value) : reject(new Error('No se pudo convertir la foto a WebP'))),
      'image/webp',
      0.82,
    );
  });
  return new File([blob], 'evidencia.webp', { type: 'image/webp' });
}

import { saveJobEvidence, signedEvidenceUrl, isEvidenceStoragePath } from '@myworksapp/shared';
import { supabase } from '../supabaseClient';

type Item = { id: string; url: string; video: boolean; confianza: string | null };

async function luma9x8(file: Blob): Promise<Uint8Array> {
  const bitmap = await createImageBitmap(file);
  const canvas = document.createElement('canvas');
  canvas.width = 9;
  canvas.height = 8;
  const ctx = canvas.getContext('2d', { willReadFrequently: true });
  if (!ctx) throw new Error('No se pudo leer la foto');
  ctx.drawImage(bitmap, 0, 0, 9, 8);
  bitmap.close();
  const pixels = ctx.getImageData(0, 0, 9, 8).data;
  const luma = new Uint8Array(72);
  for (let i = 0; i < 72; i += 1) {
    const offset = i * 4;
    luma[i] = Math.round((pixels[offset] * 30 + pixels[offset + 1] * 59 + pixels[offset + 2] * 11) / 100);
  }
  return luma;
}

export function JobEvidencePanel({
  jobId,
  userId,
  readOnly = false,
}: {
  jobId: string;
  userId: string;
  /** Trabajo cerrado (completado o anulado): se ven las pruebas, pero ya no se suben nuevas. */
  readOnly?: boolean;
}) {
  const [items, setItems] = useState<Item[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [progress, setProgress] = useState(0);

  async function load() {
    const { data, error: readError } = await supabase
      .from('fotos_trabajo')
      .select('id, ruta_foto, tipo_medio, confianza')
      .eq('id_trabajo', jobId)
      .order('creado_en', { ascending: false });
    if (readError) {
      setError('No se pudo leer la evidencia');
      return;
    }
    const next: Item[] = [];
    for (const row of data ?? []) {
      const path = String(row.ruta_foto ?? '');
      if (!isEvidenceStoragePath(path)) continue;
      const url = await signedEvidenceUrl(supabase, path);
      if (!url) continue;
      next.push({
        id: String(row.id),
        url,
        video: row.tipo_medio === 'video',
        confianza: row.confianza == null ? null : String(row.confianza),
      });
    }
    setItems(next);
    setError(null);
  }

  useEffect(() => {
    void load();
  }, [jobId]);

  async function onFile(file: File | undefined) {
    if (!file) return;
    setBusy(true);
    setError(null);
    setProgress(0.05);
    try {
      const originalBytes = new Uint8Array(await file.arrayBuffer());
      const hashOriginal = await sha256Hex(originalBytes);
      const metadata = {
        nombre: file.name,
        tipo: file.type,
        bytes: file.size,
        modificado: file.lastModified,
      };
      const video = file.type.startsWith('video/');
      const luma = video ? null : await luma9x8(file);
      const prepared = video ? file : await imageFileToWebp(file);
      const preparedBytes = new Uint8Array(await prepared.arrayBuffer());
      const hashWebp = video ? hashOriginal : await sha256Hex(preparedBytes);
      const fileId = crypto.randomUUID();
      await saveJobEvidence(
        supabase,
        {
          jobId,
          userId,
          fileId,
          body: prepared,
          mime: prepared.type || (video ? 'video/mp4' : 'image/webp'),
          byteLength: prepared.size,
        },
        setProgress,
      );
      const { error: procedenciaError } = await supabase.rpc('registrar_evidencia_web', {
        p_id_foto: fileId,
        p_id_trabajo: jobId,
        p_hash_original: hashOriginal,
        p_hash_sha256: hashWebp,
        p_luma: luma ? byteaHex(luma) : null,
        p_tipo: video ? 'video' : 'detalle',
        p_metadata: metadata,
      });
      if (procedenciaError) {
        throw new Error('La evidencia quedó guardada como no verificada.');
      }
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'No se pudo subir la evidencia');
    } finally {
      setBusy(false);
    }
  }

  return (
    <section className="tracking-escrow-card">
      <div>
        <strong>Evidencia</strong>
        <p>
          Desde el navegador la evidencia queda marcada como no verificada.
          No cierra el pago sola. El hash original se guarda antes de convertir a WebP.
        </p>
        {busy ? <progress value={progress} max={1} /> : null}
        {error ? <p role="alert">{error}</p> : null}
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          {items.map((item) =>
            item.video ? (
              <video key={item.id} src={item.url} controls width={160} />
            ) : (
              <figure key={item.id} style={{ margin: 0 }}>
                <img src={item.url} alt="" width={96} height={96} style={{ objectFit: 'cover' }} />
                <figcaption>
                  {item.confianza === 'confiable' ? 'Verificada' : 'No verificada'}
                </figcaption>
              </figure>
            ),
          )}
        </div>
        {readOnly ? (
          items.length === 0 ? <p>Este trabajo se cerró sin evidencia.</p> : null
        ) : (
        <label className="btn-ghost" style={{ display: 'inline-block', marginTop: 8 }}>
          {busy ? 'Subiendo…' : 'Agregar evidencia'}
          <input
            type="file"
            accept="image/jpeg,image/png,image/webp,video/mp4,video/quicktime,video/webm"
            hidden
            disabled={busy}
            onChange={(event) => void onFile(event.target.files?.[0])}
          />
        </label>
        )}
      </div>
    </section>
  );
}
