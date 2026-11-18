import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { oneclickReturnBase } from "./oneclick_return_base.ts";

const SITE = "https://myworksapp-cl.vercel.app/";
const allowed = ["https://myworksapp-cl.vercel.app", "http://localhost:5173"];

describe("vuelta de Oneclick después del banco", () => {
  it("la app vuelve al sitio https que el WebView sabe seguir", () => {
    assert.equal(
      oneclickReturnBase({ fromApp: true, webOrigin: "", allowedOrigins: allowed }),
      SITE,
    );
  });

  it("la web vuelve al origen que inició la inscripción si está permitido", () => {
    assert.equal(
      oneclickReturnBase({
        fromApp: false,
        webOrigin: "http://localhost:5173",
        allowedOrigins: allowed,
      }),
      "http://localhost:5173/",
    );
  });

  it("sin origen válido nunca cae en localhost", () => {
    for (const webOrigin of ["", "https://otro.example", "http://localhost:9999"]) {
      assert.equal(
        oneclickReturnBase({ fromApp: false, webOrigin, allowedOrigins: allowed }),
        SITE,
      );
    }
  });

  it("usa WEBPAY_WEB_RETURN_URL solo si es https", () => {
    assert.equal(
      oneclickReturnBase({
        fromApp: false,
        webOrigin: "",
        allowedOrigins: allowed,
        configured: "https://mi-sitio.example",
      }),
      "https://mi-sitio.example/",
    );
    assert.equal(
      oneclickReturnBase({
        fromApp: false,
        webOrigin: "",
        allowedOrigins: allowed,
        configured: "http://localhost:5173/",
      }),
      SITE,
    );
  });
});
