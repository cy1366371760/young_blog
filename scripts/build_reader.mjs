import { build } from "esbuild";

await build({
  entryPoints: ["web/reader.js"],
  outfile: "public/reader.js",
  bundle: true,
  format: "esm",
  target: ["chrome109"],
  minify: true,
  legalComments: "eof",
});
