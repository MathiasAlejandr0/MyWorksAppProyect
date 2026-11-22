import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  clasificarMensaje,
  enmascararParaExterno,
  puntajeHibrido,
  redactarPerfil,
  resumirResenas,
  sanitizarMetadata,
  sugerenciaDesdeTexto,
  validarSugerencia,
  validarSugerenciaDocumento,
} from "./ia.ts";
import { crearProveedor, sugerenciaConProveedor } from "./ia_proveedor.ts";

describe("privacidad y eventos", () => {
  it("enmascara RUT, correo y teléfono antes de salir", () => {
    const salida = enmascararParaExterno("RUT 12.345.678-5 y ana@correo.cl llama al +56912345678");
    assert.equal(salida.includes("12.345.678-5"), false);
    assert.equal(salida.includes("ana@correo.cl"), false);
    assert.equal(salida.includes("912345678"), false);
    assert.match(salida, /RUT oculto/);
  });

  it("quita claves sensibles de la metadata", () => {
    const limpio = sanitizarMetadata({ rut: "1-9", comuna: "Puerto Montt", n: 2 });
    assert.deepEqual(limpio, { comuna: "Puerto Montt", n: 2 });
  });
});

describe("moderación", () => {
  it("marca pago por fuera, banco e insulto y deja pasar un pedido normal", () => {
    assert.equal(clasificarMensaje("págame por fuera de la app"), "fuera");
    assert.equal(clasificarMensaje("mi número de cuenta es este"), "banco");
    assert.equal(clasificarMensaje("qué aweonao"), "insulto");
    assert.equal(clasificarMensaje("el calefont gotea en la cocina"), "limpio");
  });

  it("deja en dudoso un texto que no calza con una regla cerrada", () => {
    assert.equal(clasificarMensaje("te paso el dato cuando llegue"), "dudoso");
  });
});

describe("asistente", () => {
  it("sugiere gasfitería urgente y marca que es una sugerencia", () => {
    const sugerencia = sugerenciaDesdeTexto("se rompió una cañería y hay una fuga hoy");
    assert.equal(sugerencia.categoria, "gasfiteria");
    assert.equal(sugerencia.urgencia, "alta");
    assert.ok(sugerencia.precio_min_clp <= sugerencia.precio_max_clp);
    assert.match(sugerencia.aviso, /Sugerencia de la IA/);
  });

  it("rechaza una salida que no cumple el esquema", () => {
    assert.equal(validarSugerencia({ categoria: "magia", urgencia: "alta", precio_min_clp: 1, precio_max_clp: 2, preguntas: [] }), null);
  });

  it("redacta el perfil sin copiar un RUT y resume reseñas", () => {
    const texto = redactarPerfil("gasfiter con rut 12.345.678-9");
    assert.equal(texto.includes("12.345.678-9"), false);
    assert.match(texto, /Trabajo con orden/);
    const resumen = resumirResenas(["Llegó a la hora", "Dejó todo limpio"]);
    assert.match(resumen, /2 reseñas/);
  });

  it("usa mock si no hay clave y valida el JSON de Ollama", async () => {
    const mock = crearProveedor({});
    assert.equal(mock.nombre, "mock");
    const sugerencia = await sugerenciaConProveedor(mock, "no hay luz en el enchufe");
    assert.equal(sugerencia?.categoria, "electricidad");

    const fetchImpl = async () => new Response(JSON.stringify({
      message: { content: JSON.stringify({
        categoria: "pintura",
        urgencia: "baja",
        precio_min_clp: 40000,
        precio_max_clp: 90000,
        preguntas: ["¿Cuántos metros hay que pintar?"],
      }) },
    }));
    const ollama = crearProveedor({ IA_PROVEEDOR: "ollama", OLLAMA_URL: "http://127.0.0.1:11434" }, fetchImpl);
    assert.equal(ollama.nombre, "ollama");
    const pintada = await sugerenciaConProveedor(ollama, "quiero pintar un muro");
    assert.equal(pintada?.categoria, "pintura");
    assert.match(pintada?.aviso ?? "", /Sugerencia de la IA/);
  });

  it("no llama a Gemini si la clave no está, aunque se pida", () => {
    assert.equal(crearProveedor({ IA_PROVEEDOR: "gemini" }).nombre, "mock");
  });
});

describe("búsqueda y documento", () => {
  it("el puntaje híbrido premia cercanía y nota sin inventar un vector", () => {
    const alto = puntajeHibrido({
      similitud: 0.9,
      distanciaKm: 1,
      calificacion: 4.8,
      nCalificaciones: 10,
      tasaCancelacion: 0,
      disputas: 0,
      horasRespuesta: 2,
    });
    const bajo = puntajeHibrido({
      similitud: 0.1,
      distanciaKm: 40,
      calificacion: 3,
      nCalificaciones: 1,
      tasaCancelacion: 0.8,
      disputas: 4,
      horasRespuesta: 48,
    });
    assert.ok(alto > bajo);
    assert.ok(alto <= 1);
  });

  it("la sugerencia de documento no conserva un RUT que el modelo haya copiado", () => {
    const doc = validarSugerenciaDocumento({
      legible: true,
      tipo: "carnet",
      nombre_coincide: true,
      confianza: 0.8,
      nota: "coincide, RUT 12.345.678-5",
    });
    assert.equal(doc?.nota.includes("12.345.678-5"), false);
    assert.equal(doc?.tipo, "carnet");
  });
});
