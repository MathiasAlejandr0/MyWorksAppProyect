import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  TBK_INTEGRATION_API_KEY,
  TBK_ONECLICK_CHILD_COMMERCE,
  TBK_ONECLICK_CHILD_COMMERCE_2,
  TBK_ONECLICK_MALL_COMMERCE,
  TBK_WEBPAY_PLUS_COMMERCE,
  resolveOneclickConfig,
  resolveTbkConfig,
} from "./tbk.ts";

const OFFICIAL_KEY =
  "579B532A7440BB0C9079DED94D31EA1615BACEB56610332264630D42D0A36B1C";
const WRONG_WEBPAY_SUFFIX = "A1428";
const WRONG_ONECLICK_SUFFIX = "A1438";

const PROD_WEBPAY = {
  TBK_ENV: "production",
  TBK_COMMERCE_CODE: "597012345678",
  TBK_API_KEY: "clave-real-de-produccion-webpay",
};

describe("credenciales Transbank de integración", () => {
  it("usa la llave pública oficial y los códigos de comercio documentados", () => {
    assert.equal(TBK_INTEGRATION_API_KEY, OFFICIAL_KEY);
    assert.equal(TBK_WEBPAY_PLUS_COMMERCE, "597055555532");
    assert.equal(TBK_ONECLICK_MALL_COMMERCE, "597055555541");
    assert.equal(TBK_ONECLICK_CHILD_COMMERCE, "597055555542");
    assert.equal(TBK_ONECLICK_CHILD_COMMERCE_2, "597055555543");
    assert.equal(OFFICIAL_KEY.endsWith(WRONG_WEBPAY_SUFFIX), false);
    assert.equal(OFFICIAL_KEY.endsWith(WRONG_ONECLICK_SUFFIX), false);

    const webpay = resolveTbkConfig({ TBK_ENV: "integration" });
    assert.equal(webpay.commerceCode, "597055555532");
    assert.equal(webpay.apiKey, OFFICIAL_KEY);
    assert.equal(webpay.host, "https://webpay3gint.transbank.cl");

    const oneclick = resolveOneclickConfig({ TBK_ENV: "integration" });
    assert.equal(oneclick.commerceCode, "597055555541");
    assert.equal(oneclick.childCommerceCode, "597055555542");
    assert.equal(oneclick.apiKey, OFFICIAL_KEY);
    assert.equal(oneclick.apiKey.endsWith(WRONG_WEBPAY_SUFFIX), false);
    assert.equal(oneclick.apiKey.endsWith(WRONG_ONECLICK_SUFFIX), false);
  });

  it("aplica el fallback si TBK_ENV no está definido", () => {
    const webpay = resolveTbkConfig({});
    const oneclick = resolveOneclickConfig({});
    assert.equal(webpay.env, "integration");
    assert.equal(webpay.apiKey, OFFICIAL_KEY);
    assert.equal(oneclick.apiKey, OFFICIAL_KEY);
    assert.equal(oneclick.childCommerceCode, TBK_ONECLICK_CHILD_COMMERCE);
  });

  it("respeta secretos explícitos en integración", () => {
    const webpay = resolveTbkConfig({
      TBK_ENV: "integration",
      TBK_COMMERCE_CODE: "597099999999",
      TBK_API_KEY: "clave-propia-integracion",
    });
    assert.equal(webpay.commerceCode, "597099999999");
    assert.equal(webpay.apiKey, "clave-propia-integracion");

    const oneclick = resolveOneclickConfig({
      TBK_ENV: "integration",
      TBK_COMMERCE_CODE: "597099999999",
      TBK_API_KEY: "clave-propia-integracion",
      TBK_ONECLICK_COMMERCE_CODE: "597088888881",
      TBK_ONECLICK_API_KEY: "clave-propia-oneclick",
      TBK_ONECLICK_CHILD_CODE: "597055555543",
    });
    assert.equal(oneclick.commerceCode, "597088888881");
    assert.equal(oneclick.apiKey, "clave-propia-oneclick");
    assert.equal(oneclick.childCommerceCode, "597055555543");
  });

  it("en producción falla si faltan secretos", () => {
    assert.throws(
      () => resolveTbkConfig({ TBK_ENV: "production" }),
      /TBK_COMMERCE_CODE \/ TBK_API_KEY requeridos en production/,
    );
    assert.throws(
      () => resolveOneclickConfig(PROD_WEBPAY),
      /TBK_ONECLICK_COMMERCE_CODE \/ TBK_ONECLICK_API_KEY \/ TBK_ONECLICK_CHILD_CODE requeridos en production/,
    );
  });

  it("en producción rechaza la llave y los códigos públicos", () => {
    assert.throws(
      () =>
        resolveTbkConfig({
          TBK_ENV: "production",
          TBK_COMMERCE_CODE: "597055555532",
          TBK_API_KEY: "clave-real-de-produccion-webpay",
        }),
      /no acepta las claves públicas de integración/,
    );
    assert.throws(
      () =>
        resolveTbkConfig({
          TBK_ENV: "production",
          TBK_COMMERCE_CODE: "597012345678",
          TBK_API_KEY: OFFICIAL_KEY,
        }),
      /no acepta las claves públicas de integración/,
    );
    assert.throws(
      () =>
        resolveOneclickConfig({
          ...PROD_WEBPAY,
          TBK_ONECLICK_COMMERCE_CODE: "597055555541",
          TBK_ONECLICK_API_KEY: "clave-real-oneclick",
          TBK_ONECLICK_CHILD_CODE: "597012345679",
        }),
      /no acepta las claves públicas de integración Oneclick/,
    );
    assert.throws(
      () =>
        resolveOneclickConfig({
          ...PROD_WEBPAY,
          TBK_ONECLICK_COMMERCE_CODE: "597012345680",
          TBK_ONECLICK_API_KEY: "clave-real-oneclick",
          TBK_ONECLICK_CHILD_CODE: "597055555543",
        }),
      /no acepta las claves públicas de integración Oneclick/,
    );
  });

  it("un TBK_ENV distinto de integration o production no usa el fallback", () => {
    assert.throws(
      () => resolveTbkConfig({ TBK_ENV: "prod" }),
      /no es válido/,
    );
    assert.throws(
      () => resolveOneclickConfig({ TBK_ENV: "test" }),
      /no es válido/,
    );
  });

  it("producción con secretos reales no sustituye la llave", () => {
    const webpay = resolveTbkConfig(PROD_WEBPAY);
    assert.equal(webpay.env, "production");
    assert.equal(webpay.apiKey, "clave-real-de-produccion-webpay");
    assert.equal(webpay.host, "https://webpay3g.transbank.cl");

    const oneclick = resolveOneclickConfig({
      ...PROD_WEBPAY,
      TBK_ONECLICK_COMMERCE_CODE: "597012345681",
      TBK_ONECLICK_API_KEY: "clave-real-oneclick",
      TBK_ONECLICK_CHILD_CODE: "597012345682",
    });
    assert.equal(oneclick.apiKey, "clave-real-oneclick");
    assert.equal(oneclick.childCommerceCode, "597012345682");
  });
});
