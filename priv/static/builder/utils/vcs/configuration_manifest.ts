import Ajv from "https://esm.sh/ajv@~8.12.0";
import { parse } from "https://deno.land/std@0.195.0/jsonc/mod.ts";
import { exists } from "https://deno.land/std@0.196.0/fs/exists.ts";
import { Result } from "../result.ts";
import { SourceContext, TargetContext } from "./types.ts";

export type ConfigurationManifest = {
  // The path to the manifest file.
  path: string;

  /** The source and target contexts necessary to localize */
  context: {
    /** The base context of the source language. */
    source: SourceContext;
    /** The target contexts of the target languages. */
    target: TargetContext[];
  };
  /**
   * A wildcard to resolve all the files that should be localized. The wildcard
   * should contain the {language} token to resolve it with all the languages.
   */
  files: string;
};

export type ManifestLoadingError =
  | { type: "missing_file"; filePath: string }
  | {
    type: "invalid_json";
    filePath: string;
  }
  | {
    type: "invalid_schema";
    errors: string[];
    filePath: string;
  };

/**
 * It loads and validates a configuration manifest at a given path.
 * @param configurationManifestPath {string} The absolute path to the glossia.jsonc manifest file to load
 * @returns {Promise<ConfigurationManifest>} A promise that resolves with the configuration if the manifest can be loaded successfully. The promise rejects with an error if either the file doesn't exist, the format is invalid (we expect a documented JSON), or it doesn't comply with the schema.
 */
export async function loadAndValidateConfigurationManifest(
  configurationManifestPath: string,
): Promise<Result<ConfigurationManifest, ManifestLoadingError>> {
  if (!(await exists(configurationManifestPath))) {
    return {
      failure: { type: "missing_file", filePath: configurationManifestPath },
    };
  }
  const validate = await getConfigurationValidate();
  console.info(
    `Reading configuration file at path: ${configurationManifestPath}`,
  );
  // deno-lint-ignore no-explicit-any
  let configurationFile: any;
  try {
    configurationFile = parse(
      await Deno.readTextFile(configurationManifestPath),
    );
  } catch (error) {
    if (error instanceof SyntaxError) {
      return {
        failure: { type: "invalid_json", filePath: configurationManifestPath },
      };
    } else {
      throw error;
    }
  }

  const isValid = validate(configurationFile, {
    instancePath: configurationManifestPath,
    parentData: {},
    parentDataProperty: "",
    rootData: [],
    dynamicAnchors: {},
  });
  if (!isValid) {
    const errors: string[] = [];
    validate.errors?.forEach((validationError) => {
      if (validationError.message) {
        // TODO: Capitalize the first letter of the error message
        errors.push(validationError.message);
      }
    });
    return {
      failure: {
        type: "invalid_schema",
        errors: errors,
        filePath: configurationManifestPath,
      },
    };
  } else {
    return {
      success: {
        ...configurationFile,
        path: configurationManifestPath,
      } as ConfigurationManifest,
    };
  }
}

/**
 * It returns a function that validates the configuration.
 * Documentation: https://ajv.js.org/guide/managing-schemas.html
 *
 * @returns {Promise<(data: any) => boolean>} A function that validates the configuration
 */
async function getConfigurationValidate() {
  const configurationSchema = await import(
    "../../../schemas/configuration.json",
    {
      assert: { type: "json" },
    }
  );
  const languageSchema = await import("../../../schemas/language.json", {
    assert: { type: "json" },
  });
  const sourceContextSchema = await import(
    "../../../schemas/source_context.json",
    {
      assert: { type: "json" },
    }
  );
  const targetContextSchema = await import(
    "../../../schemas/target_context.json",
    {
      assert: { type: "json" },
    }
  );

  const ajv = new Ajv({
    strict: true,
    strictSchema: true,
    strictTypes: true,
    strictRequired: true,
    validateSchema: true,
    strictTuples: false,
    allErrors: true,
  });

  ajv.addSchema(languageSchema.default, languageSchema.default["$id"]);
  ajv.addSchema(
    sourceContextSchema.default,
    sourceContextSchema.default["$id"],
  );
  ajv.addSchema(
    targetContextSchema.default,
    targetContextSchema.default["$id"],
  );

  return ajv.compile(configurationSchema.default);
}
