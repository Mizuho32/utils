#!/usr/bin/env bash
# ./apparmor.d/* を /etc/apparmor.d/ にインストールしてロードする
set -euo pipefail

src=$(cd "$(dirname "$0")/apparmor.d" && pwd)

for f in "$src"/*; do
  name=$(basename "$f")
  echo "install: $name"
  sudo install -m 644 "$f" "/etc/apparmor.d/$name"
  sudo apparmor_parser -r "/etc/apparmor.d/$name"
done
