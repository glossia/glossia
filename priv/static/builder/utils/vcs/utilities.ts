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
