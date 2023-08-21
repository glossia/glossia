import { ConfigurationManifest } from "./configuration_manifest.ts";
import {
  dirname,
  join,
  relative,
} from "https://deno.land/std@0.196.0/path/posix.ts";
import { getGitCommitSHA } from "../environment.ts";
import { isDirectory, resolveGlob } from "../fs.ts";
import { deepMerge } from "https://deno.land/std@0.196.0/collections/deep_merge.ts";
import { basename } from "https://deno.land/std@0.196.0/path/mod.ts";
import {
  crypto,
  toHashString,
} from "https://deno.land/std@0.196.0/crypto/mod.ts";
import { FileFormat, getFileFormat } from "./utilities.ts";

/**
 * TODO
 *  - Rename into translation_request.ts
 * - Document the code in this module
 */
type TranslationPayloadModuleContext = {
  language: string;
};

type TranslationPayloadModule = {
  source: {
    id: string;
    context: TranslationPayloadModuleContext;
  };
  target: {
    id: string[];
    context: TranslationPayloadModuleContext;
  }[];
};

type TranslationPayload = {
  id: string;
  modules: TranslationPayloadModule[];
};

type GenerateTranslationPayloadOptions = { root: string };

/**
 * Given an array of configuration manifests, it generates a translation payload
 * to send to the server to handle the translation server-side.
 * The reason behind not doing it client-side is because we want to keep the server
 * as the source of truth for the translation logic. Once we know the files that should
 * be translated and the context, pulling and pushing files is something that can be done
 * through the APIs.
 * @param configurationManifests {ConfigurationManifest[]} A list of configuration manifests.
 * @param options {GenerateTranslationPayloadOptions} Options to generate the payload.
 * @returns {Promise<TranslationPayload>} A translation payload.
 */
export async function generateTranslationPayload(
  configurationManifests: ConfigurationManifest[],
  options: GenerateTranslationPayloadOptions,
): Promise<TranslationPayload> {
  // The id uniquely represents a content change snapshot.
  const id = getGitCommitSHA() as string;

  const modules = (await Promise.all(
    configurationManifests.map((manifest) =>
      generateTranslationModuleFromManifest(manifest, options)
    ),
  )).flatMap((modules) => modules);

  return {
    id,
    modules,
  };
}

export async function generateTranslationModuleFromManifest(
  configurationManifest: ConfigurationManifest,
  options: GenerateTranslationPayloadOptions,
): Promise<TranslationPayloadModule[]> {
  const tree = await resolveFileTree({
    relativePath: configurationManifest.files,
    basePath: dirname(configurationManifest.path),
    rootDirectory: dirname(configurationManifest.path),
    parentTree: {},
  });
  const flatTree = await flattenedTree(tree, {
    rootDirectory: dirname(configurationManifest.path),
    sourceContext: configurationManifest.context.source,
  });
  const contexts = [
    { ...configurationManifest.context.source, type: "source" },
    ...(configurationManifest.context.target.map((context) => ({
      ...context,
      type: "target",
    }))),
  ];
  contexts.forEach((context) => {
    const flatTree = pathReplacingPlaceholders(
      configurationManifest.files,
      context,
    );
  });
  console.info(flatTree);
  // console.info(JSON.stringify(tree, null, 2));

  // "files": "priv/gettext/{language}/LC_MESSAGES/*.po"
  /**
   * priv/gettext/.+/LC_MESSAGES/.+.po
   */
  return [];
}

function pathReplacingPlaceholders(
  path: string,
  placeholders: Record<string, string>,
) {
  for (const [placeholder, value] of Object.entries(placeholders)) {
    path = path.replace(`{${placeholder}}`, value);
  }

  return path;
}

type PayloadGeneratorFlattenedTree = {
  [name: string]: {
    format?: FileFormat;
    items: { [id: string]: {} };
  };
};

async function flattenedTree(
  tree: FileTree,
  { rootDirectory, sourceContext }: {
    rootDirectory: string;
    sourceContext: Record<string, string>;
  },
): Promise<PayloadGeneratorFlattenedTree> {
  const result: PayloadGeneratorFlattenedTree = {};

  async function recurse(
    { node, path }: {
      node: FileTreeNode;
      path: string[];
    },
  ) {
    if (node.type === "file" && node.children) {
      let format: FileFormat | undefined;
      if (node.children.length > 0) {
        format = getFileFormat(node.children[0]);
      }
      const pathWithPlaceholders = path.join("/");

      result[pathWithPlaceholders] = {
        format: format,
        items: Object.fromEntries(
          await Promise.all(node.children.map(async (path) => {
            const context = extractPlaceholderFromPath(
              path,
              pathWithPlaceholders,
            );
            return [path, {
              type: isSourceContext(context, sourceContext)
                ? "source"
                : "target",
              checksum: {
                current: {
                  algorithm: "sha256",
                  value: await computeSha256(join(rootDirectory, path)),
                },
              },
              context,
            }];
          })),
        ),
      };
    } else if (node.type === "directory" && node.children) {
      for (let [key, childNode] of Object.entries(node.children)) {
        if (childNode.contextPlaceholders.length > 0) {
          for (const placeholder of childNode.contextPlaceholders) {
            key = key.replace(`{${placeholder}}`, `{${placeholder}}`);
          }
        }

        await recurse({ node: childNode, path: path.concat(key) });
      }
    }
  }

  for (const rootKey of Object.keys(tree)) {
    await recurse({ node: tree[rootKey], path: [rootKey] });
  }

  return result;
}

function isSourceContext(
  context: Record<string, string>,
  sourceContext: Record<string, string>,
) {
  return Object.entries(sourceContext).every(
    ([key, value]) => context.hasOwnProperty(key) && context[key] === value,
  );
}

async function computeSha256(filepath: string) {
  const content = await Deno.readFile(filepath);
  const hash = await crypto.subtle.digest(
    "SHA-256",
    content,
  );
  const hashString = toHashString(hash);
  return hashString;
}

function extractPlaceholderFromPath(
  path: string,
  pattern: string,
): Record<string, string> {
  const placeholderNames: string[] = [];

  // Convert pattern into a regex pattern, capturing placeholders.
  const regexPattern = pattern.replace(/\{(\w+)\}/g, (_match, p1) => {
    placeholderNames.push(p1);
    return "([a-zA-Z0-9_-]+)"; // Match alphanumeric, underscores, and dashes.
  });

  const regex = new RegExp(regexPattern);
  const matches = path.match(regex);

  if (matches) {
    const result: Record<string, string> = {};
    for (let i = 0; i < placeholderNames.length; i++) {
      result[placeholderNames[i]] = matches[i + 1];
    }
    return result;
  }

  return {};
}

/**
 * A type that represents a directory tree node.
 */
type FileTreeDirectoryNode = {
  type: "directory";
  /**
   * When the path component representing this node contains placeholders, for example {language}, those are captured here.
   */
  contextPlaceholders: string[];
  children: FileTree;
};

/**
 * A type that represents a file tree node.
 */
type FileTreeFileNode = {
  type: "file";
  /**
   * When the path component representing this node contains placeholders, for example {language}, those are captured here.
   */
  contextPlaceholders: string[];
  children: string[];
};

/**
 * A type that represents a file tree node. It can be either a file or a directory.
 */
type FileTreeNode = FileTreeDirectoryNode | FileTreeFileNode;

/**
 * A type that represents a file tree.
 * It's a recursive structure that represents a directory and its children.
 */
type FileTree = {
  [name: string]: FileTreeNode;
};

/**
 * The options necessary to resolve a file tree recursively navigating the file system
 * down from the given root directory.
 */
type ResolveFileTreeOptions = {
  /** The relative path for the current recursion iteration.  */
  relativePath: string;

  /** The base path from the previous recursion iteration.. This is used to construct absolute paths. */
  basePath: string;

  /** The directory from where the recursion started. */
  rootDirectory: string;

  /** The parent tree to add children to. */
  parentTree: FileTree;
};

async function resolveFileTree(
  options: ResolveFileTreeOptions,
): Promise<FileTree> {
  // There aren't more components to traverse.
  const nextRelativePathComponent = options.relativePath.split("/").slice(0, 1)
    .shift();

  if (!nextRelativePathComponent) return options.parentTree;

  const regex = /\{(\w+)\}/g;

  // deno-lint-ignore ban-ts-comment
  // @ts-ignore
  const contextPlaceholders = [...nextRelativePathComponent.matchAll(regex)]
    .map((
      match,
    ) => match[1]);
  const globPattern = nextRelativePathComponent.replace(/\{[^}]+\}/g, "*");
  const childrenPaths = await resolveGlob(globPattern, {
    root: options.basePath,
  });
  let childrenDirectories: FileTree = {};
  let areFiles = false;
  for (const childPath of childrenPaths) {
    if (!(await isDirectory(childPath))) {
      areFiles = true;
      break;
    }
  }

  if (areFiles) {
    for (const childPath of childrenPaths) {
      options.parentTree[basename(childPath)] = {
        type: "file",
        contextPlaceholders,
        children: [relative(options.rootDirectory, childPath)],
      };
    }
  } else {
    for (const childPath of childrenPaths) {
      childrenDirectories = deepMerge(
        childrenDirectories,
        await resolveFileTree({
          relativePath: options.relativePath.replace(
            `${nextRelativePathComponent}/`,
            "",
          ),
          basePath: childPath,
          rootDirectory: options.rootDirectory,
          parentTree: {},
        }),
      );

      options.parentTree[nextRelativePathComponent] = {
        type: "directory",
        contextPlaceholders,
        children: childrenDirectories,
      };
    }
  }

  return options.parentTree;
}
