defmodule Glossia.Editor.PreviewBrowser do
  @moduledoc false

  # Node 22 and Chromium ship in the sandbox image. No browser connection,
  # app port, HTML, cookies or URL is ever handed to the person's browser.
  def source do
    ~S"""
    import fs from 'node:fs';
    import path from 'node:path';
    import {spawn} from 'node:child_process';
    const cfg = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
    const home = path.dirname(cfg.root);
    const port = process.env.GLOSSIA_PREVIEW_PORT || '4173';
    const browserPort = process.env.GLOSSIA_PREVIEW_BROWSER_PORT || '9222';
    const origin = 'http://127.0.0.1:' + port;
    const url = new URL(cfg.path, origin);
    if (url.origin !== origin) throw Error('invalid_route');
    const sleep = ms => new Promise(r => setTimeout(r, ms));
    const children = [];
    let socket;
    let stopped = false;
    function stop() {
      if (stopped) return;
      stopped = true;
      socket?.close();
      for (const child of children) {
        try { process.kill(-child.pid, 'SIGKILL'); } catch {}
      }
    }
    process.on('SIGTERM', () => { stop(); process.exit(0); });
    process.on('SIGINT', () => { stop(); process.exit(0); });
    process.on('exit', stop);
    const deadline = setTimeout(() => { stop(); process.exit(1); }, 850000);
    function child(command, args, env) {
      const p = spawn(command, args, {cwd: cfg.root, env, stdio: 'ignore', detached: true});
      children.push(p);
      p.on('error', () => { stop(); process.exit(1); });
      return p;
    }
    function atomic(file, data) {
      const tmp = file + '.tmp';
      fs.writeFileSync(tmp, data);
      fs.renameSync(tmp, file);
    }
    function writeContent(relative, content) {
      if (typeof relative !== 'string' || path.isAbsolute(relative) || relative.split(/[\\/]/).some(p => !p || ['..', '.', '.git'].includes(p))) throw Error('invalid_file');
      let current = cfg.root;
      const parts = relative.split('/');
      for (const part of parts.slice(0, -1)) {
        current = path.join(current, part);
        if (!fs.existsSync(current)) fs.mkdirSync(current);
        if (!fs.lstatSync(current).isDirectory() || fs.lstatSync(current).isSymbolicLink()) throw Error('unsafe_file');
      }
      atomic(path.join(cfg.root, relative), content);
    }
    function loopbackOnly() {
      if (process.platform !== 'linux') return; // trusted local fixtures only
      for (const file of ['/proc/net/tcp', '/proc/net/tcp6']) {
        const rows = fs.readFileSync(file, 'utf8').trim().split('\n').slice(1);
        for (const row of rows) {
          const columns = row.trim().split(/\s+/);
          if (columns[3] !== '0A') continue;
          const address = columns[1].split(':')[0];
          if (!['0100007F', '00000000000000000000000001000000'].includes(address)) throw Error('non_loopback_listener');
        }
      }
    }
    const safeEnv = {PATH: process.env.PATH, HOME: home, HOST: '127.0.0.1', PORT: port, NODE_ENV: 'development'};
    // Prove the discovered page depends on the actual edited file, rather
    // than accepting an unrelated homepage with a coincidentally shared title.
    // Probe bytes exist only in this disposable checkout and never in a frame.
    writeContent(cfg.probe_path, cfg.probe_content);
    const app = child('/bin/sh', ['-c', cfg.command], safeEnv);
    let appReady = false;
    for (let i = 0; i < 120; i++) {
      if (app.exitCode !== null) throw Error('app_stopped');
      try {
        const res = await fetch(url, {redirect: 'manual', signal: AbortSignal.timeout(1000)});
        if (res.status >= 200 && res.status < 300) { appReady = true; break; }
      } catch {}
      await sleep(500);
    }
    if (!appReady) throw Error('unusable_route');
    loopbackOnly();
    const browser = child(process.env.GLOSSIA_PREVIEW_CHROMIUM || 'chromium', [
      '--headless', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
      '--no-proxy-server',
      '--disable-features=LocalNetworkAccessChecks',
      '--no-first-run', '--disable-background-networking', '--disable-extensions',
      '--remote-debugging-address=127.0.0.1', '--remote-debugging-port=' + browserPort,
      '--user-data-dir=' + path.join(home, 'preview-chromium'), 'about:blank'
    ], {PATH: process.env.PATH, HOME: home});
    let target;
    for (let i = 0; i < 60; i++) {
      try {
        const targets = await (await fetch('http://127.0.0.1:' + browserPort + '/json/list', {signal: AbortSignal.timeout(1000)})).json();
        target = targets.find(t => t.type === 'page');
        if (target) break;
      } catch {}
      await sleep(250);
    }
    if (!target) throw Error('browser_unavailable');
    socket = new WebSocket(target.webSocketDebuggerUrl);
    await new Promise((resolve, reject) => { socket.onopen = resolve; socket.onerror = reject; });
    let serial = 0;
    const pending = new Map();
    let mainFrame;
    let loader;
    let context;
    let loading = false;
    let documentGeneration = 0;
    let expectedLoader;
    function cdp(method, params = {}) {
      return new Promise((resolve, reject) => {
        const id = ++serial;
        const timer = setTimeout(() => { pending.delete(id); reject(Error('browser_timeout_' + method)); }, 10000);
        pending.set(id, {resolve, reject, timer});
        socket.send(JSON.stringify({id, method, params}));
      });
    }
    socket.onmessage = async ({data}) => {
      const msg = JSON.parse(data);
      if (msg.id) {
        const item = pending.get(msg.id);
        if (!item) return;
        clearTimeout(item.timer); pending.delete(msg.id);
        if (msg.error) item.reject(Object.assign(Error('browser_error'), {cdpError: msg.error})); else item.resolve(msg.result);
      } else if (msg.method === 'Page.frameStartedLoading' && msg.params.frameId === mainFrame) {
        loading = true;
        documentGeneration++;
      } else if (msg.method === 'Page.frameNavigated' && !msg.params.frame.parentId) {
        mainFrame = msg.params.frame.id;
        loader = msg.params.frame.loaderId;
        context = undefined;
        documentGeneration++;
      } else if (msg.method === 'Page.lifecycleEvent' && msg.params.frameId === mainFrame && msg.params.loaderId === loader && msg.params.name === 'load') {
        loading = false;
      } else if (msg.method === 'Page.frameStoppedLoading' && msg.params.frameId === mainFrame) {
        loading = false;
      } else if (msg.method === 'Page.navigatedWithinDocument' && msg.params.frameId === mainFrame) {
        documentGeneration++;
      } else if (msg.method === 'Runtime.executionContextsCleared') {
        context = undefined;
        documentGeneration++;
      } else if (msg.method === 'Runtime.executionContextDestroyed' && context && (msg.params.executionContextUniqueId ? msg.params.executionContextUniqueId === context.uniqueId : msg.params.executionContextId === context.id)) {
        context = undefined;
        documentGeneration++;
      } else if (msg.method === 'Runtime.executionContextCreated' && msg.params.context.auxData?.isDefault && msg.params.context.auxData.frameId === mainFrame) {
        context = {id: msg.params.context.id, uniqueId: msg.params.context.uniqueId};
        documentGeneration++;
      } else if (msg.method === 'Fetch.requestPaused') {
        const req = msg.params;
        const u = new URL(req.request.url);
        const allowed = u.origin === origin || ['data:', 'blob:'].includes(u.protocol);
        try {
          await cdp(allowed ? 'Fetch.continueRequest' : 'Fetch.failRequest', allowed ? {requestId: req.requestId} : {requestId: req.requestId, errorReason: 'BlockedByClient'});
        } catch {}
      }
    };
    await cdp('Page.enable');
    const tree = await cdp('Page.getFrameTree');
    mainFrame = tree.frameTree.frame.id;
    loader = tree.frameTree.frame.loaderId;
    await cdp('Page.setLifecycleEventsEnabled', {enabled: true});
    await cdp('Runtime.enable');
    await cdp('Network.enable');
    await cdp('Network.setCacheDisabled', {cacheDisabled: true});
    await cdp('Network.setBlockedURLs', {urls: ['ws://*', 'wss://*']});
    await cdp('Fetch.enable', {patterns: [{urlPattern: '*', requestStage: 'Request'}]});
    await cdp('Emulation.setDeviceMetricsOverride', {width: 1200, height: 800, deviceScaleFactor: 1, mobile: false});
    function inspectionDocument() {
      if (loading || !context?.uniqueId || (expectedLoader && loader !== expectedLoader)) return null;
      return {generation: documentGeneration, uniqueId: context.uniqueId};
    }
    function currentDocument(document) {
      return document && !loading && document.generation === documentGeneration && document.uniqueId === context?.uniqueId;
    }
    async function inspect(expression, document = inspectionDocument()) {
      if (!currentDocument(document)) return null;
      try {
        const result = await cdp('Runtime.evaluate', {expression, uniqueContextId: document.uniqueId, returnByValue: true});
        return currentDocument(document) ? {result, document} : null;
      } catch (error) {
        // Only context-lifecycle failures cancel an inspection. Timeouts and
        // unrelated protocol failures remain fatal, and inputs never use this path.
        if (error.cdpError?.code === -32602 && error.cdpError.message === 'uniqueContextId not found') return null;
        if (error.cdpError?.code === -32000 && /^(Cannot find context with specified (?:unique )?id|Execution context was destroyed\.?|Inspected target navigated or closed)$/.test(error.cdpError.message)) return null;
        throw error;
      }
    }
    let revision = 0;
    let sequence = 0;
    let inputSequence = 0;
    let probed = false;
    let verified = false;
    let needsNavigation = true;
    let probeMarker = cfg.probe_marker;
    let originalContent = cfg.original_content;
    let highlightTargets = cfg.highlight_targets;
    let firstVerification = true;
    // Runs only in the disposable browser. CSS ranges neither rewrite the
    // app's DOM nor intercept pointer events, links or selection.
    function highlight(targets, reveal) {
      if (!document.body || document.readyState !== 'complete') return null;
      const normalize = value => value.replace(/\s+/g, ' ').trim();
      const queries = targets.map(normalize).filter(text => text && text.length <= 16000).slice(0, 100);
      function blockFor(element) {
        while (element && element !== document.body) {
          if (!['inline', 'contents'].includes(getComputedStyle(element).display)) return element;
          element = element.parentElement;
        }
        return document.body;
      }
      const ranges = [];
      const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT);
      let node;
      let text = '';
      let block;
      const positions = [];
      // Bound work even when a repository renders an unexpectedly large page.
      while ((node = walker.nextNode()) && positions.length < 200000) {
        if (node.nodeType === Node.ELEMENT_NODE) {
          // A rendered line break separates words even without a whitespace
          // text node. Queries are trimmed, so range endpoints stay in text.
          if (node.tagName === 'BR' && positions.length && !text.endsWith(' ') && node.checkVisibility({visibilityProperty: true, opacityProperty: true})) {
            text += ' ';
            positions.push(positions[positions.length - 1]);
          }
          continue;
        }
        const parent = node.parentElement;
        if (!parent || parent.closest('script,style,noscript,template') || !parent.checkVisibility({visibilityProperty: true, opacityProperty: true})) continue;
        const currentBlock = blockFor(parent);
        // Adjacent blocks must not fabricate a phrase that isn't rendered.
        if (positions.length && currentBlock !== block) {
          text += '\0';
          positions.push({node, offset: 0});
        }
        block = currentBlock;
        for (let offset = 0; offset < node.length && positions.length < 200000; offset++) {
          const char = /\s/.test(node.data[offset]) ? ' ' : node.data[offset];
          if (char === ' ' && text.endsWith(' ')) continue;
          text += char;
          positions.push({node, offset});
        }
      }
      for (const query of new Set(queries)) {
        let start = 0;
        while (ranges.length < 100 && (start = text.indexOf(query, start)) !== -1) {
          const first = positions[start];
          const last = positions[start + query.length - 1];
          const range = document.createRange();
          range.setStart(first.node, first.offset);
          range.setEnd(last.node, last.offset + 1);
          if (range.getClientRects().length) ranges.push(range);
          start += query.length;
        }
      }
      if (!document.adoptedStyleSheets.some(sheet => sheet.glossiaPreviewHighlight)) {
        // Constructed sheets work with strict style-src CSP without relaxing it.
        const sheet = new CSSStyleSheet();
        sheet.glossiaPreviewHighlight = true;
        sheet.replaceSync(':root{--glossia-preview-highlight-background:#fde68a;--glossia-preview-highlight-text:#1f2937}::highlight(glossia-edited-text){background-color:var(--glossia-preview-highlight-background);color:var(--glossia-preview-highlight-text)}');
        document.adoptedStyleSheets = [...document.adoptedStyleSheets, sheet];
      }
      CSS.highlights.set('glossia-edited-text', new Highlight(...ranges));
      if (reveal && ranges.length) {
        const rect = ranges[0].getBoundingClientRect();
        if (rect.bottom < 0 || rect.top > innerHeight)
          ranges[0].startContainer.parentElement.scrollIntoView({block: 'center'});
      }
      return ranges.length;
    }
    while (true) {
      if (app.exitCode !== null || browser.exitCode !== null) throw Error('runtime_stopped');
      loopbackOnly();
      try {
        const inputPath = path.join(home, 'preview-input.json');
        if (fs.statSync(inputPath).size > 12000000) throw Error('input_too_large');
        const input = JSON.parse(fs.readFileSync(inputPath, 'utf8'));
        if (verified && Number.isSafeInteger(input.revision) && input.revision > revision) {
          for (const f of input.files) {
            if (f.path === cfg.probe_path) {
              originalContent = f.content;
              writeContent(f.path, input.probe_content);
            } else writeContent(f.path, f.content);
          }
          probeMarker = input.probe_marker;
          highlightTargets = input.highlight_targets;
          probed = false;
          verified = false;
          firstVerification = false;
          revision = input.revision;
          needsNavigation = true;
        }
      } catch (e) { if (e.code !== 'ENOENT' && !(e instanceof SyntaxError)) throw e; }
      // Reload only during probe verification. Once verified, preserve app
      // navigation, client state and scroll between JPEG captures.
      if (needsNavigation) {
        // Page.navigate acknowledges the navigation request, not document load.
        // Events may precede its response; match the returned loader afterwards.
        expectedLoader = undefined;
        loading = true;
        documentGeneration++;
        const nav = await cdp('Page.navigate', {url: url.href});
        if (nav.errorText) throw Error('navigation_failed');
        expectedLoader = nav.loaderId;
        // Same-document navigation has no new loader or context to await.
        if (!nav.loaderId) loading = false;
        needsNavigation = false;
      }
      let page;
      let frameDocument;
      // Wait for hydration/rebuild, not an arbitrary sleep followed by an old
      // DOM falsely labelled with the new revision. The probe must both appear
      // and disappear before any frame for that revision is eligible.
      for (let attempt = 0; attempt < 30; attempt++) {
        const inspection = await inspect('JSON.stringify({url:location.href, text:document.body?.innerText || "", ready:document.readyState})');
        if (inspection) {
          page = JSON.parse(inspection.result.result.value);
          if (new URL(page.url).origin !== origin) throw Error('unsafe_navigation');
          const loaded = (verified || new URL(page.url).href === url.href) && page.ready === 'complete';
          const markerReady = probed ? !page.text.includes(probeMarker) : page.text.includes(probeMarker);
          if (loaded && (verified || markerReady)) { frameDocument = inspection.document; break; }
        }
        if (attempt === 29) throw Error('route_evidence_missing');
        await sleep(500);
      }
      if (!probed) {
        writeContent(cfg.probe_path, originalContent);
        probed = true;
        needsNavigation = true;
        await sleep(1000);
        continue;
      }
      const revealHighlight = !verified;
      if (!verified) {
        const normalize = s => s.replace(/\s+/g, ' ').trim();
        if (firstVerification && !normalize(page.text).includes(normalize(cfg.evidence))) throw Error('route_evidence_missing');
        verified = true;
        expectedLoader = undefined;
      }
      // A cumulative bounded batch plus sequence acknowledgements prevents
      // mailbox-file overwrites from dropping rapid click + wheel input.
      let interactions;
      try {
        const file = path.join(home, 'preview-interactions.json');
        if (fs.statSync(file).size > 16000) throw Error('input_too_large');
        interactions = JSON.parse(fs.readFileSync(file, 'utf8'));
      } catch (e) { if (e.code !== 'ENOENT' && !(e instanceof SyntaxError)) throw e; }
      let obsoleteInspection = false;
      if (interactions?.revision === revision) {
        if (!Array.isArray(interactions.inputs) || interactions.inputs.length > 32) throw Error('invalid_input');
        for (const item of interactions.inputs) {
          if (!Number.isSafeInteger(item.sequence) || item.sequence <= 0) throw Error('invalid_input');
          if (item.sequence <= inputSequence) continue;
          if (!currentDocument(frameDocument)) { obsoleteInspection = true; break; }
          const input = item.input;
          const bounded = (n, min, max) => Number.isSafeInteger(n) && n >= min && n <= max;
          if (!input || !bounded(input.x, 0, 1199) || !bounded(input.y, 0, 799)) throw Error('invalid_input');
          if (input.type === 'click' && Object.keys(input).length === 3) {
            await cdp('Input.dispatchMouseEvent', {type: 'mousePressed', x: input.x, y: input.y, button: 'left', buttons: 1, clickCount: 1});
            await cdp('Input.dispatchMouseEvent', {type: 'mouseReleased', x: input.x, y: input.y, button: 'left', buttons: 0, clickCount: 1});
          } else if (input.type === 'scroll' && Object.keys(input).length === 5 && bounded(input.delta_x, -2000, 2000) && bounded(input.delta_y, -2000, 2000)) {
            await cdp('Input.dispatchMouseEvent', {type: 'mouseWheel', x: input.x, y: input.y, deltaX: input.delta_x, deltaY: input.delta_y});
          } else throw Error('invalid_input');
          inputSequence = item.sequence;
          if (input.type === 'click') await sleep(100);
          const location = await inspect('location.origin');
          if (!location) { obsoleteInspection = true; break; }
          if (location.result.result.value !== origin) throw Error('unsafe_navigation');
          frameDocument = location.document;
        }
        // Let a whole wheel batch render once, rather than adding latency
        // for every tick and falling behind a continuous gesture.
        await sleep(100);
      }
      if (obsoleteInspection) { await sleep(100); continue; }
      const highlighted = await inspect('(' + highlight.toString() + ')(' + JSON.stringify(highlightTargets) + ',' + revealHighlight + ')', frameDocument);
      if (!highlighted) { await sleep(100); continue; }
      if (highlighted.result.exceptionDetails) throw Error('highlight_failed');
      // A same-origin click can enter a streamed document whose body hasn't
      // arrived yet. Wait for it instead of treating navigation as no match.
      if (highlighted.result.result.value === null) { await sleep(100); continue; }
      const shot = await cdp('Page.captureScreenshot', {format: 'jpeg', quality: 65, captureBeyondViewport: false});
      if (!currentDocument(highlighted.document)) continue;
      if (shot.data.length > 680000) throw Error('frame_too_large');
      atomic(path.join(home, 'preview-frame.json'), JSON.stringify({revision, sequence: ++sequence, input_sequence: inputSequence, highlights: highlighted.result.result.value, frame: shot.data}));
      await sleep(1000);
    }
    """
  end
end
