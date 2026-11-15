import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { reconcileAuthorized, safeEqual } from "./reconcile_auth.ts";

const base = {
  header: "",
  bearer: "",
  envSecret: "",
  serviceKey: "svc",
  vaultCheck: (_: string) => Promise.resolve(false),
};

Deno.test("safeEqual compara exacto", () => {
  assertEquals(safeEqual("abc", "abc"), true);
  assertEquals(safeEqual("abc", "abd"), false);
  assertEquals(safeEqual("abc", "abcd"), false);
});

Deno.test("sin credenciales rechaza y no consulta Vault", async () => {
  let called = false;
  const ok = await reconcileAuthorized({
    ...base,
    vaultCheck: () => { called = true; return Promise.resolve(true); },
  });
  assertEquals(ok, false);
  assertEquals(called, false);
});

Deno.test("Bearer service role autoriza", async () => {
  assertEquals(await reconcileAuthorized({ ...base, bearer: "svc" }), true);
  assertEquals(await reconcileAuthorized({ ...base, bearer: "otro" }), false);
});

Deno.test("header igual al secreto de entorno autoriza", async () => {
  assertEquals(await reconcileAuthorized({ ...base, envSecret: "s1", header: "s1" }), true);
});

Deno.test("sin secreto de entorno valida contra Vault", async () => {
  const vaultCheck = (s: string) => Promise.resolve(s === "vault");
  assertEquals(await reconcileAuthorized({ ...base, header: "vault", vaultCheck }), true);
  assertEquals(await reconcileAuthorized({ ...base, header: "malo", vaultCheck }), false);
});

Deno.test("secreto de entorno distinto cae a Vault", async () => {
  const vaultCheck = (s: string) => Promise.resolve(s === "vault");
  assertEquals(
    await reconcileAuthorized({ ...base, envSecret: "viejo", header: "vault", vaultCheck }),
    true,
  );
});

Deno.test("error de Vault rechaza", async () => {
  const vaultCheck = () => Promise.reject(new Error("rpc"));
  assertEquals(await reconcileAuthorized({ ...base, header: "x", vaultCheck }), false);
});
