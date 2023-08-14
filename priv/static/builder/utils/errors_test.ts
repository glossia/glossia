import { assertEquals } from "https://deno.land/std@0.196.0/assert/assert_equals.ts";
import { HandledError, runReportingErrors } from "./errors.ts";
import { assertRejects } from "https://deno.land/std@0.196.0/assert/assert_rejects.ts";

Deno.test("it strips the markdown from the error message", () => {
  // Given/When
  const got = new HandledError("# test");

  // Then
  assertEquals(got.message, "test");
  assertEquals(got.markdownMessage, "# test");
});

Deno.test("runReportingErrors reports the errors thrown by the callback", async () => {
  const errorMessage = "test";
  let gotError: Error | undefined;
  let gotMetadata: any | undefined;

  await assertRejects(
    async () => {
      await runReportingErrors(() => {
        throw new Error(errorMessage);
      }, {
        reportFunction: (err, metadata) => {
          gotError = err;
          gotMetadata = metadata;
          return Promise.resolve(undefined);
        },
      });
    },
    Error,
    errorMessage,
  );

  assertEquals(gotError?.message, errorMessage);
  assertEquals(gotMetadata, {});
});
