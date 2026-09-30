import type { AppSupabase } from '../client';

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

function mapMessage(row: Record<string, unknown>): JobMessage {
  return {
    id: String(row.id),
    jobId: String(row.id_trabajo),
    senderId: String(row.id_remitente),
    receiverId: String(row.id_destinatario),
    content: String(row.contenido ?? ''),
    createdAt: String(row.creado_en),
  };
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
  return ((data ?? []) as Record<string, unknown>[]).map(mapMessage);
}

export async function sendJobMessage(
  supabase: AppSupabase,
  input: NewJobMessage,
): Promise<void> {
  const content = input.content.trim();
  if (!content) throw new Error('Escribe un mensaje.');
  if (content.length > 2000) throw new Error('El mensaje es demasiado largo.');
  const { error } = await supabase.from('mensajes').insert(buildJobMessageInsert({
    ...input,
    content,
  }));
  if (error) throw error;
}
