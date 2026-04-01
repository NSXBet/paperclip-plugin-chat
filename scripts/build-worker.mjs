import esbuild from "esbuild";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const packageRoot = path.resolve(__dirname, "..");

// Bundle the worker with all dependencies inlined (SDK, zod, shared, etc.)
// This matches the SDK's createPluginBundlerPresets() defaults:
// - format: esm, platform: node, bundle: true
// - Only react/react-dom are external (not used by worker)
await esbuild.build({
  entryPoints: [path.join(packageRoot, "src/worker.ts")],
  outfile: path.join(packageRoot, "dist/worker.js"),
  bundle: true,
  format: "esm",
  platform: "node",
  target: ["node20"],
  sourcemap: true,
  external: ["react", "react-dom"],
  logLevel: "info",
});
