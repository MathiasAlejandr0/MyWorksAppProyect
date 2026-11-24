import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  holdOptionsForPayment,
  openJobAfterHold,
} from "./open_job_after_hold.ts";

function fakeAdmin() {
  const rpcs: Array<{ fn: string; args: Record<string, unknown> }> = [];
  const updates: Array<{
    table: string;
    values: Record<string, unknown>;
    where: string[];
  }> = [];
  return {
    rpcs,
    updates,
    admin: {
      rpc: async (fn: string, args: Record<string, unknown>) => {
        rpcs.push({ fn, args });
        return { error: null };
      },
      from: (table: string) => ({
        update: (values: Record<string, unknown>) => ({
          eq: (c1: string, v1: string) => ({
            eq: (c2: string, v2: string) => {
              updates.push({
                table,
                values,
                where: [`${c1}=${v1}`, `${c2}=${v2}`],
              });
              return Promise.resolve({ error: null });
            },
          }),
        }),
      }),
    },
  };
}

describe("holdOptionsForPayment", () => {
  it("incluye el id de la orden de cambio", () => {
    assert.deepEqual(
      holdOptionsForPayment({
        id: "pago-1",
        id_orden_cambio: "oc-9",
      }),
      { paymentId: "pago-1", changeOrderId: "oc-9" },
    );
  });

  it("un cobro principal deja changeOrderId en null", () => {
    assert.deepEqual(
      holdOptionsForPayment({
        id: "pago-principal",
        id_orden_cambio: null,
      }),
      { paymentId: "pago-principal", changeOrderId: null },
    );
  });
});

describe("openJobAfterHold", () => {
  it("con ambos ids llama marcar_orden_cambio_pagada y no toca trabajos", async () => {
    const { admin, rpcs, updates } = fakeAdmin();
    await openJobAfterHold(admin, "job-1", {
      changeOrderId: "oc-9",
      paymentId: "pago-1",
    });
    assert.equal(rpcs.length, 1);
    assert.equal(rpcs[0].fn, "marcar_orden_cambio_pagada");
    assert.deepEqual(rpcs[0].args, {
      p_id_orden_cambio: "oc-9",
      p_id_pago: "pago-1",
    });
    assert.equal(updates.length, 0);
  });

  it("con solo paymentId pasa el trabajo de esperando_pago a pendiente", async () => {
    const { admin, rpcs, updates } = fakeAdmin();
    await openJobAfterHold(admin, "job-1", { paymentId: "pago-1" });
    assert.equal(rpcs.length, 0);
    assert.equal(updates.length, 1);
    assert.equal(updates[0].table, "trabajos");
    assert.equal(updates[0].values.estado, "pendiente");
    assert.equal(updates[0].values.estado_pago, "retenido");
    assert.deepEqual(updates[0].where, [
      "id=job-1",
      "estado=esperando_pago",
    ]);
  });
});
