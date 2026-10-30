import { execFileSync } from "node:child_process";
import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import assert from "node:assert/strict";

const sdk = process.env.ANDROID_HOME ?? path.join(os.homedir(), "Library/Android/sdk");
const adb = path.join(sdk, "platform-tools/adb");
const serial = process.env.ANDROID_SERIAL ?? "emulator-5554";
if (!serial.startsWith("emulator-")) throw new Error("Use a dedicated emulator; this test reinstalls the app.");
const pkg = "dev.youngblog.reader";
const run = (...args) => execFileSync(adb, ["-s", serial, ...args], { encoding: "utf8", maxBuffer: 8 * 1024 * 1024 });
const airplane = run("shell", "settings", "get", "global", "airplane_mode_on").trim();
const wifi = run("shell", "settings", "get", "global", "wifi_on").trim();
const data = run("shell", "settings", "get", "global", "mobile_data").trim();
try {
  run("uninstall", pkg);
  run("install", "artifacts/young-blog.apk");
  run("shell", "cmd", "connectivity", "airplane-mode", "enable");
  run("shell", "svc", "wifi", "disable");
  run("shell", "svc", "data", "disable");
  const launch = run("shell", "am", "start", "-W", "-a", "android.intent.action.VIEW", "-d",
    "https://young-blog.pages.dev/tech/zh-hans/ocaml-learning/jane-street-video-notes/jane-street-why-ocaml", pkg);
  let xml = "";
  for (let attempt = 0; attempt < 10; attempt++) {
    run("shell", "uiautomator", "dump", "/sdcard/young-blog-release.xml");
    xml = run("shell", "cat", "/sdcard/young-blog-release.xml");
    if (xml.includes("从一段布尔表达式代码理解")) break;
  }
  assert.ok(xml.includes("从一段布尔表达式代码理解"), "Packaged article must open on first launch without network access");
  assert.ok(xml.includes("分享文章"), "The release reader must show localized article controls");
  const sockets = run("shell", "cat", "/proc/net/unix");
  const pid = run("shell", "pidof", pkg).trim();
  assert.ok(!sockets.includes(`webview_devtools_remote_${pid}`), "Release WebView debugging must be disabled");
  await fs.writeFile("artifacts/android-release-offline.png", execFileSync(adb,
    ["-s", serial, "exec-out", "screencap", "-p"], { maxBuffer: 8 * 1024 * 1024 }));
  await fs.writeFile("artifacts/android-release-smoke.json", JSON.stringify({
    serial, package: pkg, firstLaunchOffline: true, localizedArticle: true, debuggingDisabled: true, launch,
  }, null, 2) + "\n");
  console.log("PASS Signed release APK opens a packaged Chinese article on its first launch in airplane mode");
  console.log("PASS Release WebView debugging is disabled");
} finally {
  run("shell", "cmd", "connectivity", "airplane-mode", airplane === "1" ? "enable" : "disable");
  run("shell", "svc", "wifi", wifi === "1" ? "enable" : "disable");
  run("shell", "svc", "data", data === "1" ? "enable" : "disable");
  run("shell", "rm", "-f", "/sdcard/young-blog-release.xml");
}
