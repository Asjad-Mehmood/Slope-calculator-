// Slope Calculator offline: keeps the app's files so it opens without a connection. Written by
// tool/web_build.sh, which fills in the cache name and the file list for each build.
'use strict';

const CACHE = '__CACHE__';
const FILES = __FILES__;
// CanvasKit comes in two builds (Chromium browsers and the rest) of 5 to 7 MB; only the one this
// browser loaded is kept, when the page says which (see flutter_bootstrap.js)
const ENGINE = (f) => f.startsWith('canvaskit/');
const scope = new URL(self.registration.scope.replace(/\/?$/, '/'));
// the page, kept under the address it is opened at (exceltokml.com/slope-calculation/app): the
// website sends index.html there with a redirect, and a redirected answer can't open a page
const page = self.registration.scope.replace(/\/$/, '');

/** A copy without the "redirected" mark, which a page navigation refuses */
async function plain(res) {
  if (!res || !res.redirected) return res;
  return new Response(await res.blob(), { status: res.status, statusText: res.statusText, headers: res.headers });
}

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE);
      await cache.addAll([page, ...FILES.filter((f) => !ENGINE(f)).map((f) => new URL(f, scope).href)]);
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      for (const key of await caches.keys()) {
        if (key.startsWith('slope-') && key !== CACHE) await caches.delete(key);
      }
      await self.clients.claim();
    })(),
  );
});

// the page lists the engine files it loaded: keep those
self.addEventListener('message', (event) => {
  const urls = event.data && event.data.keep;
  if (!Array.isArray(urls)) return;
  const wanted = urls
    .map((u) => new URL(u, scope))
    .filter((u) => u.origin === scope.origin && FILES.includes(u.pathname.slice(scope.pathname.length)))
    .map((u) => u.href);
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(wanted)).catch(() => {}));
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  const url = new URL(req.url);
  // only the app's own files; the account requests (/api/...) always go to the website
  if (req.method !== 'GET' || url.origin !== scope.origin || !url.pathname.startsWith(scope.pathname.replace(/\/$/, ''))) return;

  // the page: the newest when online, the kept one offline
  if (req.mode === 'navigate' || url.href === page || url.pathname.endsWith('/index.html')) {
    event.respondWith(
      (async () => {
        try {
          const fresh = await fetch(req);
          if (fresh.ok) (await caches.open(CACHE)).put(page, await plain(fresh.clone()));
          return fresh;
        } catch (e) {
          return (await plain(await caches.match(page))) || Response.error();
        }
      })(),
    );
    return;
  }

  // everything else is versioned by the cache name: kept copy first
  event.respondWith(
    (async () => {
      const kept = await caches.match(req, { ignoreSearch: true });
      if (kept) return kept;
      const fresh = await fetch(req);
      if (fresh.ok && url.pathname.startsWith(scope.pathname)) (await caches.open(CACHE)).put(req, fresh.clone());
      return fresh;
    })(),
  );
});
