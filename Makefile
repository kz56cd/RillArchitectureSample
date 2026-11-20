XCODEGEN := mint run yonaskolb/XcodeGen@8d3d3476a69ae3e5d68e1adccc701c410c05eb36
DESTINATION ?= platform=iOS Simulator,name=iPhone 17

.PHONY: generate build test test-architecture check-unidirectional check

## Xcode のプロジェクトを project.yml から作る
generate:
	$(XCODEGEN) generate

## アプリをビルドする
build: generate
	xcodebuild build -project LUCASample.xcodeproj -scheme LUCASample -destination '$(DESTINATION)' -quiet

## アプリのストアと Architecture パッケージのテストを、シミュレーターで流す
test: generate
	xcodebuild test -project LUCASample.xcodeproj -scheme LUCASample -destination '$(DESTINATION)' -quiet

## Architecture パッケージのテストだけを、macOS で手早く流す
test-architecture:
	cd Packages/Architecture && swift test

## 単一方向を破る書き方が、コンパイルエラーになることを確かめる
check-unidirectional:
	./Checks/check-unidirectional.sh

## すべて確かめる
check: test check-unidirectional
