XCODEGEN := mint run yonaskolb/XcodeGen@8d3d3476a69ae3e5d68e1adccc701c410c05eb36
DESTINATION ?= platform=iOS Simulator,name=iPhone 17

.PHONY: generate build test test-rill check-unidirectional check

## Xcode のプロジェクトを project.yml から作る
generate:
	$(XCODEGEN) generate

## アプリをビルドする
build: generate
	xcodebuild build -project RillArchitectureSample.xcodeproj -scheme RillArchitectureSample -destination '$(DESTINATION)' -quiet

## アプリのストアと Rill パッケージのテストを、シミュレーターで流す
test: generate
	xcodebuild test -project RillArchitectureSample.xcodeproj -scheme RillArchitectureSample -destination '$(DESTINATION)' -quiet

## Rill パッケージのテストだけを、macOS で手早く流す
test-rill:
	swift test

## 単一方向を破る書き方が、コンパイルエラーになることを確かめる
check-unidirectional:
	./Checks/check-unidirectional.sh

## すべて確かめる
check: test test-rill check-unidirectional
