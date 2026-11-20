#!/bin/bash
# ストアの状態を外から書き換える書き方が、コンパイルエラーになることを確かめる。
#
# 1. アプリのソースだけなら、型検査が通る。
# 2. Checks/UnidirectionalViolations.swift を足すと、`// expected-error` の行がすべてエラーになる。
set -euo pipefail

cd "$(dirname "$0")/.."

violations=Checks/UnidirectionalViolations.swift
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

# アプリが import する Rill パッケージを、先にモジュールとして作る。
modules=$(mktemp -d)
trap 'rm -rf "$modules"' EXIT
swiftc_simulator -emit-module \
    -module-name Rill \
    -emit-module-path "$modules/Rill.swiftmodule" \
    Packages/Rill/Sources/Rill/*.swift

typecheck() {
    swiftc_simulator -typecheck -module-name RillArchitectureSample -I "$modules" "$@"
}

echo "1. アプリのソースだけで型検査する"
typecheck "${sources[@]}"
echo "   通った"

echo "2. 単一方向を破る書き方を足して型検査する"
if output=$(typecheck "${sources[@]}" "$violations" 2>&1); then
    echo "   型検査が通ってしまった。単一方向を破る書き方が許されている" >&2
    exit 1
fi

expected_lines=$(grep -n '// expected-error$' "$violations" | cut -d: -f1)
failed=0
for line in $expected_lines; do
    if grep -q "^${violations}:${line}:[0-9]*: error:" <<< "$output"; then
        echo "   ${line} 行目: エラーになった"
    else
        echo "   ${line} 行目: エラーにならなかった" >&2
        failed=1
    fi
done

unexpected=$(grep ': error:' <<< "$output" | grep -v "^${violations}:" || true)
if [ -n "$unexpected" ]; then
    echo "   見本のファイル以外でエラーが出た:" >&2
    echo "$unexpected" >&2
    failed=1
fi

echo
grep "^${violations}:[0-9]*:[0-9]*: error:" <<< "$output" | sed 's/^/   /'

if [ "$failed" -ne 0 ]; then
    exit 1
fi
echo
echo "単一方向の決まりは、コンパイラーで守られている"
