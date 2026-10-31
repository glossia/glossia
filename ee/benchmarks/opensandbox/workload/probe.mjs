import fs from 'node:fs';
import path from 'node:path';

const home = process.env.GLOSSIA_BENCH_HOME || '/tmp/glossia';
const configPath = process.env.GLOSSIA_BENCH_CONFIG || '/opt/glossia-bench/preview-launch.json';
const browserPort = process.env.GLOSSIA_PREVIEW_BROWSER_PORT || '9222';
const linux = process.platform === 'linux';
let socket;
const deadline = setTimeout(() => {
  socket?.close();
  process.stderr.write('probe_timeout\n');
  process.exit(1);
}, 15000);

try {
  const cfg = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const targets = await (await fetch(`http://127.0.0.1:${browserPort}/json/list`, {
    signal: AbortSignal.timeout(3000)
  })).json();
  const target = targets.find(candidate => candidate.type === 'page' &&
    new URL(candidate.url).pathname === cfg.path);
  if (!target?.webSocketDebuggerUrl) throw Error('missing_page_target');
  socket = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(Error('cdp_connect_timeout')), 3000);
    socket.onopen = () => { clearTimeout(timer); resolve(); };
    socket.onerror = () => { clearTimeout(timer); reject(Error('cdp_connect_failed')); };
  });
  const evaluated = await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(Error('cdp_evaluate_timeout')), 5000);
    socket.onmessage = ({data}) => {
      const message = JSON.parse(data);
      if (message.id !== 1) return;
      clearTimeout(timer);
      if (message.error) reject(Error('cdp_evaluate_failed'));
      else resolve(message.result);
    };
    socket.onerror = () => { clearTimeout(timer); reject(Error('cdp_socket_failed')); };
    socket.send(JSON.stringify({id: 1, method: 'Runtime.evaluate', params: {
      expression: 'JSON.stringify(window.__glossiaBench)', returnByValue: true
    }}));
  });
  if (evaluated.exceptionDetails || typeof evaluated.result?.value !== 'string') throw Error('missing_page_state');
  const page = JSON.parse(evaluated.result.value);
  if (!page || typeof page.server_nonce !== 'string' || !page.server_nonce ||
    typeof page.browser_nonce !== 'string' || !page.browser_nonce ||
    !Number.isSafeInteger(page.clicks) || page.clicks < 0 ||
    !Number.isSafeInteger(page.server_pid) || page.server_pid <= 0) throw Error('invalid_page_state');

  const processes = {driver: null, server: null, chromium: null};
  let bootId = null;
  if (linux) {
    const identity = pid => {
      if (!Number.isSafeInteger(pid) || pid <= 0) throw Error('invalid_process_pid');
      const stat = fs.readFileSync(`/proc/${pid}/stat`, 'utf8');
      const fields = stat.slice(stat.lastIndexOf(')') + 2).trim().split(/\s+/);
      if (fields[0] === 'Z' || !/^\d+$/.test(fields[19])) throw Error('invalid_process_identity');
      return {pid, starttime: fields[19]};
    };
    processes.driver = identity(Number(fs.readFileSync(path.join(home, 'driver.pid'), 'utf8').trim()));
    processes.server = identity(page.server_pid);
    const chromiumPids = fs.readdirSync('/proc').filter(entry => /^\d+$/.test(entry)).filter(pid => {
      try {
        const args = fs.readFileSync(`/proc/${pid}/cmdline`, 'utf8').split('\0');
        return args.includes(`--remote-debugging-port=${browserPort}`) &&
          !args.some(argument => argument === '--type' || argument.startsWith('--type='));
      } catch (error) {
        if (error.code === 'ENOENT' || error.code === 'ESRCH') return false;
        throw error;
      }
    });
    if (chromiumPids.length !== 1) throw Error('missing_or_ambiguous_chromium_identity');
    processes.chromium = identity(Number(chromiumPids[0]));
    bootId = fs.readFileSync('/proc/sys/kernel/random/boot_id', 'utf8').trim();
    if (!bootId) throw Error('missing_boot_id');
  }
  const editedFile = fs.readFileSync(path.join(cfg.root, cfg.probe_path), 'utf8');
  const {frame: image, data: ignoredData, ...frame} = JSON.parse(fs.readFileSync(path.join(home, 'preview-frame.json'), 'utf8'));
  if (typeof image !== 'string' || !image || !Number.isSafeInteger(frame.sequence)) throw Error('missing_frame');
  process.stdout.write(JSON.stringify({page, boot_id: bootId, processes, edited_file: editedFile, frame}) + '\n');
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
} finally {
  // Keep the hard deadline active until the close handshake finishes, too.
  if (!socket || socket.readyState === WebSocket.CLOSED) clearTimeout(deadline);
  else {
    socket.addEventListener('close', () => clearTimeout(deadline), {once: true});
    socket.close();
  }
}
