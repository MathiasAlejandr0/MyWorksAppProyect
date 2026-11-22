import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { esAlertaIa, leerAlertasIa, leerModeracion, resumenSugerencia } from "./ia-consola.ts";

describe("consola de IA", () => {
  it("se queda con las alertas del motor y deja fuera el resto", () => {
    const leido = leerAlertasIa({
      bandera: false,
      alertas: [
        { id: "1", tipo: "ia_banco_retiro", severidad: "alta", resumen: "Cambió la cuenta", estado: "abierto", detalle: { propuesta: true } },
        { id: "2", tipo: "logins_fallidos", resumen: "global" },
      ],
    });
    assert.equal(leido.bandera, false);
    assert.equal(leido.alertas.length, 1);
    assert.equal(esAlertaIa("ia_anomalia"), true);
    assert.match(leido.alertas[0].detalle, /propuesta/);
  });

  it("la cola muestra el veredicto sin borrar el extracto", () => {
    const filas = leerModeracion([
      { id: "m1", id_mensaje: "abc", motivo: "insulto", estado: "pendiente", extracto: "qué aweonao", veredicto_llm: "" },
    ]);
    assert.equal(filas[0].extracto, "qué aweonao");
    assert.equal(filas[0].estado, "pendiente");
  });

  it("la ficha dice que la validación es una sugerencia", () => {
    const texto = resumenSugerencia({ tipo: "carnet", nota: "legible", decision: "pendiente_humano" });
    assert.match(texto, /Sugerencia de la IA/);
    assert.match(texto, /humana/);
  });
});
