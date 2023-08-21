import {
  dirname,
  join,
  relative,
} from "https://deno.land/std@0.196.0/path/posix.ts";
import {
  getContextFromFilePath,
  getFileFormat,
  getFileSHA256,
} from "./utilities.ts";
import { isDirectory, resolveGlob } from "../fs.ts";
import { deepMerge } from "https://deno.land/std@0.196.0/collections/deep_merge.ts";
import { basename } from "https://deno.land/std@0.196.0/path/mod.ts";
import { ConfigurationManifest } from "./configuration_manifest.ts";
import { exists } from "https://deno.land/std@0.196.0/fs/exists.ts";
import {
  Context,
  FileFormat,
  TranslationRequestPayloadItem,
  TranslationRequestPayloadModule,
} from "./types.ts";

type GenerateModulesPayloadOptions = { rootDirectory: string };

/**
 * Resolves the file tree using the given configuration manifest and returns
 * a payload to initiate a translation request.
 * @param options {ConfigurationManifest} The configuration manifest.
 * @returns
 */
export async function generateModulesPayload(
  configurationManifest: ConfigurationManifest,
  options: GenerateModulesPayloadOptions,
): Promise<TranslationRequestPayloadModule[]> {
  const tree = await resolveFileTree({
    relativePath: configurationManifest.files,
    basePath: dirname(configurationManifest.path),
    rootDirectory: options.rootDirectory,
    manifestDirectory: dirname(configurationManifest.path),
    parentTree: {},
  });
  return getPayloadFromTree(tree, {
    rootDirectory: options.rootDirectory,
    sourceContext: configurationManifest.context.source,
    manifestDirectory: dirname(configurationManifest.path),
  });
}

async function getPayloadFromTree(
  tree: FileTree,
  { rootDirectory, sourceContext, manifestDirectory }: {
    rootDirectory: string;
    manifestDirectory: string;
    sourceContext: Record<string, string>;
  },
): Promise<TranslationRequestPayloadModule[]> {
  const result: TranslationRequestPayloadModule[] = [];

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
      const pathWithPlaceholders = relative(
        rootDirectory,
        join(manifestDirectory, path.join("/")),
      );

      if (!format) {
        return;
        // Unsupported format so we skip the files
      }
      let sourceItem: TranslationRequestPayloadItem | undefined;
      const targetItems: TranslationRequestPayloadItem[] = [];

      for (const path of node.children) {
        const context = getContextFromFilePath(
          path,
          pathWithPlaceholders,
        );
        const checksumRelativePath = join(
          dirname(path),
          `.glossia.${basename(path)}.json`,
        );
        const checksumPath = join(
          manifestDirectory,
          checksumRelativePath,
        );
        let cachedChecksum = { id: checksumRelativePath };
        if (await exists(checksumPath)) {
          cachedChecksum = {
            id: checksumRelativePath,
            ...JSON.parse(await Deno.readTextFile(checksumPath)),
          };
        }

        const item = {
          id: path,
          checksum: {
            current: {
              algorithm: "sha256",
              value: await getFileSHA256(
                join(rootDirectory, path),
                { ...(context as Context) },
              ),
            },
            cached: cachedChecksum,
          },
          context,
        };
        if (isSourceContext(context, sourceContext)) {
          sourceItem = item;
        } else {
          targetItems.push(item);
        }
      }

      result.push({
        id: pathWithPlaceholders,
        format: format,
        items: {
          source: sourceItem as TranslationRequestPayloadItem,
          target: targetItems,
        },
      });
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

  /** The directory containing the manifest configuration file */
  manifestDirectory: string;

  /** The root directory of the project */
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
          manifestDirectory: options.manifestDirectory,
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
