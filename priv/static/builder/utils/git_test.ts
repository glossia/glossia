import { getContentSourceAccessToken } from "./environment.ts";
import { clone } from "./git.ts";
import { runInTemporaryDirectory } from "../tests/test-helpers.ts";

Deno.test("clone clones the repository", async () => {
  await runInTemporaryDirectory(async (tmpDir) => {
    // When
    await clone({
      root: tmpDir,
      contentSourcePlatform: "github",
      idInContentSourcePlatform: "glossia/glossia",
      gitCommitSHA: undefined,
      gitAccessToken: getContentSourceAccessToken(),
    });
  });
});
