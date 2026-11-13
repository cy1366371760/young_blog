import http from "node:http";
import fs from "node:fs";
import path from "node:path";

const root = path.resolve("dist");
const types = { ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".css": "text/css; charset=utf-8", ".json": "application/json" };
http.createServer((request, response) => {
  const pathname = decodeURIComponent(new URL(request.url, "http://localhost").pathname);
  let file = path.resolve(root, "." + pathname);
  if (!file.startsWith(root + path.sep) && file !== root) {
    response.writeHead(403).end(); return;
  }
  if (pathname === "/" || /^\/(tech|essays)\//.test(pathname)) file = path.join(root, "index.html");
  if (!fs.existsSync(file) || !fs.statSync(file).isFile()) {
    response.writeHead(404).end("Not found"); return;
  }
  response.writeHead(200, { "Content-Type": types[path.extname(file)] ?? "application/octet-stream", "Cache-Control": "no-store" });
  fs.createReadStream(file).pipe(response);
}).listen(Number(process.env.PORT ?? 8891), "127.0.0.1", () => console.log("Young Blog preview is ready"));
