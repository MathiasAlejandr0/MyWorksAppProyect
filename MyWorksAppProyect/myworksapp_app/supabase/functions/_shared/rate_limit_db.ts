type RpcResult = { data: unknown; error: { message?: string } | null };

type RpcClient = {
  rpc: (
    fn: string,
    args: Record<string, unknown>,
  ) => PromiseLike<RpcResult>;
};

/** true = permitido. Si la RPC falla o no existe, se rechaza. */
export async function allowRateDb(
  admin: RpcClient,
  key: string,
  max: number,
  windowMs: number,
): Promise<boolean> {
  const id = key.trim();
  if (!id || max < 1 || windowMs < 1000) return false;
  try {
    const { data, error } = await admin.rpc("rate_limit_consumir", {
      p_clave: id,
      p_max: max,
      p_ventana_segundos: Math.ceil(windowMs / 1000),
    });
    if (error) return false;
    return data === true;
  } catch {
    return false;
  }
}
