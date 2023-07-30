import Ajv, { ValidateFunction } from "https://esm.sh/ajv@8.6.1";
import { expandGlob } from "https://deno.land/std@0.196.0/fs/mod.ts";
import { parse } from "https://deno.land/std@0.195.0/jsonc/mod.ts";

type Configuration = {
  path: string;
  languages: {
    source: string;
    target: string[];
  };
  files: string[];
};

/**
 * It returns a function that validates the configuration.
 * Documentation: https://ajv.js.org/guide/managing-schemas.html
 *
 * @returns {Promise<(data: any) => boolean>} A function that validates the configuration
 */
export async function getConfigurationValidate() {
  const configurationSchema = await import("../schemas/configuration.json", {
    assert: { type: "json" },
  });
  const languageSchema = await import("../schemas/language.json", {
    assert: { type: "json" },
  });

  const ajv = new Ajv({
    schemas: [configurationSchema.default, languageSchema.default],
    strict: true,
    strictSchema: true,
    strictTypes: true,
    strictRequired: true,
    validateSchema: true,
    allErrors: true,
  });
  return ajv.compile(configurationSchema);
}

export async function loadConfigurations(
  { root }: { root: string },
): Promise<Configuration[]> {
  console.info("Loading configuration", { fromDirectory: root });
  const validate = await getConfigurationValidate();
  const configurationFilePaths: string[] = await loadConfigurationFilePaths(
    root,
  );
  const configurations: Configuration[] = await loadAndValidateConfigurations(
    configurationFilePaths,
    validate,
  );
  if (validate.errors) {
    throw new Error("Invalid configuration files found");
  }
  return configurations;
}

async function loadAndValidateConfigurations(
  configurationFilePaths: string[],
  validate: ValidateFunction<unknown>,
): Promise<Configuration[]> {
  return await Promise.all(
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
      }
      return {
        // deno-lint-ignore ban-ts-comment
        // @ts-ignore
        ...(configurationFile),
        path: configurationFilePath,
      };
    }),
  );
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
