import { join } from "https://deno.land/std@0.196.0/path/posix.ts";
import { runInTemporaryDirectory } from "../../tests/test-helpers.ts";
import { loadAndValidateConfigurationManifest } from "./configuration_manifest.ts";
import { assertEquals } from "https://deno.land/std@0.196.0/assert/assert_equals.ts";
import { assertRejects } from "https://deno.land/std@0.196.0/assert/assert_rejects.ts";

Deno.test("loadAndValidateConfigurationManifest loads the file successfully when the schema is valid", async () => {
  await runInTemporaryDirectory(async (tmpDir) => {
    // Given
    const configurationManifestPath = join(tmpDir, "glossia.jsonc");
    const configurationManifest = {
      languages: {
        source: "es",
        target: ["en", "es"],
      },
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
    assertEquals(got.success?.source, configurationManifest.languages.source);
    assertEquals(got.languages.target, configurationManifest.languages.target);
    assertEquals(got.files, configurationManifest.files);
  });
});

// Deno.test("loadAndValidateConfigurationManifest throws an error when the file doesn't exist", async () => {
//   await runInTemporaryDirectory(async (tmpDir) => {
//     // Given
//     const configurationManifestPath = join(tmpDir, "glossia.jsonc");

//     // When/Then
//     await assertRejects(
//       async () => {
//         await loadAndValidateConfigurationManifest(
//           configurationManifestPath,
//         );
//       },
//       Error,
//       `The configuration manifest not found at path ${configurationManifestPath}`,
//     );
//   });
// });

// Deno.test("loadAndValidateConfigurationManifest throws an error when the configuration file does not comply with the JSON spec ", async () => {
//   await runInTemporaryDirectory(async (tmpDir) => {
//     // Given
//     const configurationManifestPath = join(tmpDir, "glossia.jsonc");
//     await Deno.writeTextFile(
//       configurationManifestPath,
//       "invalid-json",
//     );

//     // When/Then
//     await assertRejects(
//       async () => {
//         await loadAndValidateConfigurationManifest(
//           configurationManifestPath,
//         );
//       },
//       Error,
//       `The configuration manifest at path ${configurationManifestPath} is not a valid JSON`,
//     );
//   });
// });

// Deno.test("loadAndValidateConfigurationManifest throws an error when the configuration file does not comply with the configuration schema", async () => {
//   await runInTemporaryDirectory(async (tmpDir) => {
//     // Given
//     const configurationManifestPath = join(tmpDir, "glossia.jsonc");
//     const configurationManifest = {
//       invalid: "posts/*/{language}.md",
//     };
//     await Deno.writeTextFile(
//       configurationManifestPath,
//       JSON.stringify(configurationManifest),
//     );

//     // When/Then
//     await assertRejects(
//       async () => {
//         await loadAndValidateConfigurationManifest(
//           configurationManifestPath,
//         );
//       },
//       Error,
//       `The validation of the configuration manifest at path ${configurationManifestPath} failed with the following errors:
//  - must have required property 'languages'
//  - must have required property 'files'`,
//     );
//   });
// });
