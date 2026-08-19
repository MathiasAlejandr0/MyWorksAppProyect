import type { SupabaseClient } from '@supabase/supabase-js';
import type { JobRow } from '../types';

export interface CreateJobInput {
  userId: string;
  workerId: string;
  serviceId: string;
  description: string;
  address?: string;
  latitude?: number;
  longitude?: number;
}

export async function createPendingJob(
  supabase: SupabaseClient,
  input: CreateJobInput,
): Promise<JobRow> {
  const now = new Date().toISOString();
  const payload = {
    id: crypto.randomUUID(),
    userId: input.userId,
    workerId: input.workerId,
    serviceId: input.serviceId,
    status: 'pending',
    description: input.description,
    address: input.address ?? 'Solicitud desde web',
    latitude: input.latitude ?? null,
    longitude: input.longitude ?? null,
    pricingMode: 'legacy',
    paymentStatus: 'pending',
    createdAt: now,
    updatedAt: now,
  };

  const { data, error } = await supabase.from('jobs').insert(payload).select().single();
  if (error) throw error;
  return data as JobRow;
}

export async function fetchUserJobs(
  supabase: SupabaseClient,
  userId: string,
): Promise<JobRow[]> {
  const { data, error } = await supabase
    .from('jobs')
    .select('id, userId, workerId, serviceId, status, address, description, createdAt')
    .eq('userId', userId)
    .order('createdAt', { ascending: false });

  if (error) throw error;
  return (data ?? []) as JobRow[];
}
