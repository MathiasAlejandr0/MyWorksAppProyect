import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  buildFcmMessage,
  createSignedJwt,
  isDeadTokenResponse,
  parseServiceAccount,
} from "./fcm.ts";

function b64urlToBytes(s: string): Uint8Array {
  const pad = s.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((s.length + 3) % 4);
  return Uint8Array.from(atob(pad), (c) => c.charCodeAt(0));
}

async function testKeyPair() {
  const pair = await crypto.subtle.generateKey(
    {
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["sign", "verify"],
  );
  const pkcs8 = new Uint8Array(await crypto.subtle.exportKey("pkcs8", pair.privateKey));
  let bin = "";
  for (const b of pkcs8) bin += String.fromCharCode(b);
  const pem = `-----BEGIN PRIVATE KEY-----\n${btoa(bin)}\n-----END PRIVATE KEY-----\n`;
  return { pem, publicKey: pair.publicKey };
}

describe("push FCM", () => {
  it("lee la cuenta de servicio solo si trae los 3 campos", () => {
    assert.equal(parseServiceAccount(undefined), null);
    assert.equal(parseServiceAccount("no-json"), null);
    assert.equal(parseServiceAccount(JSON.stringify({ project_id: "p" })), null);
    assert.deepEqual(
      parseServiceAccount(
        JSON.stringify({ project_id: "p", client_email: "a@b", private_key: "k", extra: 1 }),
      ),
      { project_id: "p", client_email: "a@b", private_key: "k" },
    );
  });

  it("firma un JWT RS256 verificable con los claims de FCM", async () => {
    const { pem, publicKey } = await testKeyPair();
    const jwt = await createSignedJwt(
      { project_id: "p", client_email: "svc@p.iam.gserviceaccount.com", private_key: pem },
      1_700_000_000,
    );
    const [h, c, s] = jwt.split(".");
    assert.deepEqual(JSON.parse(new TextDecoder().decode(b64urlToBytes(h))), {
      alg: "RS256",
      typ: "JWT",
    });
    const claims = JSON.parse(new TextDecoder().decode(b64urlToBytes(c)));
    assert.equal(claims.iss, "svc@p.iam.gserviceaccount.com");
    assert.equal(claims.scope, "https://www.googleapis.com/auth/firebase.messaging");
    assert.equal(claims.exp - claims.iat, 3600);
    const ok = await crypto.subtle.verify(
      "RSASSA-PKCS1-v1_5",
      publicKey,
      b64urlToBytes(s),
      new TextEncoder().encode(`${h}.${c}`),
    );
    assert.equal(ok, true);
  });

  it("acepta la clave con \\n escapados como viene en el JSON de Google", async () => {
    const { pem } = await testKeyPair();
    const escaped = pem.replace(/\n/g, "\\n");
    const jwt = await createSignedJwt({ project_id: "p", client_email: "a@b", private_key: escaped });
    assert.equal(jwt.split(".").length, 3);
  });

  it("arma el mensaje con canal Android y datos para abrir el trabajo", () => {
    const msg = buildFcmMessage("tok", {
      id: "n1",
      tipo: "job_update",
      titulo: "Trabajo aceptado",
      cuerpo: "x".repeat(500),
      id_relacionado: "job-1",
    });
    assert.equal(msg.message.token, "tok");
    assert.equal(msg.message.notification.title, "Trabajo aceptado");
    assert.equal(msg.message.notification.body.length, 400);
    assert.deepEqual(msg.message.data, {
      tipo: "job_update",
      id_notificacion: "n1",
      id_relacionado: "job-1",
    });
    assert.equal(msg.message.android.notification.channel_id, "myworksapp_channel");
  });

  it("detecta tokens muertos", () => {
    assert.equal(isDeadTokenResponse(404, ""), true);
    assert.equal(isDeadTokenResponse(400, '{"error":{"details":[{"errorCode":"UNREGISTERED"}]}}'), true);
    assert.equal(isDeadTokenResponse(400, "otra cosa"), false);
    assert.equal(isDeadTokenResponse(500, "UNREGISTERED"), false);
  });
});
