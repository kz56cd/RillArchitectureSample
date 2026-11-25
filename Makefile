XCODEGEN := mint run yonaskolb/XcodeGen@8d3d3476a69ae3e5d68e1adccc701c410c05eb36
DESTINATION ?= platform=iOS Simulator,name=iPhone 17
# Rill パッケージの trait。多言語化しないアプリなら NoLocalization(例: make build RILL_TRAITS=NoLocalization)
RILL_TRAITS ?=

.PHONY: generate build test test-rill check-unidirectional check-no-localization check

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
	cd Packages/Rill && swift test
	cd Packages/Rill && swift test --traits NoLocalization

## 単一方向を破る書き方が、コンパイルエラーになることを確かめる
check-unidirectional:
	./Checks/check-unidirectional.sh

## 多言語化しない設定(trait NoLocalization)でも、アプリのソースが組めることを確かめる
check-no-localization:
	./Checks/check-no-localization.sh

## すべて確かめる
check: test test-rill check-unidirectional check-no-localization
