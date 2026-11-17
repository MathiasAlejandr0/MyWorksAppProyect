// Página puente: recibe acción, campo y token en el # y hace POST a Transbank.
(function () {
  var HOSTS = ["webpay3gint.transbank.cl", "webpay3g.transbank.cl"];
  var FIELDS = ["token_ws", "TBK_TOKEN"];
  var msg = document.getElementById("msg");
  try {
    var p = new URLSearchParams(location.hash.slice(1));
    var action = new URL(p.get("a") || "");
    var field = p.get("f") || "";
    var token = p.get("t") || "";
    if (action.protocol !== "https:" || HOSTS.indexOf(action.hostname) < 0 ||
        FIELDS.indexOf(field) < 0 || !token) {
      throw new Error("invalid");
    }
    history.replaceState(null, "", location.pathname);
    var form = document.getElementById("tbk");
    form.action = action.toString();
    var input = document.createElement("input");
    input.type = "hidden";
    input.name = field;
    input.value = token;
    form.appendChild(input);
    form.submit();
  } catch (e) {
    msg.textContent = "No se pudo abrir Transbank. Vuelve a la app e inténtalo de nuevo.";
  }
})();
