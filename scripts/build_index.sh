#!/usr/bin/env bash
# Build a static Blender extension repository (index.json + index.html) from
# the latest GitHub release of each repo in repos.txt.
#
#   scripts/build_index.sh <blender> <output-dir>
#
# The zips themselves stay on the release pages (GitHub Pages rejects files
# over 100 MB), so archive_url points at each release asset. Needs `gh`
# (GH_TOKEN in Actions).
set -euo pipefail

BLENDER=$1
OUT=$2
SITE_URL=${SITE_URL:-https://matthewturk.github.io/avl-blender-extensions}
ROOT=$(cd "$(dirname "$0")/.." && pwd)

ZIPS=$(mktemp -d)
trap 'rm -rf "$ZIPS"' EXIT
URLS="$ZIPS/urls.tsv"
: > "$URLS"

grep -v '^\s*\(#\|$\)' "$ROOT/repos.txt" | while read -r repo; do
    if ! tag=$(gh release view -R "$repo" --json tagName -q .tagName 2>/dev/null); then
        echo "skip $repo: no release"
        continue
    fi
    for name in $(gh release view "$tag" -R "$repo" --json assets -q '.assets[].name | select(endswith(".zip"))'); do
        echo "$repo $tag: $name"
        gh release download "$tag" -R "$repo" -p "$name" -D "$ZIPS/zips"
        printf '%s\t%s\n' "$name" "https://github.com/$repo/releases/download/$tag/$name" >> "$URLS"
    done
done

"$BLENDER" --factory-startup --command extension server-generate --repo-dir="$ZIPS/zips" --html

mkdir -p "$OUT"
python3 - "$ZIPS/zips" "$URLS" "$OUT" "$SITE_URL" <<'PY'
import json, sys, urllib.parse
from pathlib import Path

zips, urls, out, site = Path(sys.argv[1]), sys.argv[2], Path(sys.argv[3]), sys.argv[4]
url_of = dict(line.rstrip("\n").split("\t") for line in open(urls))

index = json.loads((zips / "index.json").read_text())
for pkg in index["data"]:
    pkg["archive_url"] = url_of[pkg["archive_url"].removeprefix("./")]
(out / "index.json").write_text(json.dumps(index, indent=2) + "\n")

# The HTML's links carry ?repository=./index.json so dragging one into
# Blender offers to add this repository; make both parts absolute.
html = (zips / "index.html").read_text()
html = html.replace("repository=.%2Findex.json", "repository=" + urllib.parse.quote(site + "/index.json", safe=""))
for name, url in url_of.items():
    html = html.replace(f'href="./{name}', f'href="{url}')
(out / "index.html").write_text(html)
print(f"{len(index['data'])} package(s) -> {out}")
PY
