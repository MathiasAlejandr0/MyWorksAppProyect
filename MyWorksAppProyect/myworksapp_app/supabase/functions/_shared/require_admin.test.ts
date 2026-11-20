import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { describe, it } from "node:test";
import { fileURLToPath } from "node:url";
import {
  ADMIN_DENIED,
  adminSessionAllowed,
  guardAdminMutation,
  motivoValido,
  requireAdmin,
  type AdminRpc,
} from "./require_admin.ts";

function rpc(data: unknown, error: { message?: string } | null = null): AdminRpc {
  return {
    rpc: async () => ({ data, error }),
  };
}

describe("is_admin en el servidor", () => {
  it("un JWT aal1 (is_admin false) responde 403 y no cambia pagos ni disputas", async () => {
    let mutated = 0;
    const result = await guardAdminMutation(rpc(false), async () => {
      mutated += 1;
      return { pago: "cambiado" };
    });
    assert.equal(result.status, 403);
    if (result.status === 403) assert.equal(result.error, ADMIN_DENIED);
    assert.equal(mutated, 0);
  });

  it("una cuenta suspendida (is_admin false) responde 403 y no muta", async () => {
    let mutated = 0;
    const result = await guardAdminMutation(rpc(null), async () => {
      mutated += 1;
    });
    assert.equal(result.status, 403);
    assert.equal(mutated, 0);
  });

  it("un error de la RPC responde 403 y no muta", async () => {
    let mutated = 0;
    const result = await guardAdminMutation(
      rpc(true, { message: "permission denied" }),
      async () => {
        mutated += 1;
      },
    );
    assert.equal(result.status, 403);
    assert.equal(mutated, 0);
  });

  it("admin aal2 con cuenta activa (is_admin true) deja ejecutar la mutación", async () => {
    let mutated = 0;
    const result = await guardAdminMutation(rpc(true), async () => {
      mutated += 1;
      return "liberado";
    });
    assert.equal(result.status, 200);
    if (result.status === 200) assert.equal(result.value, "liberado");
    assert.equal(mutated, 1);
  });

  it("solo acepta el booleano true", () => {
    assert.equal(adminSessionAllowed(true, null), true);
    assert.equal(adminSessionAllowed("true", null), false);
    assert.equal(adminSessionAllowed(false, null), false);
    assert.equal(adminSessionAllowed(true, { message: "x" }), false);
  });

  it("el motivo de una acción de dinero exige al menos 10 caracteres", () => {
    assert.equal(motivoValido("corto"), null);
    assert.equal(motivoValido("  liberar por acuerdo de las partes  "), "liberar por acuerdo de las partes");
  });

  it("requireAdmin no filtra el detalle al cliente", async () => {
    const gate = await requireAdmin(rpc(false), () => {});
    assert.deepEqual(gate, { ok: false, status: 403, error: ADMIN_DENIED });
  });
});

describe("las funciones de consola no leen perfiles.rol", () => {
  const root = fileURLToPath(new URL("..", import.meta.url));
  const files = [
    "webpay-release/index.ts",
    "webpay-resolve-dispute/index.ts",
    "webpay-refund/index.ts",
    "invitar-colaborador/index.ts",
  ];

  for (const file of files) {
    it(file, () => {
      const src = readFileSync(`${root}${file}`, "utf8");
      assert.match(src, /requireAdmin\(/);
      assert.doesNotMatch(src, /select\("rol"\)/);
      assert.doesNotMatch(src, /profile\?\.rol/);
    });
  }

  it("el reembolso de cancelación usa is_admin para el atajo de admin", () => {
    const src = readFileSync(`${root}webpay-refund-cancellation/index.ts`, "utf8");
    assert.match(src, /requireAdmin\(/);
    assert.doesNotMatch(src, /profile\?\.rol/);
  });
});
