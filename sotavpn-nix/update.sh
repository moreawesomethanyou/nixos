#!/usr/bin/env bash
# Re-pin package.nix after Sota publishes a new build.
# Upstream serves only a "latest" artifact, so the hash in package.nix goes
# stale on every release and the build fails with a hash mismatch. Run this.
set -euo pipefail

url="https://storage.sota.ac/api/v1/public/storage/sotavpn-latest-x64.pkg.tar.zst"
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "downloading $url"
curl -fL --progress-bar -o "$tmp/pkg.tar.zst" "$url"

version="$(tar --zstd -xOf "$tmp/pkg.tar.zst" .PKGINFO | sed -n 's/^pkgver = //p')"
hash="sha256-$(sha256sum "$tmp/pkg.tar.zst" | cut -d' ' -f1 \
  | python3 -c 'import sys,base64,binascii;print(base64.b64encode(binascii.unhexlify(sys.stdin.read().strip())).decode())')"

echo "version: $version"
echo "hash:    $hash"

sed -i \
  -e "s|^  version = \".*\";|  version = \"$version\";|" \
  -e "s|    hash = \"sha256-.*\";|    hash = \"$hash\";|" \
  "$here/package.nix"

echo "package.nix updated"
