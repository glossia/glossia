import { exists } from "https://deno.land/std@0.196.0/fs/mod.ts";
import {
  ConfigurationManifest,
  ConfigurationManifestContext,
} from "./configuration_manifest.ts";
import { dirname, join } from "https://deno.land/std@0.196.0/path/posix.ts";
import { expandGlob } from "https://deno.land/std@0.196.0/fs/mod.ts";
import { getGitCommitSHA } from "../environment.ts";
import { isDirectory, resolveGlob } from "../fs.ts";
import { deepMerge } from "https://deno.land/std@0.196.0/collections/deep_merge.ts";
import { basename } from "https://deno.land/std@0.196.0/path/mod.ts";

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

async function generateTranslationModuleFromManifest(
  configurationManifest: ConfigurationManifest,
  options: GenerateTranslationPayloadOptions,
): Promise<TranslationPayloadModule[]> {
  // "files": "priv/gettext/{language}/LC_MESSAGES/*.po"
  /**
   * priv/gettext/.+/LC_MESSAGES/.+.po
   */
  /**
   * priv/gettext/es/LC_MESSAGES/default.po
   * priv/gettext/es/LC_MESSAGES/errors.po
   * priv/gettext/en/LC_MESSAGES/default.po
   * priv/gettext/en/LC_MESSAGES/errors.po
   */

  /**
   * {
   *   name: "posts",
   *   children: [
   *      {
   *        name: "1",
   *        children: [
   *        {
   *          name: "en.md"
   *          placeholder: language
   *        }]
   *      }
   *   ]
   * }
   */

  // /**
  //  * posts/*/{lang}.md
  //  * posts/
  //  *   1/
  //  *     en.md
  //  *     es.md
  //  *     de.md
  //  *   2/
  //  *     en.md
  //  *     es.md
  //  *     de.md
  //  */

  return [];
}
/**
 * {
 *    "posts": {
 *      children: {
 *
 *      }
 *    }
 * }
 */

type PayloadGeneratorFileTree = {
  [name: string]: {
    type: "directory";
    placeholders: string[];
    children: PayloadGeneratorFileTree;
  } | { type: "file"; placeholders: string[] };
};

export async function resolveTree(
  { relativePath, basePath, tree, contextAttributes }: {
    relativePath: string;
    basePath: string;
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

async function resolveModulePaths(
  configurationManifest: ConfigurationManifest,
): Promise<Set<string>> {
  const sourcePaths = await resolveContextPaths(
    configurationManifest.context.source,
    configurationManifest,
  );
  const targetPaths = (await Promise.all(
    configurationManifest.context.target.map(async (targetContext) => {
      return await resolveContextPaths(targetContext, configurationManifest);
    }),
  )).flatMap((paths) => paths);

  return new Set([...sourcePaths, ...targetPaths]);
}

async function resolveContextPaths(
  context: ConfigurationManifestContext,
  configurationManifest: ConfigurationManifest,
): Promise<string[]> {
  const manifestDirectory = dirname(configurationManifest.path);
  let filesWithContextVariablesReplaced = configurationManifest.files;
  for (const property in context) {
    // deno-lint-ignore no-prototype-builtins
    if (context.hasOwnProperty(property)) {
      filesWithContextVariablesReplaced = filesWithContextVariablesReplaced
        // deno-lint-ignore ban-ts-comment
        // @ts-ignore
        .replace(`{${property}}`, context[property]);
    }
  }

  const files: string[] = [];
  for await (
    const configurationFilePath of expandGlob(
      join(manifestDirectory, filesWithContextVariablesReplaced),
    )
  ) {
    files.push(configurationFilePath.path);
  }
  return files;
}
