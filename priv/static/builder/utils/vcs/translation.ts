import { exists } from "https://deno.land/std@0.196.0/fs/mod.ts";
import { isFailure, Result } from "../result.ts";
import { ConfigurationManifest } from "./configuration_manifest.ts";
import { join, relative } from "https://deno.land/std@0.196.0/path/posix.ts";
import { HandledError } from "../errors.ts";

type TranslationPayloadModuleContext = {
  language: string;
};

type TranslationPayloadModule = {
  source: {
    path: string;
    context: TranslationPayloadModuleContext;
  };
  target: {
    path: string;
    context: TranslationPayloadModuleContext;
  }[];
};

type TranslationPayload = {
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
  const results = await Promise.all(
    configurationManifests.map(async (configurationManifest) => {
      return await generateTranslationPayloadModule(
        configurationManifest,
        options,
      );
    }),
  );
  const missingFiles: string[] = [];
  const modules: TranslationPayloadModule[] = [];
  for (const result of results) {
    if (isFailure(result)) {
      missingFiles.push(...result.failure.files);
    } else {
      modules.push(result.success);
    }
  }

  if (missingFiles.length > 0) {
    throw new HandledError(
      `The following files referenced by the configuration files are missing:
${missingFiles.map((file) => `  - ${file}`).join("\n")}`,
    );
  }

  return { modules };
}

async function generateTranslationPayloadModule(
  configurationManifest: ConfigurationManifest,
  options: GenerateTranslationPayloadOptions,
): Promise<
  Result<TranslationPayloadModule, { type: "missing_files"; files: string[] }>
> {
  const missingFiles: string[] = [];

  // Source file
  let sourceFile: {
    path: string;
    context: TranslationPayloadModuleContext;
  } | undefined;
  const sourceFileResult = await resolveFilePathWithContext(
    join(configurationManifest.path, configurationManifest.files),
    configurationManifest.context.source,
  );
  if (isFailure(sourceFileResult)) {
    missingFiles.push(
      relative(
        options.root,
        sourceFileResult.failure.path,
      ),
    );
  } else {
    sourceFile = {
      path: sourceFileResult.success,
      context: configurationManifest.context.source,
    };
  }

  // Target files
  const targetFiles: {
    path: string;
    context: TranslationPayloadModuleContext;
  }[] = [];

  for (const target of configurationManifest.context.target) {
    const targetFileResult = await resolveFilePathWithContext(
      join(configurationManifest.path, configurationManifest.files),
      target,
    );
    if (isFailure(targetFileResult)) {
      missingFiles.push(
        relative(
          options.root,
          targetFileResult.failure.path,
        ),
      );
    } else {
      targetFiles.push({
        path: targetFileResult.success,
        context: target,
      });
    }
  }

  if (missingFiles.length > 0) {
    return { failure: { type: "missing_files", files: missingFiles } };
  } else {
    return {
      success: {
        source: sourceFile as {
          path: string;
          context: TranslationPayloadModuleContext;
        },
        target: targetFiles,
      },
    };
  }
}

/**
 * Given a path with context variables to be resolved, for example `priv/static/{language}/foo.txt`
 * it traverses the context properties and resolves them in the path.
 * @param path {string} A path with context variables to be resolved.
 * @param context {Record<string, string>} A context object.
 * @returns {string} A resolved path.
 */
async function resolveFilePathWithContext(
  path: string,
  context: Record<string, string>,
): Promise<Result<string, { type: "not_found"; path: string }>> {
  let outputPath: string = path;
  for (const prop in context) {
    // deno-lint-ignore no-prototype-builtins
    if (context.hasOwnProperty(prop)) {
      outputPath = outputPath.replace(`{${prop}}`, context[prop]);
    }
  }
  if (!(await exists(outputPath))) {
    return { failure: { type: "not_found", path: path } };
  }
  return { success: outputPath };
}
