/** Precarga la foto del héroe solo en la portada. En el resto de rutas no se usa. */
(function () {
  var path = location.pathname.replace(/\/$/, '') || '/';
  if (path !== '/' && path !== '/encuesta') return;
  var narrow = window.matchMedia('(max-width: 900px)').matches;
  var link = document.createElement('link');
  link.rel = 'preload';
  link.as = 'image';
  link.href = narrow ? '/hero/tecnico-480.webp' : '/hero/tecnico-640.webp';
  link.setAttribute('fetchpriority', 'high');
  document.head.appendChild(link);
})();
