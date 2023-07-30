import { loadConfigurations } from "./configuration.ts";
import { getRootDirectory } from "./test-helpers.ts";

Deno.test("returns all the configurations", async () => {
  // Given
  const rootDirectory = getRootDirectory();

  // When
  const got = await loadConfigurations({ root: rootDirectory });
});
