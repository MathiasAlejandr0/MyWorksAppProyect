// Solo maneja GET del mismo origen. Lo externo (Supabase, Unsplash, fuentes,
// mapas, Transbank) va directo a la red: si pasa por aquí, el CSP de este
// script (connect-src) lo bloquea y las imágenes y fuentes no cargan.
// La página se pide primero a la red, para que un deploy nuevo no deje
// un index.html viejo apuntando a assets que ya no existen.
const CACHE_NAME = 'myworksapp-v2';
const ASSETS_TO_CACHE = ['/', '/manifest.json'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS_TO_CACHE)),
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k))),
      )
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return;
  if (new URL(request.url).origin !== self.location.origin) return;

  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request).catch(() => caches.match('/').then((r) => r || Response.error())),
    );
    return;
  }

  event.respondWith(caches.match(request).then((r) => r || fetch(request)));
});
