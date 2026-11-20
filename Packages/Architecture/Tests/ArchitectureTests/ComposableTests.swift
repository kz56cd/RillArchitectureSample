import Testing
@testable import Architecture

/// `Composable` の `send` の決まりのテスト
struct ComposableTests {

    @Test func send_reduceで状態を変えてから親へ伝える() async {
        let sut = Counter()

        await sut.send(.incrementButtonTapped)

        #expect(sut.count == 1)
        #expect(sut.events.values == [
            .reduce(.incrementButtonTapped),
            .parent(.incrementButtonTapped)
        ])
    }

    @Test func send_親へ伝えるときには状態が確定している() async {
        let countSeenByParent = Recorder<Int>()
        weak var weakSUT: Counter?
        let sut = Counter(action: { _ in
            if let count = weakSUT?.count {
                countSeenByParent.record(count)
            }
        })
        weakSUT = sut

        await sut.send(.incrementButtonTapped)

        #expect(countSeenByParent.values == [1])
    }

    @Test func send_reduceの中で待つ処理も終わりまで待つ() async {
        let sut = Counter()

        await sut.send(.slowIncrementButtonTapped)

        #expect(sut.count == 1)
        #expect(sut.events.values.last == .parent(.slowIncrementButtonTapped))
    }

    @Test func send_reduceの中からsend_結果が先に親へ届く() async {
        let sut = Counter()

        await sut.send(.loadButtonTapped)

        #expect(sut.count == 42)
        #expect(sut.events.values == [
            .reduce(.loadButtonTapped),
            .reduce(.loadResponse(42)),
            .parent(.loadResponse(42)),
            .parent(.loadButtonTapped)
        ])
    }

    @Test func send_reduceを書かないストア_親へそのまま伝える() async {
        let parent = Recorder<Relay.Action>()
        let sut = Relay(action: { parent.record($0) })

        await sut.send(.ping)

        #expect(parent.values == [.ping])
    }

    @Test func send_子のActionが親のreduceに届く() async {
        weak var weakParent: Counter?
        let parent = Counter()
        weakParent = parent
        let child = Counter(action: { _ in await weakParent?.send(.incrementButtonTapped) })

        await child.send(.incrementButtonTapped)
        await child.send(.incrementButtonTapped)

        #expect(child.count == 2)
        #expect(parent.count == 2)
    }
}
