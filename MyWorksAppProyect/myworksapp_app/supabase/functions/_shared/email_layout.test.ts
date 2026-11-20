import { assert, assertEquals, assertStringIncludes } from "jsr:@std/assert@1";
import { renderEmail, safeHref } from "./email_layout.ts";

Deno.test("renderEmail escapa script y rechaza javascript en el boton", () => {
  const { html, text } = renderEmail({
    preheader: "aviso <script>",
    title: "Titulo <script>",
    paragraphs: ["Hola <script>alert(1)</script>"],
    rows: [{ label: "Nota", value: "<script>fila</script>" }],
    button: { label: "Entrar <script>", url: "javascript:alert(1)" },
    note: "nota <script>",
  });
  assertEquals(html.includes("<script"), false);
  assertEquals(html.includes("javascript:"), false);
  assertStringIncludes(html, "&lt;script&gt;");
  assertStringIncludes(html, "Duoc UC");
  assertStringIncludes(text, "Duoc UC");
  assertEquals(safeHref("javascript:alert(1)"), null);
  assertEquals(safeHref("http://127.0.0.1/x"), null);
  assert(safeHref("https://myworksapp.cl/aviso-legal")?.startsWith("https://"));
  assert(safeHref("myworksapp-admin://auth/callback")?.startsWith("myworksapp-admin:"));
  assert(safeHref("cl.myworksapp.auth://login-callback")?.startsWith("cl.myworksapp.auth:"));
});
