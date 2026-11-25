#!/bin/bash
# trait `NoLocalization`(多言語化しないアプリ向け)でも、アプリのソースが組めることを確かめる。
#
# trait を有効にした Rill を作り、アプリのソースと一緒に型検査する。
# Xcode のプロジェクトは書き換えない。
set -euo pipefail

cd "$(dirname "$0")/.."

sources=()
while IFS= read -r file; do
    sources+=("$file")
done < <(find RillArchitectureSample -name '*.swift' | sort)

swiftc_simulator() {
    xcrun --sdk iphonesimulator swiftc \
        -target arm64-apple-ios26.0-simulator \
        -swift-version 6 \
        -default-isolation MainActor \
        -parse-as-library \
        "$@"
}

modules=$(mktemp -d)
trap 'rm -rf "$modules"' EXIT

echo "1. trait NoLocalization を有効にした Rill を作る"
swiftc_simulator -emit-module \
    -module-name Rill \
    -D NoLocalization \
    -emit-module-path "$modules/Rill.swiftmodule" \
    Packages/Rill/Sources/Rill/*/*.swift

echo "2. DisplayText が String そのものになっていることを確かめる"
probe="$modules/Probe.swift"
printf 'import Rill\nlet probe: String.Type = DisplayText.self\n' > "$probe"
swiftc_simulator -typecheck -module-name Probe -I "$modules" "$probe"

echo "3. アプリのソースを型検査する"
swiftc_simulator -typecheck -module-name RillArchitectureSample -I "$modules" "${sources[@]}"

echo
echo "多言語化しない設定でも、アプリのソースが組める"
