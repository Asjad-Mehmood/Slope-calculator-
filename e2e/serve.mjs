// Serves build/web the way exceltokml.com does: at /slope-calculation/app, the folder address
// answering with index.html, and sw.js allowed to look after the folder. /api is answered by the
// tests themselves (page.route), so nothing reaches the website.
import { createReadStream, existsSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname, join, normalize } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../build/web/', import.meta.url));
const base = '/slope-calculation/app';
const port = Number(process.env.PORT || 4321);
const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.bin': 'application/octet-stream',
};

createServer((req, res) => {
  const path = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  if (path === `${base}/index.html` || path === `${base}/`) {
    res.writeHead(301, { location: base }).end(); // like the website
    return;
  }
  if (!path.startsWith(base)) return res.writeHead(404).end();
  const rel = path === base ? 'index.html' : path.slice(base.length + 1);
  const file = normalize(join(root, rel));
  if (!file.startsWith(root) || !existsSync(file) || statSync(file).isDirectory()) return res.writeHead(404).end();
  const headers = { 'content-type': types[extname(file)] || 'application/octet-stream' };
  if (rel === 'sw.js') Object.assign(headers, { 'service-worker-allowed': base, 'cache-control': 'no-cache' });
  res.writeHead(200, headers);
  createReadStream(file).pipe(res);
}).listen(port, () => console.log(`http://localhost:${port}${base}`));
