import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { escapeHtml, invitationHtml, pickInviteRedirect, safeInviteHref } from "./invite_html.ts";

describe("correo de invitación", () => {
  it("escapa un nombre con HTML", () => {
    const html = invitationHtml({
      name: '<img src=x onerror=alert(1)>',
      role: "Soporte",
      message: 'hola <script>alert("x")</script>',
    });
    assert.equal(html.includes("<img"), false);
    assert.equal(html.includes("<script"), false);
    assert.match(html, /&lt;img src=x onerror=alert\(1\)&gt;/);
    assert.match(html, /&lt;script&gt;/);
  });

  it("no acepta un enlace javascript", () => {
    assert.equal(safeInviteHref("javascript:alert(1)"), null);
    const html = invitationHtml({
      name: "Ana",
      role: "QA",
      message: "",
      actionLink: "javascript:alert(1)",
    });
    assert.equal(html.includes("javascript:"), false);
  });

  it("el redirect de la app instalada está permitido y un origen arbitrario no", () => {
    assert.equal(
      pickInviteRedirect("myworksapp-admin://auth/callback", "http://127.0.0.1:3001"),
      "myworksapp-admin://auth/callback",
    );
    assert.equal(
      pickInviteRedirect("https://evil.example", "http://127.0.0.1:3001"),
      "http://127.0.0.1:3001",
    );
    assert.equal(pickInviteRedirect(undefined, undefined), "myworksapp-admin://auth/callback");
  });

  it("escapeHtml cubre comillas", () => {
    assert.equal(escapeHtml(`"'&<>`), "&quot;&#39;&amp;&lt;&gt;");
  });
});
