import { expandGlob } from "https://deno.land/std@0.196.0/fs/mod.ts";

async function loadConfigurationFilePaths(root: string) {
  const configurationFilePaths: string[] = [];
  for await (
    const configurationFilePath of expandGlob("**/glossia.jsonc", {
      root: root,
    })
  ) {
    configurationFilePaths.push(configurationFilePath.path);
  }
  return configurationFilePaths;
}
