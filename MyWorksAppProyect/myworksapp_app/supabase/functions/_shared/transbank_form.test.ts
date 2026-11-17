import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  assertTransbankAction,
  TRANSBANK_BRIDGE_ORIGIN,
  transbankBridgeUrl,
  transbankRedirectResponse,
  transbankRedirectUrl,
} from "./transbank_form.ts";

describe("redirect a Transbank", () => {
  it("agrega token_ws por query", () => {
    const location = transbankRedirectUrl({
      action: "https://webpay3gint.transbank.cl/webpayserver/initTransaction",
      fieldName: "token_ws",
      token: "tok-1",
    });
    const url = new URL(location);
    assert.equal(url.searchParams.get("token_ws"), "tok-1");
  });

  it("redirige a la página puente que hace el POST (no sirve HTML desde Supabase)", () => {
    const res = transbankRedirectResponse({
      action: "https://webpay3gint.transbank.cl/webpayserver/initTransaction",
      fieldName: "token_ws",
      token: 'tok"1<',
    });
    assert.equal(res.status, 303);
    const location = new URL(res.headers.get("location") || "");
    assert.equal(location.origin, TRANSBANK_BRIDGE_ORIGIN);
    assert.equal(location.pathname, "/tbk-post.html");
    assert.equal(location.search, "");
    const frag = new URLSearchParams(location.hash.slice(1));
    assert.equal(frag.get("f"), "token_ws");
    assert.equal(frag.get("t"), 'tok"1<');
    assert.equal(
      frag.get("a"),
      "https://webpay3gint.transbank.cl/webpayserver/initTransaction",
    );
  });

  it("no arma la puente para un host que no es Transbank", () => {
    assert.throws(
      () =>
        transbankBridgeUrl({
          action: "https://ejemplo.cl/x",
          fieldName: "token_ws",
          token: "t",
        }),
      /URL de pago inválida/,
    );
  });

  it("usa TBK_TOKEN en la inscripción Oneclick", () => {
    const url = new URL(
      transbankRedirectUrl({
        action: "https://webpay3g.transbank.cl/webpayserver/bp_inscription.cgi",
        fieldName: "TBK_TOKEN",
        token: "insc",
      }),
    );
    assert.equal(url.searchParams.get("TBK_TOKEN"), "insc");
  });

  it("rechaza un host que no es Transbank", () => {
    assert.throws(
      () => assertTransbankAction("https://ejemplo.cl/pago"),
      /URL de pago inválida/,
    );
    assert.throws(
      () =>
        assertTransbankAction(
          "http://webpay3gint.transbank.cl/webpayserver/initTransaction",
        ),
      /URL de pago inválida/,
    );
  });
});
