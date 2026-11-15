import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  decideReconciliation,
  PAYMENT_AWAITING_JOB,
  UNCONFIRMED_WINDOW_MS,
} from "./reconcile_hold.ts";

const base = {
  paymentStatus: PAYMENT_AWAITING_JOB,
  jobStatus: "esperando_pago",
  capturedAtMs: 0,
  nowMs: 60_000,
  transbankAuthorized: true,
};

describe("reconciliación de Webpay capturado", () => {
  it("confirma una sola vez mientras la ventana sigue abierta", () => {
    assert.deepEqual(decideReconciliation(base), { action: "confirm" });
    assert.deepEqual(
      decideReconciliation({ ...base, paymentStatus: "retenido" }),
      { action: "ignore" },
    );
  });

  it("no vuelve a abrir el trabajo si ya salió de esperando pago", () => {
    assert.deepEqual(
      decideReconciliation({ ...base, jobStatus: "pendiente" }),
      { action: "mark_held" },
    );
  });

  it("espera si Transbank aún no confirma y reembolsa al vencer", () => {
    assert.deepEqual(
      decideReconciliation({ ...base, transbankAuthorized: false }),
      { action: "wait" },
    );
    assert.deepEqual(
      decideReconciliation({
        ...base,
        nowMs: UNCONFIRMED_WINDOW_MS,
      }),
      { action: "refund" },
    );
    assert.deepEqual(
      decideReconciliation({
        ...base,
        transbankAuthorized: false,
        nowMs: UNCONFIRMED_WINDOW_MS,
      }),
      { action: "drop" },
    );
  });
});
