import { join } from "https://deno.land/std@0.196.0/path/posix.ts";
import { loadConfigurations } from "./configuration.ts";
import { getRootDirectory, runInTemporaryDirectory } from "./test-helpers.ts";

Deno.test("returns all the configurations", async () => {
  // Given
  const rootDirectory = getRootDirectory();

  // When/Then
  await loadConfigurations({ root: rootDirectory });
});

Deno.test("throws when there's an invalid configuration", async () => {
  await runInTemporaryDirectory(async (temporaryDirectory) => {
    // Given
    const invalidConfiguration = {
      languages: "invalid",
    };
    const configurationPath = join(temporaryDirectory, "glossia.jsonc");
    await Deno.writeTextFile(
      configurationPath,
      JSON.stringify(invalidConfiguration),
    );

    // When/Then
    await loadConfigurations({ root: temporaryDirectory });
  });
});
