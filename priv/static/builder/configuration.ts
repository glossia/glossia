import { z } from "https://deno.land/x/zod@v3.31.4/mod.ts";
import { jsonSchemaToZod } from "npm:json-schema-to-zod@1.1.1";

import configurationV1JSONSchema from "../schemas/configuration/v1.json" assert {
  type: "json",
};

export const configurationSchema = jsonSchemaToZod(
  configurationV1JSONSchema as any,
);

export async function loadConfiguration({ from }: { from: string }) {
}
