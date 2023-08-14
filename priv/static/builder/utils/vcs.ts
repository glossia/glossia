import { ValidateFunction } from "https://esm.sh/ajv@~8.12.0";
import { expandGlob } from "https://deno.land/std@0.196.0/fs/mod.ts";
import { parse } from "https://deno.land/std@0.195.0/jsonc/mod.ts";
import { dirname, relative } from "https://deno.land/std@0.196.0/path/posix.ts";

type TranslationModuleLanguages = {
  source: string;
  target: string[];
};

type TranslationModule = {
  languages: TranslationModuleLanguages;
  files: string[];
};

type TranslationPayload = TranslationModule[];

type GenerateTranslationPayloadOptions = { root: string };

/**
 * It looks up the configuration files and generates the translation payload.
 *
 * @param options { GenerateTranslationPayloadOptions} The options to generate the translation payload
 * @returns {Promise<TranslationPayload>} The translation payload
 */
export async function generateTranslationPayload(
  options: GenerateTranslationPayloadOptions,
): Promise<TranslationPayload> {
  console.info("Loading configuration", { fromDirectory: options.root });
  const validate = await getConfigurationValidate();
  const configurationFilePaths: string[] = await loadConfigurationFilePaths(
    options.root,
  );
  const translationModules: TranslationModule[] =
    await loadConfigurationsResolvingFiles(
      configurationFilePaths,
      validate,
    );
  if (validate.errors) {
    throw new Error("Invalid configuration files found");
  }
  return translationModules;
}

async function loadConfigurationsResolvingFiles(
  configurationFilePaths: string[],
  validate: ValidateFunction<unknown>,
): Promise<TranslationModule[]> {
  const translationModules = await Promise.all(
    configurationFilePaths.map(async (configurationFilePath) => {
      console.info(`Reading configuration ${configurationFilePath}`);
      const configurationFile = parse(
        await Deno.readTextFile(configurationFilePath),
      );
      console.info(
        `Validating configuration file ${configurationFilePath}`,
        configurationFile,
      );
      const isValid = validate(configurationFile);
      console.info(`The validity of the configuration file is ${isValid}`);
      if (!isValid) {
        let error = null;
        if (validate.errors) {
          error = validate.errors![validate.errors!.length - 1];
        }
        console.error(
          `The validation of the configuration file at path ${configurationFilePath} failed:`,
          error,
        );
        return null;
      } else {
        return {
          languages:
            // deno-lint-ignore ban-ts-comment
            // @ts-ignore
            configurationFile["languages"] as TranslationModuleLanguages,
          files: await resolveConfigurationFiles(
            // deno-lint-ignore ban-ts-comment
            // @ts-ignore
            configurationFile["files"] as string[],
            {
              root: dirname(configurationFilePath),
              languages:
                // deno-lint-ignore ban-ts-comment
                // @ts-ignore
                configurationFile["languages"] as TranslationModuleLanguages,
            },
          ),
        };
      }
    }),
  );

  return translationModules.filter((translationModule) =>
    translationModule !== undefined
  ) as TranslationPayload;
}

async function resolveConfigurationFiles(
  files: string,
  { root, languages }: {
    root: string;
    languages: { source: string; target: string[] };
  },
) {
  const sourceAndTargetLanguages = [languages.source, ...languages.target];
  return (await Promise.all(
    sourceAndTargetLanguages.map(async (language) => {
      const languageGlob = files.replace("{language}", language);
      const languageFiles: string[] = [];
      for await (
        const languageFilePath of expandGlob(languageGlob, {
          root: root,
        })
      ) {
        languageFiles.push(relative(root, languageFilePath.path));
      }
      return languageFiles;
    }),
  )).flat();
}

async function loadConfigurationFilePaths(root: string) {
  const configurationFilePaths: string[] = [];
  for await (
    const configurationFilePath of expandGlob("**/glossia.jsonc", {
      root: root,
    })
  ) {
    configurationFilePaths.push(configurationFilePath.path);
  }
  return configurationFilePaths;
}
