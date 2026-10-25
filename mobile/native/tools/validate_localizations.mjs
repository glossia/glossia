import { readFileSync } from 'node:fs';
import { resolve, extname } from 'node:path';
import { fileURLToPath } from 'node:url';

const utf8 = new TextDecoder('utf-8', { fatal: true });
const fail = message => { throw new Error(message); };
function decodeEscapes(value, apple) {
  return value.replace(/\\(u[\da-fA-F]{4}|U[\da-fA-F]{4}|[\s\S])/g, (_, escape) => {
    if (/^[uU][\da-fA-F]{4}$/.test(escape)) return String.fromCharCode(parseInt(escape.slice(1), 16));
    const allowed = { n: '\n', r: '\r', t: '\t', '"': '"', "'": "'", '\\': '\\' };
    if (!apple) Object.assign(allowed, { '@': '@', '?': '?' });
    return allowed[escape] ?? fail(`Unsupported resource escape: \\${escape}`);
  });
}

export function appleStrings(text) {
  let cursor = 0;
  const result = new Map();
  function whitespace() {
    while (cursor < text.length) {
      const rest = text.slice(cursor);
      const match = /^(?:\s+|\/\/[^\n]*(?:\n|$)|\/\*[\s\S]*?\*\/)/.exec(rest);
      if (!match) break;
      cursor += match[0].length;
    }
  }
  function quoted() {
    whitespace();
    const match = /^"((?:[^"\\\r\n]|\\(?:u[\da-fA-F]{4}|U[\da-fA-F]{4}|[nrt"'\\]))*)"/.exec(text.slice(cursor));
    if (!match) fail(`Expected a quoted .strings value at ${cursor}`);
    cursor += match[0].length;
    return decodeEscapes(match[1], true);
  }
  function punctuation(value) { whitespace(); if (text[cursor++] !== value) fail(`Expected ${value} at ${cursor - 1}`); }
  whitespace();
  while (cursor < text.length) {
    const key = quoted(); punctuation('='); const value = quoted(); punctuation(';');
    if (result.has(key)) fail(`Duplicate Apple key: ${key}`);
    result.set(key, value); whitespace();
  }
  return result;
}

function xmlEntities(value) {
  if (/&(?!amp;|quot;|apos;|lt;|gt;|#\d+;|#x[\da-fA-F]+;)/.test(value)) fail('Invalid XML entity');
  return value.replace(/&([^;]+);/g, (_, entity) => {
    const named = { amp: '&', quot: '"', apos: "'", lt: '<', gt: '>' };
    if (Object.hasOwn(named, entity)) return named[entity];
    const code = entity.startsWith('#x') ? parseInt(entity.slice(2), 16) : Number(entity.slice(1));
    if (!(code === 9 || code === 10 || code === 13 || code >= 32 && code <= 0x10ffff && !(code >= 0xd800 && code <= 0xdfff) && code !== 0xfffe && code !== 0xffff)) fail('Invalid XML character reference');
    return String.fromCodePoint(code);
  });
}

export function androidStrings(text) {
  if (/[\x00-\x08\x0b\x0c\x0e-\x1f]/.test(text)) fail('Invalid XML control character');
  let cursor = 0;
  const result = new Map();
  function skip() {
    while (true) {
      const match = /^(?:\s+|<!--[\s\S]*?-->)/.exec(text.slice(cursor));
      if (!match) break;
      if (match[0].startsWith('<!--') && match[0].slice(4, -3).includes('--')) fail('Invalid XML comment');
      cursor += match[0].length;
    }
  }
  function consume(pattern) { const match = pattern.exec(text.slice(cursor)); if (!match) fail(`Invalid Android resource XML at ${cursor}`); cursor += match[0].length; return match; }
  skip(); if (text.slice(cursor).startsWith('<?xml')) consume(/^<\?xml\s+version=["']1\.0["']\s+encoding=["']utf-8["']\s*\?>/i);
  skip(); consume(/^<resources\s*>/); skip();
  while (!text.slice(cursor).startsWith('</resources>')) {
    const tag = consume(/^<string\s+([^<>]*?)>/)[1];
    const attributes = new Map();
    let rest = tag;
    while (rest.trim()) {
      const match = /^\s*([a-z_]+)\s*=\s*(["'])([^<>]*?)\2(?:\s+|$)/.exec(rest);
      if (!match || attributes.has(match[1])) fail('Invalid or duplicate XML string attribute');
      attributes.set(match[1], xmlEntities(match[3])); rest = rest.slice(match[0].length);
    }
    const key = attributes.get('name');
    if (!key || !/^[a-z][a-z0-9_]*$/.test(key) || [...attributes.keys()].some(key => !['name', 'formatted'].includes(key)) || attributes.get('formatted') !== 'false') fail('Preserve string name and formatted="false" attributes');
    const raw = consume(/^([^<]*)<\/string>/)[1];
    const value = xmlEntities(raw).trim();
    if (!/^"(?:[^"\\]|\\(?:u[\da-fA-F]{4}|[nrt"'\\@?]))*"$/.test(value)) fail(`Use valid Android quoted string syntax: ${key}`);
    if (result.has(key)) fail(`Duplicate Android key: ${key}`);
    result.set(key, decodeEscapes(value.slice(1, -1), false)); skip();
  }
  consume(/^<\/resources>/); skip();
  if (cursor !== text.length) fail('Unexpected content after resources');
  return result;
}

export function placeholders(value) {
  let implicit = 0;
  const tokens = [];
  const pattern = /%%|%(?:(\d+)\$)?[-+0 #]*(?:\d+)?(?:\.\d+)?(hh|ll|[hljztLq])?([@diuoxXfFeEgGaAcCsSp])|%/g;
  for (const match of value.matchAll(pattern)) {
    if (match[0] === '%%' || match[0] === '%') tokens.push(match[0]);
    else tokens.push(`${match[1] ?? ++implicit}:${match[2] ?? ''}${match[3]}`);
  }
  for (const isolate of value.match(/[\u2066-\u2069]/g) ?? []) tokens.push(isolate);
  return tokens.sort().join('|');
}

export function validateCatalog(source, target, extension) {
  const parse = extension === '.strings' ? appleStrings : extension === '.xml' ? androidStrings : fail('Unsupported native resource extension');
  const original = parse(source), candidate = parse(target);
  if (original.size !== candidate.size || [...original.keys()].some(key => !candidate.has(key))) fail('Candidate must preserve every source key, with no additional keys');
  for (const [key, value] of original) {
    if (placeholders(value) !== placeholders(candidate.get(key))) fail(`Format arguments or directional isolates changed: ${key}`);
  }
}

export function validateEnvironment(env = process.env) {
  if (!env.GLOSSIA_SOURCE_PATH || !env.GLOSSIA_TARGET_PATH) fail('GLOSSIA_SOURCE_PATH and GLOSSIA_TARGET_PATH are required');
  const extension = extname(env.GLOSSIA_SOURCE_PATH);
  if (extname(env.GLOSSIA_TARGET_PATH) !== extension) fail('Native source and target extensions must match');
  const read = path => { const bytes = readFileSync(path); if (bytes.length > 4_194_304) fail('Native catalog exceeds 4 MB'); return utf8.decode(bytes).replace(/^\uFEFF/, ''); };
  validateCatalog(read(env.GLOSSIA_SOURCE_PATH), read(env.GLOSSIA_TARGET_PATH), extension);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try { validateEnvironment(); console.log('Native catalog syntax, keys and format arguments are valid.'); }
  catch (error) { console.error(error.message); process.exitCode = 1; }
}
