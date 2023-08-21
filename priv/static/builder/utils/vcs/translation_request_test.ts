import { join } from "https://deno.land/std@0.196.0/path/posix.ts";
import { runInTemporaryDirectory } from "../../tests/test-helpers.ts";
import { dirname } from "https://deno.land/std@0.196.0/path/posix.ts";
import { generateModulesPayload } from "./file_tree.ts";
import { assertSnapshot } from "https://deno.land/std@0.196.0/testing/snapshot.ts";
import { generateTranslationRequestPayload } from "./translation_request.ts";
import { getMockedEnv } from "../environment_test_helpers.ts";

Deno.test("generateTranslationRequestPayload with Glossia's configuration", async (t) => {
  await runInTemporaryDirectory(async (temporaryDirectory) => {
    /**
     * priv/
     *  gettext/
     *   {language}/
     *     LC_MESSAGES/
     *       *.po
     */

    // Given
    const enPOPath = join(
      temporaryDirectory,
      "priv/gettext/en/LC_MESSAGES/default.po",
    );
    const esPOPath = join(
      temporaryDirectory,
      "priv/gettext/es/LC_MESSAGES/default.po",
    );

    await Deno.mkdir(dirname(enPOPath), { recursive: true });
    await Deno.mkdir(dirname(esPOPath), { recursive: true });

    await Deno.writeTextFile(enPOPath, "");
    await Deno.writeTextFile(esPOPath, "");

    // When
    const payload = await generateTranslationRequestPayload([{
      path: join(temporaryDirectory, "priv/glossia.jsonc"),
      context: {
        source: { language: "en" },
        target: [{ language: "es" }],
      },
      files: "gettext/{language}/LC_MESSAGES/*.po",
    }], {
      rootDirectory: join(temporaryDirectory),
      env: getMockedEnv({ "GLOSSIA_GIT_COMMIT_SHA": "test-sha" }),
    });

    // Then
    assertSnapshot(t, payload);
  });
});
