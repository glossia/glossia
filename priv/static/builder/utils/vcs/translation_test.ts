import { join } from "https://deno.land/std@0.196.0/path/posix.ts";
import { runInTemporaryDirectory } from "../../tests/test-helpers.ts";
import { resolveTree } from "./translation.ts";
import { dirname } from "https://deno.land/std@0.196.0/path/posix.ts";

Deno.test("resolveTree with Glossia's configuration", async () => {
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

    const relativePath = "priv/gettext/{language}/LC_MESSAGES/*.po";
    const basePath = temporaryDirectory;
    const inputTree = {};
    const contextAttributes: string[] = ["language"];

    // When
    const tree = await resolveTree({
      relativePath,
      basePath,
      tree: inputTree,
      contextAttributes,
    });

    console.log(JSON.stringify(tree, null, 2));
  });
});
