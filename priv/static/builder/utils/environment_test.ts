import { assertThrows } from "https://deno.land/std@0.196.0/assert/assert_throws.ts";
import { getMockedEnv } from "./environment_test_helpers.ts";
import { getBuildType } from "./environment.ts";

Deno.test("getBuildType throws an error when the event is unsupported", () => {
  assertThrows(() => {
    getBuildType(getMockedEnv({ GLOSSIA_BUILD_TYPE: "invalid" }));
  }, "This instance of the builder doesn't support the event 'invalid'");
});

Deno.test("getContentSourcePlatform throws an error when the VCS platform is unsupported", () => {
  assertThrows(() => {
    getBuildType(getMockedEnv({ GLOSSIA_content_platform: "invalid" }));
  }, "This instance of the builder doesn't support the VCS platform 'invalid'");
});
