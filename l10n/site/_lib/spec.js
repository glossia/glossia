import { promises as fs } from "node:fs";
import path from "node:path";
import matter from "gray-matter";
import { compareVersionsDesc, directoryNameToVersion } from "./version.js";

const contentRoot = path.join(process.cwd(), "site", "_content");
const localeLabels = new Map([
  ["en", "English"],
  ["es", "Español"],
  ["ja", "日本語"],
]);
const localeCollator = new Intl.Collator("en");

function compareLocales(left, right) {
  if (left === right) {
    return 0;
  }

  if (left === "en") {
    return -1;
  }

  if (right === "en") {
    return 1;
  }

  return localeCollator.compare(left, right);
}

function getLocaleLabel(code) {
  return localeLabels.get(code) || code;
}

async function readVersionDirectories() {
  const entries = await fs.readdir(contentRoot, { withFileTypes: true });
  return entries
    .filter((entry) => entry.isDirectory())
    .map((entry) => directoryNameToVersion(entry.name))
    .filter(Boolean)
    .sort(compareVersionsDesc);
}

async function readLocaleDirectories(version) {
  const versionRoot = path.join(contentRoot, `v${version}`);
  const entries = await fs.readdir(versionRoot, { withFileTypes: true });
  return entries
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort(compareLocales);
}

async function loadLocaleSections(version, localeCode) {
  const localeRoot = path.join(contentRoot, `v${version}`, localeCode);
  const entries = await fs.readdir(localeRoot);
  const files = entries.filter((name) => name.endsWith(".md")).sort();
  const sections = [];

  for (const file of files) {
    const raw = await fs.readFile(path.join(localeRoot, file), "utf8");
    const parsed = matter(raw);
    sections.push({
      ...parsed.data,
      body: parsed.content,
      file,
    });
  }

  return sections;
}

async function readSpecs() {
  const versions = await readVersionDirectories();
  const specs = [];

  for (const version of versions) {
    const localeCodes = await readLocaleDirectories(version);
    const locales = localeCodes.map((code) => ({
      code,
      label: getLocaleLabel(code),
    }));
    const byLocale = {};

    for (const locale of locales) {
      byLocale[locale.code] = await loadLocaleSections(version, locale.code);
    }

    specs.push({
      version,
      locales,
      byLocale,
    });
  }

  return specs;
}

export async function loadSpecs() {
  return readSpecs();
}

export async function loadSpecVersions() {
  const specs = await loadSpecs();
  return specs.map((spec) => spec.version);
}

export async function loadLatestSpec() {
  const specs = await loadSpecs();
  return specs[0] || {
    version: "1",
    locales: [],
    byLocale: {},
  };
}

export async function loadSpecPages() {
  const specs = await loadSpecs();
  return specs.flatMap((spec) =>
    spec.locales.map((locale) => ({
      spec,
      locale,
      sections: spec.byLocale[locale.code],
    })),
  );
}
