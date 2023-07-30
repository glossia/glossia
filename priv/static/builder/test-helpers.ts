/**
 * It runs the callback in a temporary directory and removes it after the callback is executed.
 * @param callback { (temporaryDirectory: string) => Promise<T>} Callback to execute.
 * @returns {Promise<T>} The result of the callback.
 */
export async function inTemporaryDirectory<T>(
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
