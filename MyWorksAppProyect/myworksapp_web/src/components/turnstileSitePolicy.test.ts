import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  isTurnstileTestSiteKey,
  shouldRenderTurnstile,
} from "./turnstileSitePolicy.ts";

describe("widget de Turnstile", () => {
  it("reconoce las claves de prueba de Cloudflare", () => {
    assert.equal(isTurnstileTestSiteKey("1x00000000000000000000AA"), true);
    assert.equal(isTurnstileTestSiteKey("0x4AAAAAAA-real"), false);
  });

  it("en producción no renderiza una clave de prueba", () => {
    assert.equal(shouldRenderTurnstile("1x00000000000000000000AA", true), false);
    assert.equal(shouldRenderTurnstile("1x00000000000000000000BB", true), false);
    assert.equal(shouldRenderTurnstile("3x00000000000000000000FF", true), false);
  });

  it("en producción sí renderiza una clave que no es de prueba", () => {
    assert.equal(shouldRenderTurnstile("0x4AAAAAAA-real", true), true);
  });

  it("sin clave no renderiza", () => {
    assert.equal(shouldRenderTurnstile("", false), false);
    assert.equal(shouldRenderTurnstile("  ", true), false);
  });

  it("fuera de producción una clave de prueba se puede mostrar en local", () => {
    assert.equal(shouldRenderTurnstile("1x00000000000000000000AA", false), true);
  });
});
