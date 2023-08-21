import { join } from "https://deno.land/std@0.196.0/path/posix.ts";
import { runInTemporaryDirectory } from "../../tests/test-helpers.ts";
import {
  extractPlaceholderValuesFromFilePath,
  getFileFormat,
} from "./utilities.ts";
import { assertEquals } from "https://deno.land/std@0.196.0/assert/assert_equals.ts";

Deno.test("getFileFormat when the format is markdown", async () => {
  await runInTemporaryDirectory(async (temporaryDirectory) => {
    // Given
    const path = join(temporaryDirectory, "README.md");

    // When
    const got = await getFileFormat(path);

    // Then
    assertEquals(got, "markdown");
  });
});

Deno.test("getFileFormat when the format is yaml", async () => {
  await runInTemporaryDirectory(async (temporaryDirectory) => {
    // Given
    const yamlPath = join(temporaryDirectory, "strings.yaml");
    const ymlPath = join(temporaryDirectory, "strings.yml");

    // When
    const gotYaml = await getFileFormat(yamlPath);
    const gotYml = await getFileFormat(ymlPath);

    // Then
    assertEquals(gotYaml, "yaml");
    assertEquals(gotYml, "yaml");
  });
});

Deno.test("getFileFormat when the format is json", async () => {
  await runInTemporaryDirectory(async (temporaryDirectory) => {
    // Given
    const path = join(temporaryDirectory, "strings.json");

    // When
    const got = await getFileFormat(path);

    // Then
    assertEquals(got, "json");
  });
});

Deno.test("getFileFormat when the format is toml", async () => {
  await runInTemporaryDirectory(async (temporaryDirectory) => {
    // Given
    const path = join(temporaryDirectory, "strings.toml");

    // When
    const got = await getFileFormat(path);

    // Then
    assertEquals(got, "toml");
  });
});

Deno.test("getFileFormat when the format is po", async () => {
  await runInTemporaryDirectory(async (temporaryDirectory) => {
    // Given
    const path = join(temporaryDirectory, "strings.po");

    // When
    const got = await getFileFormat(path);

    // Then
    assertEquals(got, "portable-object");
  });
});

Deno.test("extractPlaceholdersFromFile extracts all the placeholders", () => {
  // Given
  const path = "priv/{language}/foo/{country}/strings.json";

  // When
  const got = extractPlaceholderValuesFromFilePath(
    "priv/en/foo/US/strings.json",
    path,
  );

  // Then
  assertEquals(got["language"], "en");
  assertEquals(got["country"], "US");
});
