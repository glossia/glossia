import { expandGlob } from "https://deno.land/std@0.196.0/fs/mod.ts";

type ExpandGlobParameters = Parameters<typeof expandGlob>;

/**
 * A function that uses Deno's `expandGlob` to resolve a glob pattern.
 * Unlike Deno's `expandGlob`, it returns the paths as an array.
 * @param pattern {ExpandGlobParameters[0]} The pattern to match.
 * @param options {ExpandGlobParameters[1]} The options to pass to the glob matcher.
 * @returns
 */
export async function resolveGlob(
  pattern: ExpandGlobParameters[0],
  options: ExpandGlobParameters[1] = undefined,
): Promise<string[]> {
  const paths: string[] = [];
  for await (
    const path of expandGlob(pattern, options)
  ) {
    paths.push(path.path);
  }
  return paths;
}

/**
 * Checks if a path is a directory.
 * @param path {string} The path to check.
 * @returns {Promise<boolean>} A promise that resolves to a boolean indicating if the path is a directory.
 */
export async function isDirectory(path: string): Promise<boolean> {
  try {
    const stat = await Deno.stat(path);
    return stat.isDirectory;
  } catch (_error) {
    return false;
  }
}
