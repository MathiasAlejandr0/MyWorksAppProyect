import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { allowRateDb } from "./rate_limit_db.ts";

function client(result: { data: unknown; error: { message?: string } | null }) {
  return {
    rpc: async () => result,
  };
}

describe("rate limit global", () => {
  it("acepta solo cuando la RPC responde true", async () => {
    assert.equal(await allowRateDb(client({ data: true, error: null }), "ip:1", 5, 60_000), true);
    assert.equal(await allowRateDb(client({ data: false, error: null }), "ip:1", 5, 60_000), false);
  });

  it("falla cerrado si la RPC no está o la clave viene vacía", async () => {
    assert.equal(
      await allowRateDb(client({ data: null, error: { message: "no existe" } }), "ip:1", 5, 60_000),
      false,
    );
    assert.equal(await allowRateDb(client({ data: true, error: null }), "  ", 5, 60_000), false);
  });
});
