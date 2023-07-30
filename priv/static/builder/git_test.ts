import { clone } from "./git.ts";
import { runInTemporaryDirectory } from "./test-helpers.ts";

Deno.test("clone clones the repository", async () => {
  await runInTemporaryDirectory(async (tmpDir) => {
    // When
    await clone({
      root: tmpDir,
      vcsPlatform: "github",
      vcsId: "glossia/glossia",
      gitCommitSHA: undefined,
      gitAccessToken: undefined,
    });
  });
});
