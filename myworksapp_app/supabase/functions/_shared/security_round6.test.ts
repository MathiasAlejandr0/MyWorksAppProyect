import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { abandonedCheckoutUpdate } from "./abandon_payment.ts";
import { assessWebpayCommit } from "./commit_guard.ts";
import { resolveCorsAllowOrigin } from "./cors_origin.ts";
import {
  parseGuestTicket,
  sha256Hex,
  shouldIssueGuestPasswordTicket,
} from "./guest_ticket.ts";
import { turnstileDecision } from "./turnstile_gate.ts";

describe("ticket de contraseña del invitado", () => {
  it("solo se firma en el primer paso de pendiente a retenido", () => {
    assert.equal(
      shouldIssueGuestPasswordTicket({ alreadyHeld: false, approved: true, guest: true }),
      true,
    );
    assert.equal(
      shouldIssueGuestPasswordTicket({ alreadyHeld: true, approved: true, guest: true }),
      false,
    );
    assert.equal(
      shouldIssueGuestPasswordTicket({ alreadyHeld: false, approved: false, guest: true }),
      false,
    );
    assert.equal(
      shouldIssueGuestPasswordTicket({ alreadyHeld: false, approved: true, guest: false }),
      false,
    );
  });

  it("exige jti y rechaza el formato viejo de cuatro partes", () => {
    const stale = parseGuestTicket("pwd.user.9999999999.abcd");
    assert.equal(stale.ok, false);
    const future = Math.floor(Date.now() / 1000) + 60;
    const parsed = parseGuestTicket(`pwd.user-1.${future}.abc123.sig`);
    assert.equal(parsed.ok, true);
    if (parsed.ok) {
      assert.equal(parsed.jti, "abc123");
      assert.equal(parsed.userId, "user-1");
    }
  });

  it("el nonce se compara por hash, no en claro", async () => {
    const hash = await sha256Hex("nonce-del-navegador");
    assert.equal(hash.length, 64);
    assert.notEqual(hash, "nonce-del-navegador");
    assert.equal(await sha256Hex("nonce-del-navegador"), hash);
  });
});

describe("Turnstile", () => {
  it("en integración sin secreto deja pasar la demo", () => {
    assert.equal(turnstileDecision("integration", false), "skip");
    assert.equal(turnstileDecision(undefined, false), "skip");
  });

  it("en producción sin secreto falla cerrado", () => {
    assert.equal(turnstileDecision("production", false), "fail_closed");
  });

  it("con secreto siempre verifica", () => {
    assert.equal(turnstileDecision("integration", true), "verify");
    assert.equal(turnstileDecision("production", true), "verify");
  });
});

describe("commit de Webpay", () => {
  it("no reescribe un pago ya retenido", () => {
    assert.deepEqual(
      assessWebpayCommit({
        estado: "retenido",
        responseCode: 0,
        status: "AUTHORIZED",
        commitAmount: 1,
        expectedAmount: 999,
        commitBuyOrder: "otra",
        storedBuyOrder: "MWA1",
      }),
      { action: "replay" },
    );
  });

  it("exige monto y orden iguales antes de retener", () => {
    assert.deepEqual(
      assessWebpayCommit({
        estado: "pendiente",
        responseCode: 0,
        status: "AUTHORIZED",
        commitAmount: 15000,
        expectedAmount: 15000,
        commitBuyOrder: "MWA1",
        storedBuyOrder: "MWA1",
      }),
      { action: "hold" },
    );
    assert.deepEqual(
      assessWebpayCommit({
        estado: "pendiente",
        responseCode: 0,
        status: "AUTHORIZED",
        commitAmount: 1,
        expectedAmount: 15000,
        commitBuyOrder: "MWA1",
        storedBuyOrder: "MWA1",
      }),
      { action: "mismatch", reason: "monto" },
    );
    assert.deepEqual(
      assessWebpayCommit({
        estado: "pendiente",
        responseCode: 0,
        status: "AUTHORIZED",
        commitAmount: 15000,
        expectedAmount: 15000,
        commitBuyOrder: "OTRA",
        storedBuyOrder: "MWA1",
      }),
      { action: "mismatch", reason: "buy_order" },
    );
  });
});

describe("pago abandonado en Webpay", () => {
  it("anula el cobro pendiente si el cliente cancela con TBK_TOKEN", () => {
    assert.deepEqual(
      abandonedCheckoutUpdate({
        estado: "pendiente",
        tokenWs: "",
        tbkToken: "tok-abort",
      }),
      { pago: "anulado", job: "cancelado", reason: "abort" },
    );
  });

  it("marca fallido un rechazo o un monto distinto", () => {
    assert.deepEqual(
      abandonedCheckoutUpdate({
        estado: "pendiente",
        tokenWs: "tok",
        tbkToken: "",
        decision: "reject",
      }),
      { pago: "fallido", job: "cancelado", reason: "reject" },
    );
    assert.equal(
      abandonedCheckoutUpdate({
        estado: "pendiente",
        tokenWs: "tok",
        tbkToken: "",
        decision: "mismatch",
      })?.pago,
      "fallido",
    );
  });

  it("no toca un pago ya retenido o liberado", () => {
    assert.equal(
      abandonedCheckoutUpdate({
        estado: "retenido",
        tokenWs: "",
        tbkToken: "tok-abort",
      }),
      null,
    );
    assert.equal(
      abandonedCheckoutUpdate({
        estado: "liberado",
        tokenWs: "tok",
        tbkToken: "",
        decision: "reject",
      }),
      null,
    );
    assert.equal(
      abandonedCheckoutUpdate({
        estado: "pendiente",
        tokenWs: "tok",
        tbkToken: "",
        decision: "hold",
      }),
      null,
    );
  });
});

describe("CORS", () => {
  it("no refleja un origen supabase.co si no está en la lista", () => {
    assert.equal(
      resolveCorsAllowOrigin({
        origin: "https://wxqrfcqifkfgawrnqmnj.supabase.co",
        allowlist: [],
        tbkEnv: "integration",
      }),
      "null",
    );
  });

  it("en integración acepta el vite local y el escritorio", () => {
    assert.equal(
      resolveCorsAllowOrigin({
        origin: "http://127.0.0.1:5173",
        allowlist: [],
        tbkEnv: "integration",
      }),
      "http://127.0.0.1:5173",
    );
    assert.equal(
      resolveCorsAllowOrigin({
        origin: "http://localhost:3001",
        allowlist: [],
        tbkEnv: "integration",
      }),
      "http://localhost:3001",
    );
  });

  it("en producción no abre localhost salvo allowlist", () => {
    assert.equal(
      resolveCorsAllowOrigin({
        origin: "http://localhost:5173",
        allowlist: [],
        tbkEnv: "production",
      }),
      "null",
    );
    assert.equal(
      resolveCorsAllowOrigin({
        origin: "https://app.example.cl",
        allowlist: ["https://app.example.cl"],
        tbkEnv: "production",
      }),
      "https://app.example.cl",
    );
  });
});
