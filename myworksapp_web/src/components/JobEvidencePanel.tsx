import { useEffect, useState } from 'react';
import { saveJobEvidence, signedEvidenceUrl, isEvidenceStoragePath } from '@myworksapp/shared';
import { supabase } from '../supabaseClient';

type Item = { id: string; url: string; video: boolean };

export function JobEvidencePanel({
  jobId,
  userId,
}: {
  jobId: string;
  userId: string;
}) {
  const [items, setItems] = useState<Item[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [progress, setProgress] = useState(0);

  async function load() {
    const { data, error: readError } = await supabase
      .from('fotos_trabajo')
      .select('id, ruta_foto, tipo_medio')
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
      await saveJobEvidence(
        supabase,
        {
          jobId,
          userId,
          fileId: crypto.randomUUID(),
          body: file,
          mime: file.type || 'image/jpeg',
          byteLength: file.size,
        },
        setProgress,
      );
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
        <p>Las fotos y videos quedan en un depósito privado. Aquí se ven con un enlace temporal.</p>
        {busy ? <progress value={progress} max={1} /> : null}
        {error ? <p role="alert">{error}</p> : null}
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          {items.map((item) =>
            item.video ? (
              <video key={item.id} src={item.url} controls width={160} />
            ) : (
              <img key={item.id} src={item.url} alt="" width={96} height={96} style={{ objectFit: 'cover' }} />
            ),
          )}
        </div>
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
      </div>
    </section>
  );
}
