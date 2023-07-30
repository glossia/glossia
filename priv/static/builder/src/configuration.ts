import Ajv from "https://esm.sh/ajv@8.6.1";
import { expandGlob } from "https://deno.land/std@0.196.0/fs/mod.ts";
import { parse } from "https://deno.land/std@0.195.0/jsonc/mod.ts";

import configurationV1JSONSchema from "../../schemas/configuration/v1.json" assert {
  type: "json",
};

type Configuration = {
  path: string;
  languages: {
    source: string;
    target: string[];
  };
  files: string[];
};

export async function loadConfigurations(
  { root }: { root: string },
): Promise<Configuration[]> {
  const configurationFilePaths: string[] = [];
  for await (
    const configurationFilePath of expandGlob("**/glossia.jsonc", {
      root: root,
    })
  ) {
    configurationFilePaths.push(configurationFilePath.path);
  }
  const ajv = new Ajv({
    strict: false,
    strictTuples: false,
    strictSchema: false,
    loadSchema: async (uri) => {
      const res = await fetch(uri);
      if (res.status >= 400) {
        throw new Error("Loading error: " + res.statusText);
      }
      return res.json();
    },
  });
  const validate = ajv.compile(configurationV1JSONSchema);

  const configurations: Configuration[] = await Promise.all(
    configurationFilePaths.map(async (configurationFilePath) => {
      console.log(`Reading configuration ${configurationFilePath}`);
      const configurationFile = parse(
        await Deno.readTextFile(configurationFilePath),
      );
      console.log(`Validating configuration file ${configurationFilePath}`);
      if (!validate(configurationFile)) {
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

  if (validate.errors) {
    throw new Error("Invalid configuration");
  }

  return configurations;
}
