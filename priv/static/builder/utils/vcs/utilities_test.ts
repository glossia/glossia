import { join } from "https://deno.land/std@0.196.0/path/posix.ts";
import { runInTemporaryDirectory } from "../../tests/test-helpers.ts";
import {
  getContextFromFilePath,
  getContextSHA256,
  getFileFormat,
  getFileSHA256,
} from "./utilities.ts";
import { assertEquals } from "https://deno.land/std@0.196.0/assert/assert_equals.ts";
import { assertNotEquals } from "https://deno.land/std@0.196.0/assert/assert_not_equals.ts";

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

Deno.test("getContextFromFilePath extracts all the placeholders", () => {
  // Given
  const path = "priv/{language}/foo/{country}/strings.json";

  // When
  const got = getContextFromFilePath(
    "priv/en/foo/US/strings.json",
    path,
  );

  // Then
  assertEquals(got["language"], "en");
  assertEquals(got["country"], "US");
});

Deno.test("getFileSHA256 returns the same value when the content hasn't changed", async () => {
  await runInTemporaryDirectory(async (temporaryDirectory) => {
    // Given
    const filePath = join(temporaryDirectory, "foo.txt");
    await Deno.writeTextFile(filePath, "bar");

    // When
    const lhsHash = await getFileSHA256(filePath);
    const rhsHash = await getFileSHA256(filePath);

    // Then
    assertEquals(lhsHash, rhsHash);
  });
});

Deno.test("getFileSHA256 returns a different value when the content changes", async () => {
  await runInTemporaryDirectory(async (temporaryDirectory) => {
    // Given
    const filePath = join(temporaryDirectory, "foo.txt");
    await Deno.writeTextFile(filePath, "bar");

    // When
    const lhsHash = await getFileSHA256(filePath);
    await Deno.writeTextFile(filePath, "foo");
    const rhsHash = await getFileSHA256(filePath);

    // Then
    assertNotEquals(lhsHash, rhsHash);
  });
});

Deno.test("getContextSHA256 returns the same value regardles off the order of the context keys", async () => {
  // When
  const lhsHash = await getContextSHA256({
    language: "es",
    country: "MX",
  });
  const rhsHash = await getContextSHA256({
    country: "MX",
    language: "es",
  });

  // Then
  assertEquals(lhsHash, rhsHash);
});

Deno.test("getContextSHA256 returns the same value when the contexsts are the same", async () => {
  // When
  const lhsHash = await getContextSHA256({
    language: "es",
    country: "MX",
  });
  const rhsHash = await getContextSHA256({
    language: "es",
    country: "MX",
  });

  // Then
  assertEquals(lhsHash, rhsHash);
});

Deno.test("getContextSHA256 returns the same value when the contexsts are the not the same", async () => {
  // When
  const lhsHash = await getContextSHA256({
    language: "es",
    country: "MX",
  });
  const rhsHash = await getContextSHA256({
    language: "en",
    country: "US",
  });

  // Then
  assertNotEquals(lhsHash, rhsHash);
});
