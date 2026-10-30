{{flutter_js}}
{{flutter_build_config}}

// Works offline once opened: sw.js (written by tool/web_build.sh) keeps the app's files. Its scope
// is the app's folder without the last slash, so /slope-calculation/app opens offline too (the
// website allows that with a Service-Worker-Allowed header).
if ('serviceWorker' in navigator) {
  const base = new URL('.', document.baseURI);
  window.addEventListener('load', () => {
    navigator.serviceWorker
      .register(new URL('sw.js', base), { scope: base.pathname.replace(/\/$/, '') })
      .catch((e) => console.warn('Offline use is not available:', e));
  });
  // once the app is on screen, say which CanvasKit build this browser loaded, so only that one is
  // kept offline
  window.addEventListener('flutter-first-frame', () => {
    navigator.serviceWorker.ready.then((reg) => {
      const engine = performance
        .getEntriesByType('resource')
        .map((r) => r.name)
        .filter((n) => n.startsWith(new URL('canvaskit/', base).href));
      if (engine.length && reg.active) reg.active.postMessage({ keep: engine });
    });
  });
}

_flutter.loader.load();
