import { fileExtension } from "https://deno.land/x/file_extension/mod.ts";

/**
 * The file format of a file.
 */
export type FileFormat =
  | "markdown"
  | "yaml"
  | "json"
  | "toml"
  | "portable-object";

/**
 * Returns the file format of the given file.
 * @param path {string} The absolute path to the file.
 * @returns {FileFormat | undefined}
 */
export function getFileFormat(
  path: string,
): FileFormat | undefined {
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
export function extractPlaceholderValuesFromFilePath(
  path: string,
  pattern: string,
): Record<string, string> {
  const placeholderNames: string[] = [];

  // Convert pattern into a regex pattern, capturing placeholders.
  const regexPattern = pattern.replace(/\{(\w+)\}/g, (_match, p1) => {
    placeholderNames.push(p1);
    return "([a-zA-Z0-9_-]+)"; // Match alphanumeric, underscores, and dashes.
  });

  const regex = new RegExp(regexPattern);
  const matches = path.match(regex);

  if (matches) {
    const result: Record<string, string> = {};
    for (let i = 0; i < placeholderNames.length; i++) {
      result[placeholderNames[i]] = matches[i + 1];
    }
    return result;
  }

  return {};
}
