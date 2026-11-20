import Testing
@testable import Rill

/// `testDependency(of:injection:)` のテスト
struct DependencyClientTests {

    struct GreetingClient: DependencyClient {
        static let liveValue = GreetingClient(greet: { "live: \($0)" }, farewell: { "live: bye \($0)" })
        static let testValue = GreetingClient(greet: { "test: \($0)" }, farewell: { "test: bye \($0)" })

        var greet: @Sendable (String) -> String
        var farewell: @Sendable (String) -> String
    }

    @Test func testDependency_差し替えた所だけが変わる() {
        let sut = testDependency(of: GreetingClient.self) {
            $0.greet = { "stub: \($0)" }
        }

        #expect(sut.greet("a") == "stub: a")
        #expect(sut.farewell("a") == "test: bye a")
    }

    @Test func testDependency_何も差し替えない_testValueと同じ() {
        let sut = testDependency(of: GreetingClient.self) { _ in }

        #expect(sut.greet("a") == "test: a")
        #expect(sut.farewell("a") == "test: bye a")
    }

    @Test func testDependency_testValueそのものは変わらない() {
        _ = testDependency(of: GreetingClient.self) {
            $0.greet = { "stub: \($0)" }
        }

        #expect(GreetingClient.testValue.greet("a") == "test: a")
    }
}
