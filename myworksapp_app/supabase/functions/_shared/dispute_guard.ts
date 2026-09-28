/** True si el trabajo tiene una disputa abierta o en revisión. */

export async function jobHasOpenDispute(
  admin: { from: (table: string) => any },
  jobId: string,
): Promise<boolean> {
  const { data, error } = await admin
    .from("disputas")
    .select("id")
    .eq("id_trabajo", jobId)
    .in("estado", ["abierta", "en_revision"])
    .limit(1);
  if (error) throw new Error(error.message);
  return Array.isArray(data) && data.length > 0;
}
