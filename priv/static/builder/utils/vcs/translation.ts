import { exists } from "https://deno.land/std@0.196.0/fs/mod.ts";
import {
  ConfigurationManifest,
  ConfigurationManifestContext,
} from "./configuration_manifest.ts";
import {
  dirname,
  join,
  relative,
} from "https://deno.land/std@0.196.0/path/posix.ts";
import { expandGlob } from "https://deno.land/std@0.196.0/fs/mod.ts";
import { getGitCommitSHA } from "../environment.ts";
import { isDirectory, resolveGlob } from "../fs.ts";
import { deepMerge } from "https://deno.land/std@0.196.0/collections/deep_merge.ts";
import { basename } from "https://deno.land/std@0.196.0/path/mod.ts";
import { fileExtension } from "https://deno.land/x/file_extension/mod.ts";

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
  const tree = await resolveTree({
    relativePath: configurationManifest.files,
    basePath: dirname(configurationManifest.path),
    rootPath: dirname(configurationManifest.path),
    tree: {},
    contextAttributes: [],
  });
  const flatTree = flattenedTree(tree);
  const contexts = [
    { ...configurationManifest.context.source, type: "source" },
    ...(configurationManifest.context.target.map((context) => ({
      ...context,
      type: "target",
    }))),
  ];
  contexts.forEach((context) => {
    const pathWithPlaceholdersReplaced = pathReplacingPlaceholders(
      configurationManifest.files,
      context,
    );
  });
  console.info(configurationManifest);
  console.info(flatTree);

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

type PayloadGeneratorFlattenedTreeFormat =
  | "markdown"
  | "yaml"
  | "json"
  | "toml"
  | "portable-object";

type PayloadGeneratorFlattenedTree = {
  [name: string]: {
    format?: PayloadGeneratorFlattenedTreeFormat;
    items: { [id: string]: {} };
  };
};

function flattenedTree(
  tree: PayloadGeneratorFileTree,
): PayloadGeneratorFlattenedTree {
  const result: PayloadGeneratorFlattenedTree = {};

  function recurse(node: PayloadGeneratorFileTreeNode, path: string[] = []) {
    if (node.type === "file" && node.paths) {
      let format: PayloadGeneratorFlattenedTreeFormat | undefined;
      if (node.paths.length > 0) {
        format = getFormatFromFilePath(node.paths[0]);
      }

      result[path.join("/")] = {
        format: format,
        items: Object.fromEntries(node.paths.map((path) => [path, {
          type: "source",
          checksum: {
            saved: "456",
            current: "123",
          },
          context: {
            language: "es",
          },
        }])),
      };
    } else if (node.type === "directory" && node.children) {
      for (let [key, childNode] of Object.entries(node.children)) {
        if (childNode.placeholders.length > 0) {
          for (const placeholder of childNode.placeholders) {
            key = key.replace(`{${placeholder}}`, `{${placeholder}}`);
          }
        }

        recurse(childNode, path.concat(key));
      }
    }
  }

  for (const rootKey of Object.keys(tree)) {
    recurse(tree[rootKey], [rootKey]);
  }

  return result;
}

function getFormatFromFilePath(
  path: string,
): PayloadGeneratorFlattenedTreeFormat | undefined {
  const extension = fileExtension(path);
  switch (extension) {
    case "md":
      return "markdown";
    case "yaml":
      return "yaml";
    case "yml":
      return "yaml";
    case "json":
      return "json";
    case "toml":
      return "toml";
    case "po":
      return "portable-object";
    default:
      return undefined;
  }
}

type PayloadGeneratorFileTreeNode = {
  type: "directory";
  placeholders: string[];
  children: PayloadGeneratorFileTree;
} | { type: "file"; placeholders: string[]; paths: string[] };

type PayloadGeneratorFileTree = {
  [name: string]: PayloadGeneratorFileTreeNode;
};

async function resolveTree(
  { relativePath, basePath, tree, contextAttributes, rootPath }: {
    relativePath: string;
    basePath: string;
    rootPath: string;
    tree: PayloadGeneratorFileTree;
    contextAttributes: string[];
  },
): Promise<PayloadGeneratorFileTree> {
  // There aren't more components to traverse.
  const nextRelativePathComponent = relativePath.split("/").slice(0, 1).shift();

  if (!nextRelativePathComponent) return tree;

  const regex = /\{(\w+)\}/g;

  // deno-lint-ignore ban-ts-comment
  // @ts-ignore
  const placeholders = [...nextRelativePathComponent.matchAll(regex)].map((
    match,
  ) => match[1]);
  const globPattern = nextRelativePathComponent.replace(/\{[^}]+\}/g, "*");
  const childrenPaths = await resolveGlob(globPattern, {
    root: basePath,
  });
  let childrenDirectories: PayloadGeneratorFileTree = {};
  let areFiles = false;
  for (const childPath of childrenPaths) {
    if (!(await isDirectory(childPath))) {
      areFiles = true;
      break;
    }
  }

  if (areFiles) {
    for (const childPath of childrenPaths) {
      tree[basename(childPath)] = {
        type: "file",
        placeholders,
        paths: [relative(rootPath, childPath)],
      };
    }
  } else {
    for (const childPath of childrenPaths) {
      childrenDirectories = deepMerge(
        childrenDirectories,
        await resolveTree({
          relativePath: relativePath.replace(
            `${nextRelativePathComponent}/`,
            "",
          ),
          basePath: childPath,
          rootPath: rootPath,
          tree: {},
          contextAttributes,
        }),
      );

      tree[nextRelativePathComponent] = {
        type: "directory",
        placeholders,
        children: childrenDirectories,
      };
    }
  }

  return tree;
}
