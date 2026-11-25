import SwiftUI
import Testing
@testable import Rill

/// アラートと確認ダイアログの補助のテスト
///
/// SwiftUI は、ボタンを押したときに、ボタンの処理と「出ていない」への書き換えの両方を呼ぶ。
/// 呼ばれる順番によらず、閉じる Action が 1 回だけ届き、そのあとにボタンの Action が届くことを確かめる。
struct AlertTests {

    @Test func ボタン_閉じるActionのあとにボタンのActionを送る() async throws {
        let sut = Counter(state: .init(count: 3))
        await sut.send(.resetButtonTapped)
        let alert = try #require(sut.state.alert)
        let eventCount = sut.events.values.count

        await sut.tapAlertButton(alert.buttons[0], in: \.state.alert, dismiss: .alertDismissed)

        #expect(sut.state.alert == nil)
        #expect(sut.state.count == 0)
        #expect(sut.events.values.dropFirst(eventCount).filter(\.isReduce) == [
            .reduce(.alertDismissed),
            .reduce(.resetConfirmed)
        ])
    }

    @Test func Actionの無いボタン_閉じるActionだけを送る() async throws {
        let sut = Counter(state: .init(count: 3))
        await sut.send(.resetButtonTapped)
        let alert = try #require(sut.state.alert)
        let eventCount = sut.events.values.count

        await sut.tapAlertButton(alert.buttons[1], in: \.state.alert, dismiss: .alertDismissed)

        #expect(sut.state.alert == nil)
        #expect(sut.state.count == 3)
        #expect(sut.events.values.dropFirst(eventCount).filter(\.isReduce) == [.reduce(.alertDismissed)])
    }

    @Test func 外を押して閉じた_閉じるActionを送る() async {
        let sut = Counter()
        await sut.send(.resetButtonTapped)
        let binding = sut.isAlertPresented(\.state.alert, dismiss: .alertDismissed)
        #expect(binding.wrappedValue)

        binding.wrappedValue = false
        for _ in 0 ..< 100 where sut.state.alert != nil {
            await Task.yield()
        }

        #expect(sut.state.alert == nil)
        #expect(!binding.wrappedValue)
    }

    @Test(arguments: [true, false])
    func ボタンと書き換えの順番によらず_閉じるActionは1回(bindingFirst: Bool) async throws {
        let sut = Counter(state: .init(count: 3))
        await sut.send(.resetButtonTapped)
        let alert = try #require(sut.state.alert)
        let binding = sut.isAlertPresented(\.state.alert, dismiss: .alertDismissed)
        let eventCount = sut.events.values.count

        if bindingFirst {
            binding.wrappedValue = false
            await sut.tapAlertButton(alert.buttons[0], in: \.state.alert, dismiss: .alertDismissed)
        } else {
            await sut.tapAlertButton(alert.buttons[0], in: \.state.alert, dismiss: .alertDismissed)
            binding.wrappedValue = false
        }
        for _ in 0 ..< 100 {
            await Task.yield()
        }

        let reduced = sut.events.values.dropFirst(eventCount).filter(\.isReduce)
        #expect(reduced.filter { $0 == .reduce(.alertDismissed) }.count == 1)
        #expect(reduced.contains(.reduce(.resetConfirmed)))
        #expect(sut.state.count == 0)
    }
}

private extension Counter.Event {
    var isReduce: Bool {
        if case .reduce = self { true } else { false }
    }
}
