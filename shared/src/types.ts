export type UserRole = 'user' | 'worker' | 'admin';
export type AccountStatus = 'active' | 'suspended' | 'blocked';
export type DisputeStatus = 'open' | 'under_review' | 'resolved';

export interface Profile {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  accountStatus: AccountStatus;
  profilePhotoPath?: string | null;
  createdAt?: string;
}

export interface ServiceRow {
  id: string;
  name: string;
  description?: string | null;
  category: string;
  isActive: number;
  pricingModel?: string | null;
}

export interface WorkerRow {
  userId: string;
  profession: string;
  description?: string | null;
  rating: number;
  isAvailable: number;
  visitFee: number;
  serviceCategory: string;
  pricingConfigured: number;
  workZone?: string | null;
}

export interface WorkerWithProfile extends WorkerRow {
  name: string;
  profilePhotoPath?: string | null;
  email?: string;
}

export interface JobRow {
  id: string;
  userId: string;
  workerId?: string | null;
  serviceId?: string | null;
  status: string;
  address?: string | null;
  description?: string | null;
  createdAt: string;
}

export interface DisputeRow {
  id: string;
  jobId: string;
  openedBy: string;
  reason: string;
  description?: string | null;
  status: DisputeStatus;
  resolution?: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface DisputeWithContext extends DisputeRow {
  clientName: string;
  workerName: string;
  escrowAmount: number;
}

export interface AdminMetrics {
  usersCount: number;
  workersCount: number;
  jobsCount: number;
  openDisputesCount: number;
  underReviewDisputesCount: number;
  pendingReportsCount: number;
  activeJobsCount: number;
  newErrorsCount: number;
  unresolvedAbuseCount: number;
  failedSyncCount: number;
}

export interface WebWorkerCard {
  id: string;
  name: string;
  profession: string;
  category: string;
  rating: number;
  jobsDone: number;
  photoUrl: string;
  pricePerVisit: number;
}
