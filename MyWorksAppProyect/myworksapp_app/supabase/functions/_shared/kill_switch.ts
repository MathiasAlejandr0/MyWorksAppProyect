/** Kill switches de plan Free (Dashboard → Edge secrets). Fail-closed. */

export type KillSwitch =
  | "MWA_KILL_GUEST_CHECKOUT"
  | "MWA_KILL_WEBPAY"
  | "MWA_READ_ONLY";

export function isKillSwitchOn(name: KillSwitch): boolean {
  const v = Deno.env.get(name)?.trim().toLowerCase();
  return v === "1" || v === "true" || v === "on";
}

export function killSwitchResponse(): { error: string } {
  return {
    error:
      "Servicio temporalmente en modo restringido. Inténtalo más tarde.",
  };
}
