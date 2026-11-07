#!/usr/bin/env python3
"""Create a persistent local signing identity without putting secrets in the repository."""
import os
from pathlib import Path
import secrets
import subprocess

root = Path.home() / ".local/share/young-blog"
root.mkdir(parents=True, exist_ok=True, mode=0o700)
properties = Path(os.environ.get("READER_SIGNING_PROPERTIES", root / "signing.properties"))
if properties.exists():
    print("Using the existing local Android signing identity.")
    raise SystemExit(0)
keystore = root / "reader-release.p12"
if keystore.exists():
    raise SystemExit("Signing properties are missing; restore them before generating another identity.")
password = secrets.token_hex(32)
keytool = Path(os.environ["JAVA_HOME"]) / "bin/keytool"
environment = dict(os.environ, YOUNG_BLOG_STORE_PASSWORD=password)
subprocess.run([
    str(keytool), "-genkeypair", "-noprompt", "-storetype", "PKCS12",
    "-keystore", str(keystore), "-alias", "young-blog", "-keyalg", "RSA", "-keysize", "3072",
    "-validity", "10000", "-dname", "CN=Young Blog",
    "-storepass:env", "YOUNG_BLOG_STORE_PASSWORD", "-keypass:env", "YOUNG_BLOG_STORE_PASSWORD",
], env=environment, check=True)
keystore.chmod(0o600)
properties.parent.mkdir(parents=True, exist_ok=True)
with properties.open("x") as output:
    properties.chmod(0o600)
    output.write(f"storeFile={keystore}\nstorePassword={password}\nkeyAlias=young-blog\nkeyPassword={password}\n")
print("Created a local Android signing identity under ~/.local/share/young-blog.")
