import { expandGlob } from "https://deno.land/std@0.196.0/fs/mod.ts";
import {
  ConfigurationManifest,
  loadAndValidateConfigurationManifest,
  ManifestLoadingError,
} from "./configuration_manifest.ts";
import { isSuccess } from "../result.ts";
import { HandledError } from "../errors.ts";
import { relative } from "https://deno.land/std@0.196.0/path/mod.ts";

type LoadConfigurationFilePathsOptions = { root: string };

/**
 * It looks up for all the configuration files from a given root directory.
 * @param options {LoadConfigurationFilePathsOptions} Options to configure the lookup.
 * @returns {Promise<string[]>} A promise that resolves to an array of paths to the configuration files.
 */
export async function loadConfigurationFilePaths(
  options: LoadConfigurationFilePathsOptions,
) {
  const configurationFilePaths: string[] = [];
  for await (
    const configurationFilePath of expandGlob("**/glossia.jsonc", {
      root: options.root,
    })
  ) {
    configurationFilePaths.push(configurationFilePath.path);
  }
  return configurationFilePaths;
}

type LoadConfigurationManifestsOptions = { root: string };

/**
 * Loads all the configuration manifests from a given root directory.
 * @param options {LoadConfigurationManifestsOptions} Options to configure the loading of the configuration files.
 * @returns {Promise<ConfigurationManifest[]>} A promise that resolves to an array of configuration manifests.
 */
export async function loadConfigurationManifests(
  options: LoadConfigurationManifestsOptions,
): Promise<ConfigurationManifest[]> {
  const filePaths = await loadConfigurationFilePaths(options);
  const configurationManifestResults = await Promise.all(
    filePaths.map(loadAndValidateConfigurationManifest),
  );
  const errors: ManifestLoadingError[] = [];
  const configurationManifests: ConfigurationManifest[] = [];
  for (const result of configurationManifestResults) {
    if (isSuccess(result)) {
      configurationManifests.push(result.success);
    } else {
      errors.push(result.failure);
    }
  }
  if (errors.length > 0) {
    throw new HandledError(
      getMarkdownErrorMessageFromManifestLoadingErrors(errors, options),
    );
  }
  return configurationManifests;
}

function getMarkdownErrorMessageFromManifestLoadingErrors(
  errors: ManifestLoadingError[],
  options: { root: string },
) {
  const errorMessages = errors.sort().map((error) => {
    switch (error.type) {
      case "invalid_json":
        return `- The configuration file at path \`${
          relative(options.root, error.filePath)
        }\` contains invalid JSON.`;
      case "missing_file":
        return `- The configuration file at path \`${
          relative(options.root, error.filePath)
        }\` doesn't exist.`;
      case "invalid_schema":
        return `- The configuration file at path \`${
          relative(options.root, error.filePath)
        }\` doesn't comply with the schema:
${error.errors.map((error) => `  - ${error}`).join("\n")}`;
    }
  });
  return `The following errors were found while loading the configuration manifests:\n${
    errorMessages.join("\n")
  }`;
}
