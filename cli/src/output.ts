export type OutputValues = {
  lang: string;
  relpath: string;
  basename: string;
  ext: string;
};

export function expandOutput(template: string, values: OutputValues): string {
  const out = template
    .replaceAll('{lang}', values.lang)
    .replaceAll('{relpath}', values.relpath.replaceAll('\\', '/'))
    .replaceAll('{basename}', values.basename)
    .replaceAll('{ext}', values.ext);

  return normalizeSlashes(out);
}

function normalizeSlashes(input: string): string {
  let output = '';
  let lastSlash = false;

  for (const char of input) {
    if (char === '/' || char === '\\') {
      if (!lastSlash) {
        output += '/';
      }
      lastSlash = true;
      continue;
    }

    output += char;
    lastSlash = false;
  }

  return output;
}
