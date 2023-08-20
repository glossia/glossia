import { relative } from "https://deno.land/std@0.196.0/path/mod.ts";

/**
 * It returns the relative path to the working directory.
 * @param path {string} The absolute path to a file or directory.
 * @returns {string} The relative path to the working directory.
 */
export function relativeToWorkingDirectory(path: string): string {
  return relative(Deno.cwd(), path);
}
