import { assertEquals } from "https://deno.land/std@0.196.0/assert/assert_equals.ts";
import { capitalizeFirstLetter } from "./string.ts";

Deno.test("capitalizeFirstLetter returns the value when it's undefined", () => {
  assertEquals(
    capitalizeFirstLetter(undefined as unknown as string),
    undefined,
  );
});

Deno.test("capitalizeFirstLetter returns the value when it's an empty string", () => {
  assertEquals(
    capitalizeFirstLetter(""),
    "",
  );
});

Deno.test("capitalizeFirstLetter returns the value with the first letter capitalized", () => {
  assertEquals(
    capitalizeFirstLetter("test"),
    "Test",
  );
});
