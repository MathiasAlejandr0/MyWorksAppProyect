import type { AppSupabase } from '../client';

export interface AppNotification {
  id: string;
  title: string;
  body: string;
  type: string;
  read: boolean;
  createdAt: string;
  relatedId: string | null;
}

export async function fetchMyNotifications(
  supabase: AppSupabase,
  userId: string,
  limit = 20,
): Promise<AppNotification[]> {
  const { data, error } = await supabase
    .from('notificaciones')
    .select('id, titulo, cuerpo, tipo, leido, creado_en, id_relacionado')
    .eq('id_usuario', userId)
    .order('creado_en', { ascending: false })
    .limit(limit);
  if (error) throw error;
  return ((data ?? []) as Record<string, unknown>[]).map((row) => ({
    id: String(row.id),
    title: String(row.titulo ?? ''),
    body: String(row.cuerpo ?? ''),
    type: String(row.tipo ?? ''),
    read: Number(row.leido ?? 0) === 1,
    createdAt: String(row.creado_en ?? ''),
    relatedId: row.id_relacionado ? String(row.id_relacionado) : null,
  }));
}
