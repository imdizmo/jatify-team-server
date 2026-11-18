#!/usr/bin/env bash
# Builds the team server for one system: scripts/build.sh <linux-x64|linux-arm64|win-x64> [out dir]
# Leaves <out>/jatify-team-server-<version>-<rid>/ (shelf/, questlog/, services.json, README.md, LICENSE) and its
# archive (.tar.gz, or .zip for Windows). Needs the .NET 10 SDK, Node and pnpm, and the submodules checked out.
set -euo pipefail
rid="${1:?rid: linux-x64, linux-arm64 or win-x64}"; out="${2:-dist}"; mkdir -p "$out"; out="$(cd "$out" && pwd)"
root="$(cd "$(dirname "$0")/.." && pwd)"
v="$(cat "$root/VERSION")"
name="jatify-team-server-$v-$rid"
stage="$out/$name"
rm -rf "${stage:?}"; mkdir -p "$stage"

# the library service (Asset Shelf's ShelfServer), self-contained
shelf="$root/services/asset-shelf/server/ShelfServer"
dotnet publish "$shelf" -c Release -r "$rid" --self-contained -p:PublishSingleFile=true -p:PublishTrimmed=true -p:DebugType=none -o "$stage/shelf/bin" -v q -nologo
cp "$root/services/asset-shelf/server/README.md" "$root/services/asset-shelf/server/CHANGELOG.md" "$stage/shelf/"
shelf_v="$(sed -n 's:.*<Version>\(.*\)</Version>.*:\1:p' "$shelf/ShelfServer.csproj")"

# Questlog's server, with its own Node
questlog_v="$(node -p "require('$root/services/questlog/package.json').version")"
if [[ "${SKIP_QUESTLOG:-}" != 1 ]]; then
    tmp="$out/.questlog-$rid"; rm -rf "${tmp:?}"; mkdir -p "$tmp"
    (cd "$root/services/questlog" && pnpm install --frozen-lockfile && pnpm build && scripts/package-server.sh --dir --version-from-package "$tmp" "$rid")
    mv "$tmp/questlog-server-$rid" "$stage/questlog"; rm -rf "${tmp:?}"
fi

exe=""; [[ "$rid" == win-* ]] && exe=".exe"
"$root/scripts/services.sh" "$v" "$shelf_v" "$questlog_v" "$exe" > "$stage/services.json"
cp "$root/README.md" "$root/LICENSE" "$root/CHANGELOG.md" "$stage/"

cd "$out"
if [[ "$rid" == win-* ]]; then
    rm -f "$name.zip"; zip -qr "$name.zip" "$name"; echo "$out/$name.zip"
else
    tar -czf "$name.tar.gz" "$name"; echo "$out/$name.tar.gz"
fi
