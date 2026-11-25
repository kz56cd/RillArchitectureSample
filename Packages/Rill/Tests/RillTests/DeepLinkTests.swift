import Foundation
import Testing
@testable import Rill

/// `open(_:as:action:)` と `binding(_:send:)` のテスト
struct DeepLinkTests {

    @Test func open_解釈できるURL_行き先をActionとして送る() async throws {
        let sut = Counter()
        let url = try #require(URL(string: "counter://count/5"))

        let opened = await sut.open(url, as: CounterLink.self) { link in
            switch link {
            case let .count(value): .countSelected(value)
            }
        }

        #expect(opened)
        #expect(sut.state.count == 5)
        #expect(sut.events.values == [
            .reduce(.countSelected(5)),
            .parent(.countSelected(5))
        ])
    }

    @Test(arguments: ["counter://count/abc", "other://count/5", "counter://unknown/5"])
    func open_解釈できないURL_何も送らない(string: String) async throws {
        let sut = Counter()
        let url = try #require(URL(string: string))

        let opened = await sut.open(url, as: CounterLink.self) { _ in .incrementButtonTapped }

        #expect(!opened)
        #expect(sut.state.count == 0)
        #expect(sut.events.values.isEmpty)
    }

    @Test func binding_状態の値を返し_書き込むとActionを送る() async {
        let sut = Counter()
        let binding = sut.binding(\.state.count, send: { .countSelected($0) })
        #expect(binding.wrappedValue == 0)

        binding.wrappedValue = 3
        // 書き込んだだけでは状態は変わらない。Action が処理されてから変わる。
        #expect(sut.state.count == 0)
        for _ in 0 ..< 100 where sut.state.count != 3 {
            await Task.yield()
        }

        #expect(sut.state.count == 3)
        #expect(binding.wrappedValue == 3)
        #expect(sut.events.values == [
            .reduce(.countSelected(3)),
            .parent(.countSelected(3))
        ])
    }
}
