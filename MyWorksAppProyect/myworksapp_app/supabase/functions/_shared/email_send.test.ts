import { assertEquals, assertStringIncludes } from "jsr:@std/assert@1";
import { sendEmail } from "./email_send.ts";

const content = {
  html: "<p>Hola</p>",
  text: "Hola",
};

function rememberEnv(name: string): string | undefined {
  return Deno.env.get(name);
}

function restoreEnv(name: string, value: string | undefined): void {
  if (value === undefined) Deno.env.delete(name);
  else Deno.env.set(name, value);
}

Deno.test("sin secretos no llama a Resend", async () => {
  const key = rememberEnv("RESEND_API_KEY");
  const from = rememberEnv("RESEND_FROM");
  Deno.env.delete("RESEND_API_KEY");
  Deno.env.delete("RESEND_FROM");
  let called = false;
  const original = globalThis.fetch;
  globalThis.fetch = () => {
    called = true;
    return Promise.resolve(new Response("{}", { status: 200 }));
  };
  try {
    const result = await sendEmail({
      to: "ana@myworksapp.cl",
      subject: "Prueba",
      content,
    });
    assertEquals(result, { ok: false, reason: "correo_no_configurado" });
    assertEquals(called, false);
  } finally {
    globalThis.fetch = original;
    restoreEnv("RESEND_API_KEY", key);
    restoreEnv("RESEND_FROM", from);
  }
});

Deno.test("fetch simulado devuelve el id y no escribe el correo en el log", async () => {
  const key = rememberEnv("RESEND_API_KEY");
  const from = rememberEnv("RESEND_FROM");
  Deno.env.set("RESEND_API_KEY", "re_test");
  Deno.env.set("RESEND_FROM", "MyWorksApp <no-responder@myworksapp.cl>");
  const logs: string[] = [];
  const originalLog = console.log;
  const originalFetch = globalThis.fetch;
  console.log = (...args: unknown[]) => {
    logs.push(args.map((item) => String(item)).join(" "));
  };
  globalThis.fetch = (_input, init) => {
    const headers = new Headers(init?.headers);
    assertEquals(headers.get("Idempotency-Key"), "pago-1-alta");
    assertEquals(headers.get("Authorization"), "Bearer re_test");
    return Promise.resolve(new Response(JSON.stringify({ id: "re_123" }), { status: 200 }));
  };
  try {
    const result = await sendEmail({
      to: "Ana@MyWorksApp.cl",
      subject: "Prueba",
      content,
      idempotencyKey: "pago-1-alta",
    });
    assertEquals(result, { ok: true, id: "re_123" });
    assertEquals(logs.length, 1);
    assertStringIncludes(logs[0], "email: resend 200");
    assertEquals(logs[0].includes("Ana@"), false);
    assertEquals(logs[0].includes("myworksapp.cl"), false);
  } finally {
    console.log = originalLog;
    globalThis.fetch = originalFetch;
    restoreEnv("RESEND_API_KEY", key);
    restoreEnv("RESEND_FROM", from);
  }
});
