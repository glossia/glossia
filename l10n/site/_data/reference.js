import { promises as fs } from "node:fs";
import path from "node:path";
import { directoryNameToVersion } from "../_lib/version.js";

const rootDir = process.cwd();
const referenceRoot = path.join(rootDir, "site", "_reference");

async function readReferenceSet(versionRoot) {
  return {
    standard: await fs.readFile(path.join(versionRoot, "GLOSSIA.md"), "utf8"),
    examples: {
      singleRepo: await fs.readFile(
        path.join(versionRoot, "examples", "single-repo", "GLOSSIA.md"),
        "utf8",
      ),
      scoped: await fs.readFile(
        path.join(versionRoot, "examples", "app", "GLOSSIA.md"),
        "utf8",
      ),
      es: await fs.readFile(
        path.join(versionRoot, "examples", "app", "GLOSSIA", "es.md"),
        "utf8",
      ),
      ja: await fs.readFile(
        path.join(versionRoot, "examples", "app", "GLOSSIA", "ja.md"),
        "utf8",
      ),
    },
  };
}

export default async function () {
  const entries = await fs.readdir(referenceRoot, { withFileTypes: true });
  const byVersion = {};

  for (const entry of entries) {
    if (!entry.isDirectory()) {
      continue;
    }

    const version = directoryNameToVersion(entry.name);

    if (!version) {
      continue;
    }

    byVersion[version] = await readReferenceSet(path.join(referenceRoot, entry.name));
  }

  return {
    byVersion,
  };
}
