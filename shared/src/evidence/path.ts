export const EVIDENCE_BUCKET = 'evidencias';

export const MAX_IMAGE_BYTES = 8 * 1024 * 1024;
export const MAX_VIDEO_BYTES = 20 * 1024 * 1024;

const IMAGE_MIME: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
  'image/heic': 'heic',
  'image/heif': 'heif',
};

const VIDEO_MIME: Record<string, string> = {
  'video/mp4': 'mp4',
  'video/quicktime': 'mov',
  'video/webm': 'webm',
};

export type EvidenceMedia = 'foto' | 'video';

export function evidenceMediaForMime(mime: string): EvidenceMedia | null {
  const normalized = mime.toLowerCase().split(';')[0].trim();
  if (IMAGE_MIME[normalized]) return 'foto';
  if (VIDEO_MIME[normalized]) return 'video';
  return null;
}

export function evidenceExtension(mime: string): string | null {
  const normalized = mime.toLowerCase().split(';')[0].trim();
  return IMAGE_MIME[normalized] ?? VIDEO_MIME[normalized] ?? null;
}

/** Ruta privada: `{trabajo}/{usuario}/{archivo}.ext`. No es una URL. */
export function evidenceObjectPath(
  jobId: string,
  userId: string,
  fileId: string,
  mime: string,
): string {
  const ext = evidenceExtension(mime);
  if (!jobId.trim() || !userId.trim() || !fileId.trim() || !ext) {
    throw new Error('Datos de evidencia incompletos');
  }
  if ([jobId, userId, fileId].some((part) => part.includes('/'))) {
    throw new Error('El identificador no puede incluir barras');
  }
  return `${jobId.trim()}/${userId.trim()}/${fileId.trim()}.${ext}`;
}

export function validateEvidenceFile(input: {
  mime: string;
  byteLength: number;
}): { ok: true; media: EvidenceMedia } | { ok: false; message: string } {
  const media = evidenceMediaForMime(input.mime);
  if (!media) {
    return { ok: false, message: 'Solo se aceptan fotos JPG, PNG, WEBP o videos MP4, MOV y WEBM' };
  }
  const limit = media === 'foto' ? MAX_IMAGE_BYTES : MAX_VIDEO_BYTES;
  if (!Number.isFinite(input.byteLength) || input.byteLength <= 0) {
    return { ok: false, message: 'El archivo está vacío' };
  }
  if (input.byteLength > limit) {
    const mb = Math.round(limit / (1024 * 1024));
    return { ok: false, message: `El archivo supera ${mb} MB` };
  }
  return { ok: true, media };
}

/** Camino dentro del bucket, no una URL ni una ruta local del teléfono. */
export function isEvidenceStoragePath(path: string): boolean {
  if (!path || path.includes('://') || path.includes('\\')) return false;
  const parts = path.split('/');
  return parts.length === 3 && parts.every((part) => part.length > 0 && !part.includes('..'));
}
