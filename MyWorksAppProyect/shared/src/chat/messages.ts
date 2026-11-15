import type { AppSupabase } from '../client';
import { contactBlockedMessage, containsContactData } from './contactFilter';

export interface JobMessage {
  id: string;
  jobId: string;
  senderId: string;
  receiverId: string;
  content: string;
  createdAt: string;
}

export interface NewJobMessage {
  id: string;
  jobId: string;
  senderId: string;
  receiverId: string;
  content: string;
  createdAt?: string;
}

export function buildJobMessageInsert(input: NewJobMessage) {
  const content = input.content.trim();
  return {
    id: input.id,
    id_trabajo: input.jobId,
    id_remitente: input.senderId,
    id_destinatario: input.receiverId,
    contenido: content,
    tipo: 'texto',
    leido: 0,
    creado_en: input.createdAt ?? new Date().toISOString(),
  };
}

export function mapJobMessage(
  row: Record<string, unknown> | null | undefined,
): JobMessage | null {
  if (!row || row.id == null || row.id_trabajo == null) return null;
  return {
    id: String(row.id),
    jobId: String(row.id_trabajo),
    senderId: String(row.id_remitente ?? ''),
    receiverId: String(row.id_destinatario ?? ''),
    content: String(row.contenido ?? ''),
    createdAt: String(row.creado_en ?? ''),
  };
}

export function mergeJobMessage(list: JobMessage[], incoming: JobMessage): JobMessage[] {
  if (list.some((item) => item.id === incoming.id)) return list;
  return [...list, incoming];
}

export function jobChatSendError(err: unknown): string {
  const raw =
    err instanceof Error
      ? err.message
      : typeof err === 'object' && err && 'message' in err
        ? String((err as { message: unknown }).message)
        : '';
  if (raw.includes('mensaje bloqueado') || raw === contactBlockedMessage) {
    return contactBlockedMessage;
  }
  if (/row-level security|JWT|not authenticated|permission denied|42501/i.test(raw)) {
    return 'No se envió. Inicia sesión con la cuenta del pedido.';
  }
  return raw.trim() || 'No se pudo enviar el mensaje.';
}

export async function fetchJobMessages(
  supabase: AppSupabase,
  jobId: string,
): Promise<JobMessage[]> {
  const { data, error } = await supabase
    .from('mensajes')
    .select('id, id_trabajo, id_remitente, id_destinatario, contenido, creado_en')
    .eq('id_trabajo', jobId)
    .order('creado_en', { ascending: true });
  if (error) throw error;
  return ((data ?? []) as Record<string, unknown>[])
    .map(mapJobMessage)
    .filter((row): row is JobMessage => row != null);
}

export async function sendJobMessage(
  supabase: AppSupabase,
  input: NewJobMessage,
): Promise<JobMessage> {
  const content = input.content.trim();
  if (!content) throw new Error('Escribe un mensaje.');
  if (content.length > 2000) throw new Error('El mensaje es demasiado largo.');
  if (containsContactData(content)) throw new Error(contactBlockedMessage);
  const row = buildJobMessageInsert({
    ...input,
    content,
  });
  const { error } = await supabase.from('mensajes').insert(row);
  if (error) throw error;
  return mapJobMessage(row)!;
}
