import { defineConfig } from 'vite'
import { resolve } from 'path'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig(({ command }: any) => {
  const isDev = command !== "build";
  if (isDev) {
    // Terminate the watcher when Phoenix quits
    process.stdin.on("close", () => {
      process.exit(0);
    });

    process.stdin.resume();
  }
  
  return {
    publicDir: "static",
    plugins: [react()],
    build: {
      target: "esnext", // build for recent browsers
      outDir: resolve(__dirname, "../priv/static"), // emit assets to priv/static
      emptyOutDir: true,
      sourcemap: isDev, // enable source map in dev build
      manifest: false, // do not generate manifest.json
      lib: {
        entry: resolve(__dirname, 'frontend/main.tsx'),
        name: 'Glossia',
        fileName: 'glossia',
      },
      rollupOptions: {
        input: {
          main: resolve(__dirname, "./frontend/main.tsx")
        },
        output: {
          entryFileNames: "assets/[name].js", // remove hash
          chunkFileNames: "assets/[name].js",
          assetFileNames: "assets/[name][extname]"
        }
      }
    }
  }
})