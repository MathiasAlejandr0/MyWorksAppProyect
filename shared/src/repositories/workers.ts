import type { SupabaseClient } from '@supabase/supabase-js';
import type { WebWorkerCard, WorkerWithProfile } from '../types';

const DEFAULT_AVATAR =
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200';

type WorkerQueryRow = {
  userId: string;
  profession: string;
  description?: string | null;
  rating?: number | null;
  isAvailable?: number | null;
  visitFee?: number | null;
  serviceCategory: string;
  pricingConfigured?: number | null;
  workZone?: string | null;
  profiles?:
    | { name?: string; email?: string; profilePhotoPath?: string | null }
    | { name?: string; email?: string; profilePhotoPath?: string | null }[]
    | null;
};

function mapWorkerRow(row: WorkerQueryRow): WorkerWithProfile {
  const profile = row.profiles;
  const profileRow = Array.isArray(profile) ? profile[0] : profile;

  return {
    userId: row.userId,
    profession: row.profession,
    description: row.description,
    rating: Number(row.rating ?? 0),
    isAvailable: Number(row.isAvailable ?? 0),
    visitFee: Number(row.visitFee ?? 0),
    serviceCategory: row.serviceCategory,
    pricingConfigured: Number(row.pricingConfigured ?? 0),
    workZone: row.workZone,
    name: profileRow?.name ?? 'Profesional',
    email: profileRow?.email,
    profilePhotoPath: profileRow?.profilePhotoPath,
  };
}

export async function fetchWorkersByCategory(
  supabase: SupabaseClient,
  category: string,
): Promise<WorkerWithProfile[]> {
  const { data, error } = await supabase
    .from('workers')
    .select(
      'userId, profession, description, rating, isAvailable, visitFee, serviceCategory, pricingConfigured, workZone, profiles!workers_userId_fkey(name, email, profilePhotoPath)',
    )
    .eq('serviceCategory', category)
    .eq('isAvailable', 1)
    .eq('pricingConfigured', 1)
    .order('rating', { ascending: false });

  if (error) throw error;
  return ((data ?? []) as WorkerQueryRow[]).map(mapWorkerRow);
}

export async function fetchWorkersForAdmin(
  supabase: SupabaseClient,
): Promise<WorkerWithProfile[]> {
  const { data, error } = await supabase
    .from('workers')
    .select(
      'userId, profession, description, rating, isAvailable, visitFee, serviceCategory, pricingConfigured, workZone, profiles!workers_userId_fkey(name, email, profilePhotoPath)',
    )
    .order('rating', { ascending: false });

  if (error) throw error;
  return ((data ?? []) as WorkerQueryRow[]).map(mapWorkerRow);
}

export function toWebWorkerCard(worker: WorkerWithProfile, jobsDone = 0): WebWorkerCard {
  return {
    id: worker.userId,
    name: worker.name,
    profession: worker.profession,
    category: worker.serviceCategory,
    rating: worker.rating,
    jobsDone,
    photoUrl: worker.profilePhotoPath || DEFAULT_AVATAR,
    pricePerVisit: worker.visitFee,
  };
}
