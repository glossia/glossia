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
  extractPlaceholderValuesFromFilePath,
  FileFormat,
  getFileFormat,
  getFileSHA256,
} from "./utilities.ts";

export type Context = {
  language: string;
  country?: string;
};
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
  // const tree = await resolveFileTree({
  //   relativePath: configurationManifest.files,
  //   basePath: dirname(configurationManifest.path),
  //   rootDirectory: dirname(configurationManifest.path),
  //   parentTree: {},
  // });
  // const flatTree = await flattenedTree(tree, {
  //   rootDirectory: dirname(configurationManifest.path),
  //   sourceContext: configurationManifest.context.source,
  // });
  // const contexts = [
  //   { ...configurationManifest.context.source, type: "source" },
  //   ...(configurationManifest.context.target.map((context) => ({
  //     ...context,
  //     type: "target",
  //   }))),
  // ];
  // contexts.forEach((context) => {
  //   const flatTree = pathReplacingPlaceholders(
  //     configurationManifest.files,
  //     context,
  //   );
  // });
  // console.info(JSON.stringify(flatTree, null, 2));
  // console.info(JSON.stringify(tree, null, 2));

  // "files": "priv/gettext/{language}/LC_MESSAGES/*.po"
  /**
   * priv/gettext/.+/LC_MESSAGES/.+.po
   */
  return [];
}
