import { fileExtension } from "https://deno.land/x/file_extension@v2.1.0/mod.ts";
import {
  crypto,
  toHashString,
} from "https://deno.land/std@0.196.0/crypto/mod.ts";
import { Context, FileFormat } from "./types.ts";

/**
 * Returns the file format of the given file.
 * @param path {string} The absolute path to the file.
 * @returns {FileFormat | undefined}
 */
export function getFileFormat(path: string): FileFormat | undefined {
  const extension = fileExtension(path);
  switch (extension) {
    case "md":
      return "markdown";
    case "yaml":
      return "yaml";
    case "yml":
      return "yaml";
    case "json":
      return "json";
    case "toml":
      return "toml";
    case "po":
      return "portable-object";
    case "pot":
      return "portable-object-template";
    default:
      return undefined;
  }
}

/**
 * Extracts placeholders from a file path. For example, given the path
 * "priv/{language}/{country}/strings.json" and the path "priv/en/US/strings.json",
 * it returns { language: "en", country: "US" }.
 * @param path {string} The absolute path to the file.
 * @param pattern {string} The pattern to extract placeholders from.
 * @returns {Record<string, string>} The placeholders and their values.
 */
export function getContextFromFilePath(path: string, pattern: string): Context {
  const placeholderNames: string[] = [];

  // Convert pattern into a regex pattern, capturing placeholders.
  const regexPattern = pattern.replace(/\{(\w+)\}/g, (_match, p1) => {
    placeholderNames.push(p1);
    return "([a-zA-Z0-9_-]+)"; // Match alphanumeric, underscores, and dashes.
  });

  const regex = new RegExp(regexPattern);
  const matches = path.match(regex);

  if (matches) {
    // deno-lint-ignore ban-ts-comment
    // @ts-ignore
    const result: Context = {};
    for (let i = 0; i < placeholderNames.length; i++) {
      result[placeholderNames[i] as keyof Context] = matches[i + 1];
    }
    return result;
  }

  // TODO: We should probably throw an error here if required
  // placeholders such as language are missing.
  return {} as Context;
}

/**
 * Calculates the SHA256 hash of the given file.
 * @param filepath {string} The absolute path to the file.
 * @returns {Promise<string>} The SHA256 hash of the file.
 */
export async function getFileSHA256(filepath: string) {
  const content = await Deno.readFile(filepath);
  return toHashString(await crypto.subtle.digest("SHA-256", content));
}

/**
 * Calculates the SHA256 hash of the given context.
 * @param context {Context} The context.
 * @returns {Promise<string>} The SHA256 hash of the context.
 */
export async function getContextSHA256(context: Context) {
  const contextTextEncoder = new TextEncoder();
  const encodedContextText = contextTextEncoder.encode(
    Object.keys(context)
      .sort()
      .map((key) => {
        if (context[key as keyof Context]) {
          return `${key}=${context[key as keyof Context]}`;
        } else {
          return undefined;
        }
      })
      .join(",")
  );
  const contextHash = toHashString(
    await crypto.subtle.digest("SHA-256", encodedContextText)
  );
  return contextHash;
}
