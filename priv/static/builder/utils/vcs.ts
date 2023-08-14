import { ValidateFunction } from "https://esm.sh/ajv@~8.12.0";
import { expandGlob } from "https://deno.land/std@0.196.0/fs/mod.ts";
import { parse } from "https://deno.land/std@0.195.0/jsonc/mod.ts";
import { dirname, relative } from "https://deno.land/std@0.196.0/path/posix.ts";

type TranslationModuleLanguages = {
  source: string;
  target: string[];
};

type TranslationModule = {
  languages: TranslationModuleLanguages;
  files: string[];
};

type TranslationPayload = TranslationModule[];

type GenerateTranslationPayloadOptions = { root: string };
