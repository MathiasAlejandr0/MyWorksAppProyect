import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  bridgeCustomSchemeReturn,
  readCommitTokens,
  webReturnLocation,
} from "./webpay_return.ts";

describe("retorno Webpay", () => {
  it("lee token_ws y TBK_TOKEN de la query o del formulario", () => {
    assert.deepEqual(
      readCommitTokens({
        queryTokenWs: "abc",
        queryTbkToken: "ignorar",
        bodyTokenWs: "desde-body",
      }),
      { tokenWs: "desde-body", tbkToken: "ignorar" },
    );
    assert.deepEqual(
      readCommitTokens({ queryTbkToken: "cancelado" }),
      { tokenWs: "", tbkToken: "cancelado" },
    );
  });

  it("arma la vuelta con pago, invitado y alta", () => {
    const url = new URL(
      webReturnLocation({
        origin: "http://localhost:5173",
        pago: "ok",
        paymentId: "pay-1",
        jobId: "job-1",
        guest: true,
        alta: "pwd.token",
      }),
    );
    assert.equal(url.origin, "http://localhost:5173");
    assert.equal(url.searchParams.get("pago"), "ok");
    assert.equal(url.searchParams.get("invitado"), "1");
    assert.equal(url.searchParams.get("alta"), "pwd.token");
    assert.equal(url.searchParams.get("paymentId"), "pay-1");
  });

  it("la vuelta de la app pasa a https y conserva pago=ok", () => {
    const bridged = bridgeCustomSchemeReturn(
      "myworksapp://pago/?pago=ok&paymentId=pay-1&jobId=job-1",
      "https://myworksapp-cl.vercel.app/",
    );
    const url = new URL(bridged);
    assert.equal(url.origin, "https://myworksapp-cl.vercel.app");
    assert.equal(url.searchParams.get("pago"), "ok");
    assert.equal(url.searchParams.get("paymentId"), "pay-1");
    assert.equal(url.searchParams.get("jobId"), "job-1");
  });

  it("un http de la web no se reescribe", () => {
    const same = "http://localhost:5173/?pago=ok";
    assert.equal(
      bridgeCustomSchemeReturn(same, "https://myworksapp-cl.vercel.app/"),
      same,
    );
  });

  it("un abandono solo marca pago=fail", () => {
    const url = new URL(
      webReturnLocation({
        origin: "http://127.0.0.1:5173/",
        pago: "fail",
        paymentId: "pay-2",
      }),
    );
    assert.equal(url.searchParams.get("pago"), "fail");
    assert.equal(url.searchParams.get("invitado"), null);
  });
});
