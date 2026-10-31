import {createServer} from 'node:http';
import {readFile} from 'node:fs/promises';
import {randomUUID} from 'node:crypto';
import path from 'node:path';

const serverNonce = randomUUID();
const source = path.join(process.cwd(), 'es/products.json');
const escapeHTML = value => value.replace(/[&<>"']/g, character => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
})[character]);

const server = createServer(async (request, response) => {
  if (new URL(request.url, 'http://localhost').pathname !== '/es/products') {
    response.writeHead(404).end('Not found');
    return;
  }
  try {
    const product = JSON.parse(await readFile(source, 'utf8'));
    if (typeof product.title !== 'string') throw Error('missing_title');
    response.writeHead(200, {'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store'});
    response.end(`<!doctype html>
<html lang="es"><head><meta charset="utf-8"><title>Resume benchmark</title>
<style>
body { margin: 20px; padding-top: 80px; font: 22px system-ui, sans-serif; color: #172033; background: #fff; }
button { position: fixed; left: 20px; top: 20px; width: 120px; height: 50px; font: 18px system-ui, sans-serif; }
pre { font: 18px ui-monospace, monospace; white-space: pre-wrap; }
</style></head><body>
<button id="increment" type="button">Increment</button>
<h1>${escapeHTML(product.title)}</h1>
<pre id="state"></pre>
<script>
window.__glossiaBench = {
  server_nonce: ${JSON.stringify(serverNonce)},
  browser_nonce: crypto.randomUUID(),
  clicks: 0,
  server_pid: ${process.pid}
};
const state = window.__glossiaBench;
const output = document.getElementById('state');
const render = () => { output.textContent = JSON.stringify(state, null, 2); };
document.getElementById('increment').addEventListener('click', () => { state.clicks++; render(); });
render();
</script></body></html>`);
  } catch {
    response.writeHead(500, {'Content-Type': 'text/plain; charset=utf-8'}).end('Invalid product source');
  }
});

server.listen(Number(process.env.PORT || '4173'), process.env.HOST || '127.0.0.1');
