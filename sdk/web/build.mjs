// Build the @glossia/web SDK into a dist/ directory with three formats:
// - ESM (`glossia-web.js`) — used by bundlers and modern `<script type="module">`.
// - CJS (`glossia-web.cjs`) — used by older Node.js tooling.
// - IIFE (`glossia-web.iife.js`) — used by the classic `<script>` snippet,
//   exposed as the `glossia` global so callers can do `glossia("track", "...")`.
import { build } from "esbuild";
import { copyFileSync, rmSync } from "node:fs";

copyFileSync(new URL("../../LICENSE.md", import.meta.url), new URL("./LICENSE.md", import.meta.url));

rmSync("dist", { recursive: true, force: true });

const base = {
  entryPoints: ["src/index.js"],
  bundle: true,
  target: "es2020",
  sourcemap: false,
  legalComments: "none",
  banner: {
    js: "/*! @glossia/web | O'Saasy License | Source: https://github.com/glossia/glossia/tree/main/sdk/web */",
  },
};

await build({ ...base, format: "esm", outfile: "dist/glossia-web.js" });
await build({ ...base, format: "cjs", outfile: "dist/glossia-web.cjs" });
await build({
  ...base,
  format: "iife",
  globalName: "glossia",
  outfile: "dist/glossia-web.iife.js",
});
