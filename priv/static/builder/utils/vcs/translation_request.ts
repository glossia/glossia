import { ConfigurationManifest } from "./configuration_manifest.ts";
import { getGitCommitSHA } from "../environment.ts";
import { TranslationRequestPayload } from "./types.ts";
import { generateModulesPayload } from "./file_tree.ts";

type GenerateTranslationPayloadOptions = {
  rootDirectory: string;
  env: Deno.Env;
};

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
export async function generateTranslationRequestPayload(
  configurationManifests: ConfigurationManifest[],
  options: GenerateTranslationPayloadOptions,
): Promise<TranslationRequestPayload> {
  // The id uniquely represents a content change snapshot.
  const id = getGitCommitSHA(options.env) as string;

  const modules = (await Promise.all(
    configurationManifests.map(async (manifest) =>
      await generateModulesPayload(manifest, options)
    ),
  )).flatMap((modules) => modules);

  return {
    id,
    modules,
  };
}
