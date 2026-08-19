import type { SupabaseClient } from '@supabase/supabase-js';
import type { DisputeRow, DisputeStatus, DisputeWithContext } from '../types';

interface JobSummary {
  id: string;
  userId?: string | null;
  workerId?: string | null;
  description?: string | null;
}

export async function fetchOpenDisputes(
  supabase: SupabaseClient,
): Promise<DisputeWithContext[]> {
  const { data, error } = await supabase
    .from('disputes')
    .select('id, jobId, openedBy, reason, description, status, resolution, createdAt, updatedAt')
    .in('status', ['open', 'under_review'])
    .order('createdAt', { ascending: false });

  if (error) throw error;
  const disputes = (data ?? []) as DisputeRow[];
  if (disputes.length === 0) return [];

  const jobIds = [...new Set(disputes.map((d) => d.jobId))];
  const { data: jobs, error: jobsError } = await supabase
    .from('jobs')
    .select('id, userId, workerId, description')
    .in('id', jobIds);

  if (jobsError) throw jobsError;

  const jobRows = (jobs ?? []) as JobSummary[];
  const userIds = new Set<string>();
  for (const job of jobRows) {
    if (job.userId) userIds.add(job.userId);
    if (job.workerId) userIds.add(job.workerId);
  }

  const { data: profiles, error: profilesError } = await supabase
    .from('profiles')
    .select('id, name')
    .in('id', [...userIds]);

  if (profilesError) throw profilesError;

  const profileMap = new Map<string, string>(
    (profiles ?? []).map((p: { id: string; name: string }) => [p.id, p.name]),
  );
  const jobMap = new Map<string, JobSummary>(jobRows.map((j) => [j.id, j]));

  return disputes.map((dispute) => {
    const job = jobMap.get(dispute.jobId);
    const clientName = job?.userId ? profileMap.get(job.userId) ?? 'Cliente' : 'Cliente';
    const workerName = job?.workerId
      ? profileMap.get(job.workerId) ?? 'Profesional'
      : 'Profesional';

    return {
      ...dispute,
      clientName,
      workerName,
      escrowAmount: 45000,
    };
  });
}

export async function updateDisputeStatus(
  supabase: SupabaseClient,
  disputeId: string,
  status: DisputeStatus,
  resolution: string,
  resolvedBy: string,
): Promise<void> {
  const now = new Date().toISOString();
  const { error } = await supabase
    .from('disputes')
    .update({
      status,
      resolution,
      resolvedBy,
      resolvedAt: now,
      updatedAt: now,
    })
    .eq('id', disputeId);

  if (error) throw error;
}
