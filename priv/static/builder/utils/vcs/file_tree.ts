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
  FileFormat,
  LocalizationPayloadModule,
  LocalizationPayloadSourceLocalizable,
  LocalizationPayloadTargetLocalizable,
  SourceContext,
} from "./types.ts";

type GenerateModulesPayloadOptions = { rootDirectory: string };

/**
 * Resolves the file tree using the given configuration manifest and returns
 * a payload to initiate a localization request.
 * @param options {ConfigurationManifest} The configuration manifest.
 * @returns
 */
export async function generateModulesPayload(
  configurationManifest: ConfigurationManifest,
  options: GenerateModulesPayloadOptions,
): Promise<LocalizationPayloadModule[]> {
  const tree = await resolveFileTree({
    relativePath: configurationManifest.files,
    basePath: dirname(configurationManifest.path),
    rootDirectory: options.rootDirectory,
    manifestDirectory: dirname(configurationManifest.path),
    parentTree: {},
  });
  let modules = await getPayloadFromTree(tree, {
    rootDirectory: options.rootDirectory,
    sourceContext: configurationManifest.context.source,
    manifestDirectory: dirname(configurationManifest.path),
  });
  modules = await payloadAddingAbsentLocalizableTargets(modules, {
    configurationManifest,
  });

  return modules;
}

type PayloadAddingAbsentLocalizableTargetsOptions = {
  configurationManifest: ConfigurationManifest;
};

/**
 * When we resolve the tree and flatten it, we do it using the file-system as the source of truth. As a consequence,
 * target languages that haven't been added to the file system yet won't be present in the payload.
 * This function ensures those files are present and includes them in the payload. That way, the server will see
 * that they need to be translated
 * @param modules {LocalizationPayloadModule[]} The modules to add the absent localizable targets to.
 * @param options {PayloadAddingAbsentLocalizableTargetsOptions} The options necessary to add the absent localizable targets.
 * @returns {LocalizationPayloadModule[]} The modules with the absent localizable targets added.
 */
function payloadAddingAbsentLocalizableTargets(
  modules: LocalizationPayloadModule[],
  options: PayloadAddingAbsentLocalizableTargetsOptions,
): LocalizationPayloadModule[] {
  return modules.map((module) => {
    const id = module.id;

    for (const context of options.configurationManifest.context.target) {
      let path = id;
      for (const contextAttribute of Object.entries(context)) {
        path = path.replace(
          `{${contextAttribute[0]}}`,
          contextAttribute[1],
        );
      }
      if (module.localizables.target.find((target) => target.id === path)) {
        continue;
      }
      module = {
        ...module,
        localizables: {
          ...module.localizables,
          target: [
            ...module.localizables.target,
            {
              id: path,
              context: context,
              checksum: {
                cache_id: getChecksumJSONPathFromRelativePath(path),
              },
            },
          ],
        },
      };
    }
    return module;
  });
}

function getChecksumJSONPathFromRelativePath(path: string) {
  return join(
    dirname(path),
    `.glossia.${basename(path)}.json`,
  );
}

async function getPayloadFromTree(
  tree: FileTree,
  {
    rootDirectory,
    sourceContext,
    manifestDirectory,
  }: {
    rootDirectory: string;
    manifestDirectory: string;
    sourceContext: Record<string, string>;
  },
): Promise<LocalizationPayloadModule[]> {
  const result: LocalizationPayloadModule[] = [];

  async function recurse({
    node,
    path,
  }: {
    node: FileTreeNode;
    path: string[];
  }) {
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
      let sourceLocalizable:
        | LocalizationPayloadSourceLocalizable
        | undefined;
      const targetLocalizablees: LocalizationPayloadTargetLocalizable[] = [];

      for (const path of node.children) {
        const context = getContextFromFilePath(path, pathWithPlaceholders);
        const checksumRelativePath = getChecksumJSONPathFromRelativePath(path);
        const checksumPath = join(manifestDirectory, checksumRelativePath);
        let cachedChecksum:
          | {
            algorithm: string;
            value: string;
          }
          | undefined;

        if (await exists(checksumPath)) {
          /**
           * TODO
           * We are assuming here that the schema of the lockfile evolves incrementally.
           * In other words, changes are backward compatible.
           */
          cachedChecksum = JSON.parse(await Deno.readTextFile(checksumPath));
        }

        const item = {
          id: path,
          checksum: {
            cache_id: checksumRelativePath,
            cache: cachedChecksum,
            content: {
              algorithm: "sha256",
              value: await getFileSHA256(join(rootDirectory, path)),
            },
          },
          context,
        };
        if (isSourceContext(context, sourceContext)) {
          sourceLocalizable = {
            ...item,
            context: sourceContext as SourceContext,
          };
        } else {
          targetLocalizablees.push(item);
        }
      }

      result.push({
        id: pathWithPlaceholders,
        format: format,
        localizables: {
          source: sourceLocalizable as LocalizationPayloadSourceLocalizable,
          target: targetLocalizablees,
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
  return Object.entries(context).every(
    ([key, value]) =>
      // deno-lint-ignore ban-ts-comment
      // @ts-ignore
      // deno-lint-ignore no-prototype-builtins
      context.hasOwnProperty(key) && sourceContext[key] === value,
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

function hasPathAnyComponents(path: string) {
  if (path === "") {
    return false;
  }
  const components = path.replace(/^\/|\/$/g, "").split("/");
  return components.length >= 1;
}

async function resolveFileTree(
  options: ResolveFileTreeOptions,
): Promise<FileTree> {
  // There aren't more components to traverse.
  const nextRelativePathComponent = options.relativePath
    .split("/")
    .slice(0, 1)
    .shift();

  if (!nextRelativePathComponent) return options.parentTree;

  const regex = /\{(\w+)\}/g;

  // deno-lint-ignore ban-ts-comment
  // @ts-ignore
  const contextPlaceholders = [
    ...nextRelativePathComponent.matchAll(regex),
  ].map((match) => match[1]);
  const globPattern = nextRelativePathComponent.replace(/\{[^}]+\}/g, "*");
  const childrenPaths = await resolveGlob(globPattern, {
    root: options.basePath,
  });

  let childrenDirectories: FileTree = {};
  const nextRelativePath = options.relativePath.replace(
    new RegExp(`${nextRelativePathComponent.replaceAll("*", "\\*")}/?`),
    "",
  );

  const hasNextRelativePathAnyComponent = hasPathAnyComponents(
    nextRelativePath,
  );

  for (const childPath of childrenPaths) {
    const _isDirectory = await isDirectory(childPath);
    if (!_isDirectory && hasNextRelativePathAnyComponent) {
      continue;
    } else if (!_isDirectory && !hasNextRelativePathAnyComponent) {
      options.parentTree[basename(childPath)] = {
        type: "file",
        contextPlaceholders,
        children: [relative(options.rootDirectory, childPath)],
      };
    } else if (_isDirectory && hasNextRelativePathAnyComponent) {
      childrenDirectories = deepMerge(
        childrenDirectories,
        await resolveFileTree({
          relativePath: nextRelativePath,
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
    } else if (_isDirectory && !hasNextRelativePathAnyComponent) {
      continue;
    }
  }

  return options.parentTree;
}
