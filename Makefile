XCODEGEN := mint run yonaskolb/XcodeGen@8d3d3476a69ae3e5d68e1adccc701c410c05eb36
DESTINATION ?= platform=iOS Simulator,name=iPhone 17
# Rill パッケージの trait。見本のアプリは日本語だけなので NoLocalization。多言語化する設定で作るなら RILL_TRAITS= と空にする
RILL_TRAITS ?= NoLocalization

.PHONY: generate build test test-rill check-unidirectional check-localization check

## Xcode のプロジェクトを project.yml から作る
generate:
	$(XCODEGEN) generate
	./Scripts/apply-rill-traits.sh "$(RILL_TRAITS)"

## アプリをビルドする
build: generate
	xcodebuild build -project RillArchitectureSample.xcodeproj -scheme RillArchitectureSample -destination '$(DESTINATION)' -quiet

## アプリのストアと Rill パッケージのテストを、シミュレーターで流す
test: generate
	xcodebuild test -project RillArchitectureSample.xcodeproj -scheme RillArchitectureSample -destination '$(DESTINATION)' -quiet

## Rill パッケージのテストだけを、macOS で手早く流す。多言語化する設定と、しない設定(trait NoLocalization)の両方
test-rill:
	swift test
	swift test --traits NoLocalization

## 単一方向を破る書き方が、コンパイルエラーになることを確かめる
check-unidirectional:
	./Checks/check-unidirectional.sh

## 多言語化する設定(trait なし)でも、アプリのソースが組めることを確かめる
check-localization:
	./Checks/check-localization.sh

## すべて確かめる
check: test test-rill check-unidirectional check-localization
