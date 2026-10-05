import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  assertTransbankAction,
  transbankRedirectResponse,
  transbankRedirectUrl,
} from "./transbank_form.ts";

describe("redirect a Transbank", () => {
  it("agrega token_ws por query y responde 303", () => {
    const location = transbankRedirectUrl({
      action: "https://webpay3gint.transbank.cl/webpayserver/initTransaction",
      fieldName: "token_ws",
      token: "tok-1",
    });
    const url = new URL(location);
    assert.equal(url.searchParams.get("token_ws"), "tok-1");

    const res = transbankRedirectResponse({
      action: "https://webpay3gint.transbank.cl/webpayserver/initTransaction",
      fieldName: "token_ws",
      token: "tok-1",
    });
    assert.equal(res.status, 303);
    assert.equal(res.headers.get("Location"), location);
    assert.equal(res.headers.get("Cache-Control"), "no-store");
    assert.equal(res.headers.get("Referrer-Policy"), "no-referrer");
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
