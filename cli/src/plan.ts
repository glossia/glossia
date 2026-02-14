import path from 'node:path';
import { access, readFile } from 'node:fs/promises';
import {
  type AgentConfig,
  type ContentFile,
  type Entry,
  type LLMConfig,
  collectEntries,
  mergeLlm,
  parseContentFile,
  resolveAgents,
  splitTomlFrontmatter,
} from './config.js';
import { detectFormat, type Format } from './format.js';
import { globFiles, walkFiles } from './glob.js';
import { expandOutput } from './output.js';
import { globBase, isAncestor, normalizeSlashes, relativePath } from './pathing.js';

export type EntryKind = 'translate' | 'revisit';

export type OutputPlan = {
  lang?: string;
  outputPath: string;
};

export type LLMPlan = {
  coordinator: AgentConfig;
  translator: AgentConfig;
};

export type SourcePlan = {
  sourcePath: string;
  absPath: string;
  basePath: string;
  relPath: string;
  format: Format;
  kind: EntryKind;
  entry: Entry;
  contextBodies: string[];
  langContextBodies: Record<string, string[]>;
  contextPaths: string[];
  llm: LLMPlan;
  outputs: OutputPlan[];
};

export type Plan = {
  root: string;
  contentFiles: ContentFile[];
  sources: SourcePlan[];
};

type Candidate = {
  entry: Entry;
  basePath: string;
};

export function outputLangKey(output: OutputPlan): string {
  return output.lang ?? '_';
}

export function outputFormatLabel(sourcePath: string, output: OutputPlan): string {
  if (output.lang) {
    return `${sourcePath} -> ${output.outputPath} (${output.lang})`;
  }

  return `${sourcePath} -> ${output.outputPath}`;
}

export function contextPartsFor(source: SourcePlan, langKey: string): string[] {
  const parts = [...source.contextBodies];
  const langParts = source.langContextBodies[langKey] ?? [];
  parts.push(...langParts);
  return parts;
}

export async function buildPlan(root: string): Promise<Plan> {
  const rootAbs = path.resolve(root);
  const contentFiles = await discoverContent(rootAbs);
  const entries = collectEntries(contentFiles);

  const fileList = await walkFiles(rootAbs);
  const candidates = resolveEntries(rootAbs, entries, fileList);

  const sources: SourcePlan[] = [];

  for (const [sourcePath, candidate] of candidates) {
    const absPath = path.join(rootAbs, sourcePath);
    const contextFiles = ancestorsFor(absPath, contentFiles);

    const isTranslate = candidate.entry.targets.length > 0;
    const kind: EntryKind = isTranslate ? 'translate' : 'revisit';

    const contextBodies: string[] = [];
    const contextPaths: string[] = [];
    const langContextBodies: Record<string, string[]> = {};
    let llmConfig: LLMConfig = { agent: [] };

    for (const file of contextFiles) {
      if (file.body.trim()) {
        contextBodies.push(file.body);
        contextPaths.push(file.path);
      }

      if (isTranslate) {
        for (const lang of candidate.entry.targets) {
          const langBody = await readLangContext(file.dir, lang);
          if (langBody) {
            langContextBodies[lang] = [...(langContextBodies[lang] ?? []), langBody];
          }
        }
      }

      llmConfig = mergeLlm(llmConfig, file.config.llm);
    }

    const { coordinator, translator } = resolveAgents(llmConfig);
    const relPath = relativePath(path.join(rootAbs, candidate.basePath), absPath);
    const ext = path.extname(sourcePath).replace(/^\./, '');
    const basename = path.basename(sourcePath, path.extname(sourcePath));

    const outputs: OutputPlan[] = [];
    if (isTranslate) {
      for (const lang of candidate.entry.targets) {
        outputs.push({
          lang,
          outputPath: expandOutput(candidate.entry.output, {
            lang,
            relpath: normalizeSlashes(relPath),
            basename,
            ext,
          }),
        });
      }
    } else if (!candidate.entry.output.trim()) {
      outputs.push({ outputPath: sourcePath });
    } else {
      outputs.push({
        outputPath: expandOutput(candidate.entry.output, {
          lang: '',
          relpath: normalizeSlashes(relPath),
          basename,
          ext,
        }),
      });
    }

    sources.push({
      sourcePath,
      absPath,
      basePath: candidate.basePath,
      relPath,
      format: detectFormat(sourcePath),
      kind,
      entry: candidate.entry,
      contextBodies,
      langContextBodies,
      contextPaths,
      llm: { coordinator, translator },
      outputs,
    });
  }

  sources.sort((a, b) => a.sourcePath.localeCompare(b.sourcePath));

  return {
    root: rootAbs,
    contentFiles,
    sources,
  };
}

function resolveEntries(
  root: string,
  entries: Entry[],
  fileList: string[],
): Array<[string, Candidate]> {
  const candidates = new Map<string, Candidate>();

  for (const entry of entries) {
    const { pattern, basePath } = entryPattern(root, entry);
    const matches = globFiles(pattern, fileList);
    const excludes = resolveExcludes(root, entry, fileList);

    for (const match of matches) {
      if (excludes.has(match)) {
        continue;
      }
      if (path.basename(match) === 'CONTENT.md') {
        continue;
      }

      const current = candidates.get(match);
      if (!current || shouldOverride(current.entry, entry)) {
        candidates.set(match, {
          entry,
          basePath,
        });
      }
    }
  }

  return [...candidates.entries()].sort((a, b) => a[0].localeCompare(b[0]));
}

function shouldOverride(existing: Entry, candidate: Entry): boolean {
  if (candidate.originDepth > existing.originDepth) {
    return true;
  }

  return candidate.originDepth === existing.originDepth && candidate.index > existing.index;
}

function entryPattern(root: string, entry: Entry): { pattern: string; basePath: string } {
  const relDir = relativePath(root, entry.originDir);
  const src = entry.source.trim() || entry.path.trim();
  const prefix = relDir === '.' ? '' : relDir;

  const pattern = normalizeSlashes(prefix ? `${prefix}/${src}` : src);

  let basePath = globBase(pattern);
  if (basePath === '.') {
    basePath = prefix || '.';
  }

  return { pattern, basePath };
}

function resolveExcludes(root: string, entry: Entry, fileList: string[]): Set<string> {
  const excludes = new Set<string>();
  if (entry.exclude.length === 0) {
    return excludes;
  }

  const relDir = relativePath(root, entry.originDir);
  const prefix = relDir === '.' ? '' : relDir;

  for (const pattern of entry.exclude) {
    const scopedPattern = normalizeSlashes(prefix ? `${prefix}/${pattern}` : pattern);
    for (const file of globFiles(scopedPattern, fileList)) {
      excludes.add(file);
    }
  }

  return excludes;
}

async function discoverContent(root: string): Promise<ContentFile[]> {
  const fileList = await walkFiles(root);
  const contentPaths = fileList.filter((file) => path.basename(file) === 'CONTENT.md');

  const files: ContentFile[] = [];

  for (const relPath of contentPaths) {
    const absPath = path.join(root, relPath);
    const parsed = await parseContentFile(absPath);
    const relDir = relativePath(root, parsed.dir);

    parsed.depth = relDir === '.' ? 0 : normalizeSlashes(relDir).split('/').length;

    files.push(parsed);
  }

  files.sort((a, b) => a.depth - b.depth);
  return files;
}

function ancestorsFor(sourceAbsPath: string, contentFiles: ContentFile[]): ContentFile[] {
  return contentFiles
    .filter((file) => isAncestor(file.dir, sourceAbsPath))
    .sort((a, b) => a.depth - b.depth);
}

async function readLangContext(dir: string, lang: string): Promise<string> {
  const trimmed = lang.trim();
  if (!trimmed) {
    throw new Error('empty language code');
  }
  if (trimmed.includes('/') || trimmed.includes('\\')) {
    throw new Error(`invalid language code "${lang}"`);
  }

  const filePath = path.join(dir, 'CONTENT', `${trimmed}.md`);

  try {
    await access(filePath);
  } catch {
    return '';
  }

  const data = await readFile(filePath, 'utf8');
  const split = splitTomlFrontmatter(data);
  return split.hasFrontmatter ? split.body : data;
}
