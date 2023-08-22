import { dirname, join } from "https://deno.land/std@0.196.0/path/mod.ts";
import { runInTemporaryDirectory } from "../../tests/test-helpers.ts";
import {
  loadConfigurationFilePaths,
  loadConfigurationManifests,
} from "./configuration_loader.ts";
import { assertEquals } from "https://deno.land/std@0.196.0/assert/assert_equals.ts";
import { ConfigurationManifest } from "./configuration_manifest.ts";
import { assertRejects } from "https://deno.land/std@0.196.0/assert/assert_rejects.ts";
import { HandledError } from "../errors.ts";

Deno.test("loadConfigurationFilePaths loads all the paths", async () => {
  await runInTemporaryDirectory(async (tmpDir) => {
    // Given
    const rootConfigFilePath = join(tmpDir, "glossia.jsonc");
    const nestedConfigFilePath = join(tmpDir, "subdir/glossia.jsonc");

    await Deno.mkdir(dirname(rootConfigFilePath), { recursive: true });
    await Deno.mkdir(dirname(nestedConfigFilePath), { recursive: true });
    await Deno.writeTextFile(rootConfigFilePath, "{}");
    await Deno.writeTextFile(nestedConfigFilePath, "{}");

    // When
    const got = await loadConfigurationFilePaths({ root: tmpDir });

    // Then
    assertEquals(got.sort(), [rootConfigFilePath, nestedConfigFilePath].sort());
  });
});

Deno.test("loadConfigurationManifests loads all the manifests when they are valid", async () => {
  await runInTemporaryDirectory(async (tmpDir) => {
    // Given
    const rootConfigFilePath = join(tmpDir, "glossia.jsonc");
    const nestedConfigFilePath = join(tmpDir, "subdir/glossia.jsonc");

    const rootConfigurationFile: Omit<ConfigurationManifest, "path"> = {
      context: {
        source: { language: "es", description: "This is a test content" },
        target: [{
          language: "de",
        }],
      },
      files: "*/{language}.md",
    };
    const nestedConfigurationFile: Omit<ConfigurationManifest, "path"> = {
      context: {
        source: {
          language: "es",
          description: "This is a test content",
        },
        target: [{
          language: "de",
        }],
      },
      files: "*/{language}.md",
    };
    await Deno.mkdir(dirname(rootConfigFilePath), { recursive: true });
    await Deno.mkdir(dirname(nestedConfigFilePath), { recursive: true });

    await Deno.writeTextFile(
      rootConfigFilePath,
      JSON.stringify(rootConfigurationFile),
    );
    await Deno.writeTextFile(
      nestedConfigFilePath,
      JSON.stringify(nestedConfigurationFile),
    );

    // When
    const got = await loadConfigurationManifests({ root: tmpDir });

    // Then
    assertEquals(got.length, 2);
    const first = got.sort()[0];
    const second = got.sort()[1];

    assertEquals(first.path, rootConfigFilePath);
    assertEquals(first.files, rootConfigurationFile.files);
    assertEquals(first.context, rootConfigurationFile.context);
    assertEquals(second.path, nestedConfigFilePath);
    assertEquals(second.files, nestedConfigurationFile.files);
    assertEquals(second.context, nestedConfigurationFile.context);
  });
});

Deno.test("loadConfigurationManifests throws if a configuration file is an invalid JSON", async () => {
  await runInTemporaryDirectory(async (tmpDir) => {
    // Given
    const rootConfigFilePath = join(tmpDir, "glossia.jsonc");
    const nestedConfigFilePath = join(tmpDir, "subdir/glossia.jsonc");

    const rootConfigurationFile: Omit<ConfigurationManifest, "path"> = {
      context: {
        source: { language: "es", description: "This is a test content" },
        target: [{ language: "de" }],
      },
      files: "*/{language}.md",
    };
    await Deno.mkdir(dirname(rootConfigFilePath), { recursive: true });
    await Deno.mkdir(dirname(nestedConfigFilePath), { recursive: true });

    await Deno.writeTextFile(
      rootConfigFilePath,
      JSON.stringify(rootConfigurationFile),
    );
    await Deno.writeTextFile(
      nestedConfigFilePath,
      "invalid",
    );

    // When
    await assertRejects(
      async () => {
        await loadConfigurationManifests({ root: tmpDir });
      },
      HandledError,
    );
  });
});

Deno.test("loadConfigurationManifests throws if a configuration file doesn't follow the schema", async () => {
  await runInTemporaryDirectory(async (tmpDir) => {
    // Given
    const rootConfigFilePath = join(tmpDir, "glossia.jsonc");

    const rootConfigurationFile: Omit<ConfigurationManifest, "path" | "files"> =
      {
        context: {
          source: { language: "es", description: "This is a test content" },
          target: [{ language: "de" }],
        },
        // Missing
        // files: "*/{language}.md",
      };
    await Deno.mkdir(dirname(rootConfigFilePath), { recursive: true });

    await Deno.writeTextFile(
      rootConfigFilePath,
      JSON.stringify(rootConfigurationFile),
    );

    // When
    await assertRejects(
      async () => {
        await loadConfigurationManifests({ root: tmpDir });
      },
      HandledError,
    );
  });
});
