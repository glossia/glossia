import { dirname, join } from "https://deno.land/std@0.196.0/path/posix.ts";
import { generateTranslationPayload } from "./vcs.ts";
import {
  getRootDirectory,
  runInTemporaryDirectory,
} from "../tests/test-helpers.ts";
import { assertRejects } from "https://deno.land/std@0.196.0/assert/assert_rejects.ts";
import { assertEquals } from "https://deno.land/std@0.196.0/assert/assert_equals.ts";

Deno.test("generates the translation payload", async () => {
  // Given
  const rootDirectory = getRootDirectory();

  // When/Then
  await generateTranslationPayload({ root: rootDirectory });
});

Deno.test("resolves the files paths", async () => {
  await runInTemporaryDirectory(async (temporaryDirectory) => {
    // Given
    const invalidConfiguration = {
      languages: {
        source: "en",
        target: ["es"],
      },
      files: "posts/**/{language}.md",
    };
    const configurationPath = join(temporaryDirectory, "glossia.jsonc");
    const englishPost = join(temporaryDirectory, "posts/first/en.md");
    const spanishPost = join(temporaryDirectory, "posts/first/es.md");

    await Deno.writeTextFile(
      configurationPath,
      JSON.stringify(invalidConfiguration),
    );
    await Deno.mkdir(dirname(englishPost), { recursive: true });
    await Deno.writeTextFile(englishPost, "Hello world!");
    await Deno.writeTextFile(spanishPost, "Hola mundo!");

    // When
    const payload = await generateTranslationPayload({
      root: temporaryDirectory,
    });

    // Then
    assertEquals(payload[0]["files"].includes("posts/first/en.md"), true);
    assertEquals(payload[0]["files"].includes("posts/first/es.md"), true);
  });
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
    await assertRejects(
      async () => {
        await generateTranslationPayload({ root: temporaryDirectory });
      },
      Error,
      "Invalid configuration files found",
    );
  });
});
