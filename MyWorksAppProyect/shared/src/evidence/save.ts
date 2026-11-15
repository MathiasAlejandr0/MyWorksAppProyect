import type { AppSupabase } from '../client';
import { encodeByteaHex, isWebpBytes } from '../media/bytea';
import {
  EVIDENCE_BUCKET,
  evidenceObjectPath,
  validateEvidenceFile,
  type EvidenceMedia,
} from './path';

export type EvidenceProgress = (fraction: number) => void;

type StorageClient = {
  from: (bucket: string) => {
    upload: (
      path: string,
      body: Blob | ArrayBuffer | Uint8Array,
      options: { contentType: string; upsert: boolean },
    ) => Promise<{ error: { message: string } | null }>;
    remove: (paths: string[]) => Promise<{ error: { message: string } | null }>;
    createSignedUrl: (
      path: string,
      expiresIn: number,
    ) => Promise<{ data: { signedUrl: string } | null; error: { message: string } | null }>;
  };
};

/**
 * Sube al bucket privado, guarda la ruta (no una URL) y borra el objeto
 * si la fila de `fotos_trabajo` no se inserta.
 */
export async function saveJobEvidence(
  supabase: AppSupabase & { storage: StorageClient },
  input: {
    jobId: string;
    userId: string;
    fileId: string;
    body: Blob | ArrayBuffer | Uint8Array;
    mime: string;
    byteLength: number;
  },
  onProgress?: EvidenceProgress,
): Promise<{ id: string; path: string; media: EvidenceMedia }> {
  const check = validateEvidenceFile({ mime: input.mime, byteLength: input.byteLength });
  if (!check.ok) throw new Error(check.message);
  const path = evidenceObjectPath(input.jobId, input.userId, input.fileId, input.mime);
  onProgress?.(0.1);

  let uploaded = false;
  let lastMessage = 'No se pudo subir la evidencia';
  for (let attempt = 0; attempt < 3 && !uploaded; attempt += 1) {
    const { error } = await supabase.storage.from(EVIDENCE_BUCKET).upload(path, input.body, {
      contentType: input.mime,
      upsert: false,
    });
    if (!error) {
      uploaded = true;
      break;
    }
    lastMessage = 'No se pudo subir la evidencia';
    if (attempt < 2) onProgress?.(0.2 + attempt * 0.1);
  }
  if (!uploaded) throw new Error(lastMessage);
  onProgress?.(0.7);

  const bytes = await evidenceBytes(input.body);
  const row: Record<string, string> = {
    id: input.fileId,
    id_trabajo: input.jobId,
    ruta_foto: path,
    tipo_medio: check.media,
    creado_en: new Date().toISOString(),
  };
  // La base exige imagen_webp en las fotos. El video no.
  if (check.media === 'foto' && isWebpBytes(bytes)) {
    row.imagen_webp = encodeByteaHex(bytes);
  }
  const { error: insertError } = await supabase.from('fotos_trabajo').insert(row);
  if (insertError) {
    await supabase.storage.from(EVIDENCE_BUCKET).remove([path]);
    throw new Error('No se pudo registrar la evidencia');
  }
  onProgress?.(1);
  return { id: input.fileId, path, media: check.media };
}

export async function signedEvidenceUrl(
  supabase: { storage: StorageClient },
  path: string,
  expiresIn = 60 * 60,
): Promise<string | null> {
  const { data, error } = await supabase.storage.from(EVIDENCE_BUCKET).createSignedUrl(path, expiresIn);
  if (error || !data?.signedUrl) return null;
  return data.signedUrl;
}

async function evidenceBytes(body: Blob | ArrayBuffer | Uint8Array): Promise<Uint8Array> {
  if (body instanceof Uint8Array) return body;
  if (body instanceof ArrayBuffer) return new Uint8Array(body);
  return new Uint8Array(await body.arrayBuffer());
}
