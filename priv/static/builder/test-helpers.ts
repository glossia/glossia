import { join as joinPath } from "https://deno.land/std@0.196.0/path/posix.ts";

/**
 * It runs the callback in a temporary directory and removes it after the callback is executed.
 * @param callback { (temporaryDirectory: string) => Promise<T>} Callback to execute.
 * @returns {Promise<T>} The result of the callback.
 */
export async function runInTemporaryDirectory<T>(
  callback: (temporaryDirectory: string) => Promise<T>,
): Promise<T> {
  const tempDirPath = await Deno.makeTempDir();
  let result: T;
  try {
    result = await callback(tempDirPath);
  } catch (error) {
    await Deno.remove(tempDirPath, { recursive: true });
    throw error;
  }
  await Deno.remove(tempDirPath, { recursive: true });
  return result;
}

/**
 * Returns the root directory of the project.
 * @returns {Promise<string>} The root directory of the project.
 */
export async function getRootDirectory() {
  const __dirname = new URL(".", import.meta.url).pathname;
  const rootPath = joinPath(__dirname, "..", "..", "..");
  return rootPath;
}
