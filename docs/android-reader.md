# Android Reader

Young Blog 0.1.0 keeps its OCaml/Bonsai frontend and packages the release web
assets in Capacitor. It supports Android 7.0 (API 24) and later.

## Build

Requirements: Node.js 22 or later, opam 2.2 or later with the repository's switch, JDK 21, Android
SDK platform 36, build tools 36.0.0, and platform tools. Android Studio includes
a suitable JDK. On macOS the build script discovers its bundled JDK and the
standard `~/Library/Android/sdk` directory. Other hosts should set `JAVA_HOME`
and `ANDROID_HOME` explicitly.

```sh
npm ci
opam install . --deps-only --with-test --with-dev-setup
npm run build:android
```

Outputs, excluded from Git:

- `artifacts/young-blog.apk`: signed release APK for direct installation.
- `artifacts/young-blog.aab`: signed release bundle for a distribution service.
- `artifacts/young-blog-debug.apk`: debug APK for development and inspection.
- `artifacts/young-blog.apk.sha256`: release APK checksum.

On first build, a local signing identity is created in
`~/.local/share/young-blog/`. Back up that directory privately: future updates
must use the same signing identity. Do not commit or share its passwords or key.
`READER_SIGNING_PROPERTIES` can select an existing signing-properties file.
The build does not upload or submit an application to a store.

```sh
"$ANDROID_HOME/platform-tools/adb" install -r artifacts/young-blog.apk
```

The package identifier is `dev.youngblog.reader`. Release builds disable WebView
debugging. A debug installation signed with the Android debug key cannot update
an installation signed with the release key; use a separate test device or
uninstall the debug build first, which also removes its local reader data.

## Reading and updates

- All packaged English, Simplified Chinese, and generated Traditional Chinese
  articles are available without a network connection on first launch.
- Search covers titles, summaries, and tags. It combines words and an optional
  exact tag. The saved filter applies within the current content area and locale.
- Favorites follow an article across its translations. Font size, theme, last
  route, and per-language reading positions persist on the device. Android uses
  the native Preferences store for these settings, so they do not depend on
  WebView localStorage being flushed before process termination.
- Use **Refresh library** to download current published content. The reader
  switches catalogs only after all articles have downloaded successfully.
- New servers expose `content-index.json`. Existing deployments with only
  `posts.js` are also supported, with data parsing instead of script execution.
- Remote article HTML is sanitized. No remote application code is downloaded.
- Article sharing opens the Android share sheet. External article links are
  registered with the Android activity. Until domain verification is configured,
  users may need to enable supported-link handling in Android's app settings.

For automatic verified App Links, publish `/.well-known/assetlinks.json` on
`young-blog.pages.dev` with this package name and the SHA-256 certificate
fingerprint for the installed distribution. If a store re-signs the application,
use its app-signing certificate. Enable `android:autoVerify` on the HTTPS intent
filter after adding the association. The app does not claim verified-domain
ownership before this configuration is deployed.

## Verification

```sh
opam exec -- dune build @fmt
opam exec -- dune runtest
scripts/check_content.sh
npm run build:web
npm test
npm run test:browser
```

The browser suite uses installed Chrome locally and Playwright Chromium on CI.
Use `npx playwright install chromium` for the CI browser environment.
The development dependency flag installs the pinned `ocamlformat` version used
by `.ocamlformat` and the CI format check.

For native smoke tests, install the debug APK and start the app on a dedicated
emulator, then run:

```sh
ANDROID_SERIAL=emulator-5554 node tests/android/smoke.mjs
```

The native suite clears this app's data on the dedicated emulator, then exercises
search, translated favorites, system Back, the actual
share sheet, production content refresh, incoming article intents, and an
airplane-mode cold restart. It writes screenshots and a result file under
`artifacts/`. It temporarily changes emulator connectivity and restores its prior
settings. If the host requires an HTTP proxy, set `ANDROID_TEST_PROXY` to the
emulator-reachable proxy address, such as `10.0.2.2:7890`. The CI workflow builds
and lints a debug APK but does not run the
interactive emulator suite or claim physical-device coverage.

To verify the actual signed release on the dedicated emulator, run
`node tests/android/release-smoke.mjs`. This replaces the debug installation and
its data with the release APK, checks a first-launch article in airplane mode,
and verifies that release WebView debugging is disabled.

See [ADR 0004](adr/0004-share-bonsai-reader-with-android.md) for the Jane Street
references, architectural boundaries, and tradeoffs.
