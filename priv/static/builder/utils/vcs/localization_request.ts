import { ConfigurationManifest } from "./configuration_manifest.ts";
import { getEventVersion } from "../environment.ts";
import { LocalizationRequestPayload } from "./types.ts";
import { generateModulesPayload } from "./file_tree.ts";

type GenerateLocalizationPayloadOptions = {
  rootDirectory: string;
  env: Deno.Env;
};

/**
 * Given an array of configuration manifests, it generates a localization request payload
 * to send to the server to handle the localization server-side.
 * The reason behind not doing it client-side is because we want to keep the server
 * as the source of truth for the localization logic. Once we know the files that should
 * be translated and the context, pulling and pushing files is something that can be done
 * through the APIs.
 * @param configurationManifests {ConfigurationManifest[]} A list of configuration manifests.
 * @param options {GenerateLocalizationPayloadOptions} Options to generate the payload.
 * @returns {Promise<LocalizationPayload>} A localization payload.
 */
export async function generateLocalizationRequestPayload(
  configurationManifests: ConfigurationManifest[],
  options: GenerateLocalizationPayloadOptions,
): Promise<LocalizationRequestPayload> {
  // The id uniquely represents a content change snapshot.
  const id = getEventVersion(options.env) as string;

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
