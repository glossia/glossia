import { assertThrows } from "https://deno.land/std@0.196.0/assert/assert_throws.ts";
import { getMockedEnv } from "./environment_test_helpers.ts";
import { getEvent } from "./environment.ts";

Deno.test("getEvent throws an error when the event is unsupported", () => {
  assertThrows(() => {
    getEvent(getMockedEnv({ GLOSSIA_EVENT: "invalid" }));
  }, "This instance of the builder doesn't support the event 'invalid'");
});

Deno.test("getContentSourcePlatform throws an error when the VCS platform is unsupported", () => {
  assertThrows(() => {
    getEvent(getMockedEnv({ GLOSSIA_CONTENT_SOURCE_PLATFORM: "invalid" }));
  }, "This instance of the builder doesn't support the VCS platform 'invalid'");
});
