import { join } from "https://deno.land/std@0.196.0/path/posix.ts";
import { runInTemporaryDirectory } from "../../tests/test-helpers.ts";
import { loadAndValidateConfigurationManifest } from "./configuration_manifest.ts";
import { assertEquals } from "https://deno.land/std@0.196.0/assert/assert_equals.ts";
import { isFailure, isSuccess } from "../result.ts";
import { fail } from "https://deno.land/std@0.196.0/assert/mod.ts";

Deno.test("loadAndValidateConfigurationManifest loads the file successfully when the schema is valid", async () => {
  await runInTemporaryDirectory(async (tmpDir) => {
    // Given
    const configurationManifestPath = join(tmpDir, "glossia.jsonc");
    const configurationManifest = {
      source: { language: "es" },
      target: [{ language: "en" }, { language: "es" }],
      files: "posts/*/{language}.md",
    };
    await Deno.writeTextFile(
      configurationManifestPath,
      JSON.stringify(configurationManifest),
    );

    // When
    const got = await loadAndValidateConfigurationManifest(
      configurationManifestPath,
    );

    // Then
    if (isSuccess(got)) {
      assertEquals(
        got.success.source,
        configurationManifest.source,
      );
      assertEquals(
        got.success.target,
        configurationManifest.target,
      );
      assertEquals(got.success.files, configurationManifest.files);
    } else {
      fail(
        "Expected loadAndValidateConfigurationManifest to succeed",
      );
    }
  });
});

Deno.test("loadAndValidateConfigurationManifest returns a failure when the file doesn't exist", async () => {
  await runInTemporaryDirectory(async (tmpDir) => {
    // Given
    const configurationManifestPath = join(tmpDir, "glossia.jsonc");

    // When
    const result = await loadAndValidateConfigurationManifest(
      configurationManifestPath,
    );

    // Then
    if (isFailure(result)) {
      assertEquals(result.failure.type, "missing_file");
    } else {
      fail(
        "Expected loadAndValidateConfigurationManifest to fail",
      );
    }
  });
});

Deno.test("loadAndValidateConfigurationManifest returns a failure when the configuration file does not comply with the JSON spec ", async () => {
  await runInTemporaryDirectory(async (tmpDir) => {
    // Given
    const configurationManifestPath = join(tmpDir, "glossia.jsonc");
    await Deno.writeTextFile(
      configurationManifestPath,
      "invalid-json",
    );

    // When
    const result = await loadAndValidateConfigurationManifest(
      configurationManifestPath,
    );

    // Then
    if (isFailure(result)) {
      assertEquals(result.failure.type, "invalid_json");
    } else {
      fail(
        "Expected loadAndValidateConfigurationManifest to fail",
      );
    }
  });
});

Deno.test("loadAndValidateConfigurationManifest returns a failure when the configuration file does not comply with the configuration schema", async () => {
  await runInTemporaryDirectory(async (tmpDir) => {
    // Given
    const configurationManifestPath = join(tmpDir, "glossia.jsonc");
    const configurationManifest = {
      invalid: "posts/*/{language}.md",
    };
    await Deno.writeTextFile(
      configurationManifestPath,
      JSON.stringify(configurationManifest),
    );

    // When
    const result = await loadAndValidateConfigurationManifest(
      configurationManifestPath,
    );

    // Then
    if (isFailure(result)) {
      assertEquals(result.failure.type, "invalid_schema");
      const errors = (result.failure as { errors: string[] }).errors;
      assertEquals(errors.length, 3);
    } else {
      fail(
        "Expected loadAndValidateConfigurationManifest to fail",
      );
    }
  });
});
