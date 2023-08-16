import { ConfigurationManifest } from "./configuration_manifest.ts";

type TranslationPayload = {};

type GenerateTranslationPayloadOptions = { root: string };
export async function generateTranslationPayload(
  configurationManifests: ConfigurationManifest[],
  options: GenerateTranslationPayloadOptions,
): Promise<TranslationPayload> {
  return {};
}

/**
 * /builder/api/translate
 * {
 *   "modules": [{
 *     source: {
 *       "file": "....",
 *       "context": {}
 *     },
 *     target: [{
 *       "file": "....",
 *       "context": "...."
 *     }]
 *   }]
 * }
 */
