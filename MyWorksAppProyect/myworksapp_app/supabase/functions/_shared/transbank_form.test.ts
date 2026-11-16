import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  assertTransbankAction,
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

  it("responde un formulario POST, no un GET", async () => {
    const res = transbankRedirectResponse({
      action: "https://webpay3gint.transbank.cl/webpayserver/initTransaction",
      fieldName: "token_ws",
      token: 'tok"1<',
    });
    assert.equal(res.status, 200);
    assert.match(res.headers.get("content-type") || "", /text\/html/);
    const html = await res.text();
    assert.match(html, /method="post"/);
    assert.match(html, /name="token_ws"/);
    assert.match(html, /value="tok&quot;1&lt;"/);
    assert.match(
      html,
      /action="https:\/\/webpay3gint\.transbank\.cl\/webpayserver\/initTransaction"/,
    );
    assert.equal(html.includes("tok\"1<"), false);
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
