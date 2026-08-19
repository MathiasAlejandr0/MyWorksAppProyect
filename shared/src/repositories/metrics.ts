import type { SupabaseClient } from '@supabase/supabase-js';
import type { AdminMetrics } from '../types';

async function countRows(
  supabase: SupabaseClient,
  table: string,
  filters?: Record<string, string | number>,
): Promise<number> {
  let query = supabase.from(table).select('id', { count: 'exact', head: true });
  if (filters) {
    for (const [key, value] of Object.entries(filters)) {
      query = query.eq(key, value);
    }
  }
  const { count, error } = await query;
  if (error) throw error;
  return count ?? 0;
}

export async function fetchAdminMetrics(supabase: SupabaseClient): Promise<AdminMetrics> {
  const [
    usersCount,
    workersCount,
    jobsCount,
    openDisputesCount,
    underReviewDisputesCount,
    pendingReportsCount,
    activeJobsCount,
    newErrorsCount,
    unresolvedAbuseCount,
    failedSyncCount,
  ] = await Promise.all([
    countRows(supabase, 'profiles'),
    supabase
      .from('workers')
      .select('userId', { count: 'exact', head: true })
      .then(({ count, error }: { count: number | null; error: Error | null }) => {
        if (error) throw error;
        return count ?? 0;
      }),
    countRows(supabase, 'jobs'),
    countRows(supabase, 'disputes', { status: 'open' }),
    countRows(supabase, 'disputes', { status: 'under_review' }),
    countRows(supabase, 'reports', { status: 'pending' }),
    supabase
      .from('jobs')
      .select('id', { count: 'exact', head: true })
      .in('status', ['pending', 'accepted', 'in_progress'])
      .then(({ count, error }: { count: number | null; error: Error | null }) => {
        if (error) throw error;
        return count ?? 0;
      }),
    countRows(supabase, 'app_error_logs', { status: 'new' }),
    countRows(supabase, 'abuse_events', { isResolved: 0 }),
    countRows(supabase, 'pending_actions', { status: 'failed' }),
  ]);

  return {
    usersCount,
    workersCount,
    jobsCount,
    openDisputesCount,
    underReviewDisputesCount,
    pendingReportsCount,
    activeJobsCount,
    newErrorsCount,
    unresolvedAbuseCount,
    failedSyncCount,
  };
}
