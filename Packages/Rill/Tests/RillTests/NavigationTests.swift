import Testing
@testable import Rill

/// `navigationPath(_:pop:)` の Binding と `IdentityHashable` のテスト
struct NavigationTests {

    @Test func get_積んだ子のストアを返す() async {
        let sut = Counter()
        let binding = sut.navigationPath(\.state.path, pop: { .pathPopped(count: $0) })
        #expect(binding.wrappedValue.isEmpty)

        await sut.send(.pushButtonTapped)
        await sut.send(.pushButtonTapped)

        #expect(binding.wrappedValue == sut.state.path)
        #expect(binding.wrappedValue.count == 2)
    }

    @Test func set_短くする_残った数でpopのActionを送って戻る() async {
        let sut = Counter()
        await sut.send(.pushButtonTapped)
        await sut.send(.pushButtonTapped)
        await sut.send(.pushButtonTapped)
        let first = sut.state.path[0]
        let binding = sut.navigationPath(\.state.path, pop: { .pathPopped(count: $0) })

        binding.wrappedValue = [first]
        await waitUntil { sut.state.path.count == 1 }

        #expect(sut.state.path == [first])
        #expect(sut.events.values.suffix(2) == [
            .reduce(.pathPopped(count: 1)),
            .parent(.pathPopped(count: 1))
        ])
    }

    @Test func set_長くする_Actionを送らない() async {
        let sut = Counter()
        await sut.send(.pushButtonTapped)
        let path = sut.state.path
        let eventCount = sut.events.values.count
        let binding = sut.navigationPath(\.state.path, pop: { .pathPopped(count: $0) })

        binding.wrappedValue = path + [Counter()]
        await settle()

        #expect(sut.state.path == path)
        #expect(sut.events.values.count == eventCount)
    }

    @Test func IdentityHashable_同じストアだけを等しいとみなす() async {
        let store = Counter()
        let sameState = Counter()
        await store.send(.incrementButtonTapped)
        let hashBefore = store.hashValue

        await sameState.send(.incrementButtonTapped)
        await store.send(.incrementButtonTapped)

        #expect(store == store)
        #expect(store != sameState)
        // 状態が変わっても、同じストアのハッシュ値は変わらない。
        #expect(store.hashValue == hashBefore)
        #expect(Set([store, store, sameState]).count == 2)
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
