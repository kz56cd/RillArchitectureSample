#!/bin/bash
# Xcode のプロジェクトで、Rill パッケージの trait を選ぶ。
#
# XcodeGen は、パッケージの参照に trait を書き出せない。
# `make generate` のあとに、プロジェクトのファイルの Rill の参照へ `traits` を書き足す。
#
# 使い方: Scripts/apply-rill-traits.sh "NoLocalization"(空なら何もしない)
set -euo pipefail

cd "$(dirname "$0")/.."

traits="${1:-}"
if [ -z "$traits" ]; then
    exit 0
fi

project=RillArchitectureSample.xcodeproj/project.pbxproj
anchor=$'\t\t\trelativePath = .;'

if ! grep -qF "$anchor" "$project"; then
    echo "Rill パッケージの参照が見つからない: $project" >&2
    exit 1
fi
if grep -q $'^\t\t\ttraits = (' "$project"; then
    echo "trait はすでに書かれている: $project" >&2
    exit 1
fi

# カンマ区切りの trait を、プロジェクトのファイルの書き方に並べる。
lines=""
IFS=',' read -ra names <<< "$traits"
for name in "${names[@]}"; do
    lines+=$'\t\t\t\t'"${name}"$',\n'
done

ANCHOR="$anchor" LINES="$lines" perl -0pi -e '
    my $anchor = $ENV{ANCHOR};
    my $lines = $ENV{LINES};
    s/\Q$anchor\E\n/$anchor\n\t\t\ttraits = (\n$lines\t\t\t);\n/;
' "$project"

echo "Rill パッケージの trait を選んだ: $traits"
