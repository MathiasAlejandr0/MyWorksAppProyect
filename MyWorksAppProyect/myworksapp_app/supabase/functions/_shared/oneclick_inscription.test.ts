import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  activatePendingInscription,
  cardLast4,
  isEnrolled,
} from "./oneclick_inscription.ts";
import { isInactiveInscription } from "./tbk.ts";

function fakeAdmin() {
  const calls: Array<{ values: Record<string, unknown>; where: string[] }> = [];
  return {
    calls,
    admin: {
      from: () => ({
        update: (values: Record<string, unknown>) => ({
          eq: (c1: string, v1: string) => ({
            eq: (c2: string, v2: string) => {
              calls.push({ values, where: [`${c1}=${v1}`, `${c2}=${v2}`] });
              return Promise.resolve({ error: null });
            },
          }),
        }),
      }),
    },
  };
}

const pending = {
  estado: "pendiente",
  tbk_user: null,
  token_inscripcion: "tok-1",
};

describe("tarjeta Oneclick inscrita varias veces", () => {
  it("cierra la inscripción si Transbank ya la tiene lista aunque la vuelta no llegó", async () => {
    const { admin, calls } = fakeAdmin();
    const card = await activatePendingInscription(
      admin,
      "u1",
      pending,
      async (token) => {
        assert.equal(token, "tok-1");
        return {
          response_code: 0,
          tbk_user: "tbk-abc",
          card_type: "Visa",
          card_number: "XXXXXXXXXXXX6623",
        };
      },
    );
    assert.equal(isEnrolled(card), true);
    assert.equal(card?.ultimos4, "6623");
    assert.equal(calls.length, 1);
    assert.equal(calls[0].values.estado, "activa");
    assert.deepEqual(calls[0].where, ["id_usuario=u1", "token_inscripcion=tok-1"]);
    assert.equal("token_inscripcion" in calls[0].values, false);
  });

  it("deja la inscripción pendiente mientras el cliente no termina en Transbank (-96)", async () => {
    const { admin, calls } = fakeAdmin();
    const card = await activatePendingInscription(admin, "u1", pending, async () => ({
      response_code: -96,
    }));
    assert.equal(isEnrolled(card), false);
    assert.equal(card?.estado, "pendiente");
    assert.equal(calls.length, 0);
  });

  it("no rompe si Transbank no responde", async () => {
    const { admin, calls } = fakeAdmin();
    const card = await activatePendingInscription(admin, "u1", pending, async () => {
      throw new Error("timeout");
    });
    assert.equal(card?.estado, "pendiente");
    assert.equal(calls.length, 0);
  });

  it("no vuelve a consultar una tarjeta ya activa ni una rechazada", async () => {
    const { admin } = fakeAdmin();
    let asked = 0;
    const finish = async () => {
      asked += 1;
      return { response_code: 0, tbk_user: "x" };
    };
    const active = { estado: "activa", tbk_user: "t", token_inscripcion: "tok" };
    assert.equal(await activatePendingInscription(admin, "u1", active, finish), active);
    const rejected = { estado: "rechazada", tbk_user: null, token_inscripcion: null };
    assert.equal(await activatePendingInscription(admin, "u1", rejected, finish), rejected);
    assert.equal(asked, 0);
  });

  it("toma los últimos 4 dígitos", () => {
    assert.equal(cardLast4("XXXXXXXXXXXX6623"), "6623");
    assert.equal(cardLast4(undefined), "");
  });

  it("reconoce la tarjeta que Transbank ya dio de baja", () => {
    assert.equal(
      isInactiveInscription(422, {
        error_message: "Pair tbkUser (a) and username (b) not found or inactive for commerce 1",
      }),
      true,
    );
    assert.equal(isInactiveInscription(422, { error_message: "buy_order duplicado" }), false);
    assert.equal(isInactiveInscription(500, { error_message: "not found or inactive" }), false);
  });
});
