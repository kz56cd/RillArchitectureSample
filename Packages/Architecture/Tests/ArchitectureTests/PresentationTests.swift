import Testing
@testable import Architecture

/// `presentation(_:dismiss:)` の Binding のテスト
struct PresentationTests {

    @Test func get_子のストアを返す() async throws {
        let sut = Counter()
        let binding = sut.presentation(\.child, dismiss: .childDismissed)
        #expect(binding.wrappedValue == nil)

        await sut.send(.openChildButtonTapped)

        let child = try #require(sut.child)
        #expect(binding.wrappedValue === child)
    }

    @Test func set_nil_dismissのActionを送って閉じる() async throws {
        let sut = Counter()
        await sut.send(.openChildButtonTapped)
        let binding = sut.presentation(\.child, dismiss: .childDismissed)

        binding.wrappedValue = nil
        await waitUntil { sut.child == nil }

        #expect(sut.child == nil)
        #expect(sut.events.values.suffix(2) == [
            .reduce(.childDismissed),
            .parent(.childDismissed)
        ])
    }

    @Test func set_nil以外_Actionを送らない() async throws {
        let sut = Counter()
        await sut.send(.openChildButtonTapped)
        let child = try #require(sut.child)
        let eventCount = sut.events.values.count
        let binding = sut.presentation(\.child, dismiss: .childDismissed)

        binding.wrappedValue = Counter()
        await settle()

        #expect(sut.child === child)
        #expect(sut.events.values.count == eventCount)
    }

    // MARK: Helpers

    /// `Task` で送られた Action が処理されるまで待つ。
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0 ..< 100 where !condition() {
            await Task.yield()
        }
    }

    /// 送られたかもしれない `Task` が処理される機会を与える。
    private func settle() async {
        for _ in 0 ..< 100 {
            await Task.yield()
        }
    }
}
