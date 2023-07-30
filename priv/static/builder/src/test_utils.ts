export async function inTemporaryDirectory<T>(
  callback: () => Promise<T>,
): Promise<T> {
  const tempDirPath = await Deno.makeTempDir();
  let result: T;
  try {
    result = await callback();
  } catch (error) {
    await Deno.remove(tempDirPath, { recursive: true });
    throw error;
  }
  await Deno.remove(tempDirPath, { recursive: true });
  return result;
}
