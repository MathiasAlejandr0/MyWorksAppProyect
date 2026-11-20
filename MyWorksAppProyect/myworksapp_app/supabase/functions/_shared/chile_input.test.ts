import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { chileE164, postalAddress } from "./chile_input.ts";

describe("teléfono de Chile", () => {
  it("normaliza móvil y rechaza un número corto", () => {
    assert.equal(chileE164("+56 9 1234 5678"), "+56912345678");
    assert.equal(chileE164("912345678"), "+56912345678");
    assert.equal(chileE164("123"), null);
    assert.equal(chileE164("+569123"), null);
  });
});

describe("dirección", () => {
  it("pide calle y un segundo término", () => {
    assert.equal(postalAddress("Av. Cardonal 120, Puerto Montt"), "Av. Cardonal 120, Puerto Montt");
    assert.equal(postalAddress("123"), null);
    assert.equal(postalAddress("casa"), null);
  });
});
