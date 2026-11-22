import assert from "node:assert/strict";
import { describe, it } from "node:test";
import type { AppSupabase } from "../client.ts";
import { buscarProfesionales, registrarEvento } from "./buscar.ts";

function cliente(opts: { rpcError?: boolean; rows?: Record<string, unknown>[] }): AppSupabase {
  return {
    rpc: async (name: string) => {
      if (name === "registrar_evento") return { data: null, error: null };
      if (opts.rpcError) return { data: null, error: { message: "no existe" } };
      return { data: opts.rows ?? [], error: null };
    },
    from: () => {
      const consulta: Record<string, unknown> = {};
      const misma = () => consulta;
      consulta.select = misma;
      consulta.eq = misma;
      consulta.order = misma;
      consulta.range = async () => ({ data: [], error: null });
      return consulta;
    },
    auth: {},
    functions: {},
  } as unknown as AppSupabase;
}

describe("búsqueda híbrida", () => {
  it("usa la RPC cuando responde", async () => {
    const pagina = await buscarProfesionales(cliente({
      rows: [{ id_usuario: "abc", profesion: "Gasfiter", nombre: "Ana", calificacion: 4.8, modo: "lexico" }],
    }), { q: "fuga", categoria: "gasfiteria" });
    assert.equal(pagina.respaldo, false);
    assert.equal(pagina.workers[0]?.name, "Ana");
  });

  it("vuelve al catálogo si la RPC falla", async () => {
    const pagina = await buscarProfesionales(cliente({ rpcError: true }), {
      q: "fuga",
      categoria: "gasfiteria",
    });
    assert.equal(pagina.respaldo, true);
    assert.equal(pagina.modo, "catalogo");
  });

  it("registrar un evento no lanza si la RPC falta", async () => {
    const roto = {
      rpc: async () => {
        throw new Error("red");
      },
    } as unknown as AppSupabase;
    await registrarEvento(roto, { tipo: "busqueda" });
  });
});
