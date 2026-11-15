import type { AppSupabase } from '../client';

export type PayoutProviderId = 'manual' | 'khipu' | 'fintoc';

export interface HeldPaymentRow {
  id: string;
  jobId: string;
  amountClp: number;
  status: string;
  createdAt?: string;
  workerId?: string | null;
}

export interface ManualReleaseInput {
  paymentId: string;
  /** Nº de transferencia / comprobante bancario */
  transferRef: string;
  notes?: string;
  /** Debe ser true: confirma que el dinero ya salió (o saldrá) fuera de la app */
  confirmExternal: true;
  provider?: PayoutProviderId;
}

export interface ManualReleaseResult {
  paymentId: string;
  liquidacionId?: string;
  status: string;
}

/** Pagos retenidos listos para liquidar (admin). */
export async function listHeldPayments(
  supabase: AppSupabase,
): Promise<HeldPaymentRow[]> {
  const { data, error } = await supabase
    .from('pagos')
    .select('id, id_trabajo, monto, estado, creado_en')
    .in('estado', ['retenido', 'autorizado'])
    .order('creado_en', { ascending: false })
    .limit(100);

  if (error) throw new Error(error.message);

  const rows = (data ?? []) as Record<string, unknown>[];
  const jobIds = [...new Set(rows.map((r) => String(r.id_trabajo)))];

  let workerByJob = new Map<string, string | null>();
  if (jobIds.length > 0) {
    const { data: jobs } = await supabase
      .from('trabajos')
      .select('id, id_trabajador')
      .in('id', jobIds);
    workerByJob = new Map(
      ((jobs ?? []) as { id: string; id_trabajador: string | null }[]).map(
        (j) => [j.id, j.id_trabajador],
      ),
    );
  }

  return rows.map((r) => ({
    id: String(r.id),
    jobId: String(r.id_trabajo),
    amountClp: Number(r.monto),
    status: String(r.estado),
    createdAt: r.creado_en ? String(r.creado_en) : undefined,
    workerId: workerByJob.get(String(r.id_trabajo)) ?? null,
  }));
}

export async function listLiquidaciones(
  supabase: AppSupabase,
  limit = 50,
): Promise<
  {
    id: string;
    paymentId: string;
    jobId: string;
    amountClp: number;
    provider: string;
    transferRef: string;
    notes: string | null;
    operatorId: string;
    createdAt: string;
  }[]
> {
  const { data, error } = await supabase
    .from('liquidaciones')
    .select(
      'id, id_pago, id_trabajo, monto_clp, proveedor, referencia_transferencia, notas, id_operador, creado_en',
    )
    .order('creado_en', { ascending: false })
    .limit(limit);

  if (error) throw new Error(error.message);

  return ((data ?? []) as Record<string, unknown>[]).map((r) => ({
    id: String(r.id),
    paymentId: String(r.id_pago),
    jobId: String(r.id_trabajo),
    amountClp: Number(r.monto_clp),
    provider: String(r.proveedor),
    transferRef: String(r.referencia_transferencia),
    notes: r.notas ? String(r.notas) : null,
    operatorId: String(r.id_operador),
    createdAt: String(r.creado_en),
  }));
}

/**
 * Libera escrow + registra liquidación manual vía Edge `webpay-release`.
 */
export async function releaseEscrowManual(
  supabase: AppSupabase,
  input: ManualReleaseInput,
): Promise<ManualReleaseResult> {
  const { data, error } = await supabase.functions.invoke('webpay-release', {
    body: {
      paymentId: input.paymentId,
      transferRef: input.transferRef,
      notes: input.notes,
      confirmExternal: true,
      provider: input.provider ?? 'manual',
    },
  });

  if (error) throw new Error(error.message || 'No se pudo liberar el escrow');

  const payload = data as Record<string, unknown> | null;
  if (!payload || payload.error) {
    throw new Error(String(payload?.error || 'Respuesta release inválida'));
  }

  const payment = payload.payment as Record<string, unknown> | undefined;
  const liquidacion = payload.liquidacion as Record<string, unknown> | undefined;

  return {
    paymentId: String(payment?.id || input.paymentId),
    liquidacionId: liquidacion?.id ? String(liquidacion.id) : undefined,
    status: String(payment?.estado || 'liberado'),
  };
}

/**
 * Stub de proveedores PSP Chile. No llama APIs reales hasta existir empresa.
 */
export function getPayoutProviderStatus(id: PayoutProviderId): {
  id: PayoutProviderId;
  ready: boolean;
  message: string;
} {
  if (id === 'manual') {
    return {
      id,
      ready: true,
      message: 'Admin confirma transferencia bancaria y registra referencia.',
    };
  }
  return {
    id,
    ready: false,
    message: `${id} pendiente de contrato comercial + API keys. Usar manual hasta entonces.`,
  };
}
