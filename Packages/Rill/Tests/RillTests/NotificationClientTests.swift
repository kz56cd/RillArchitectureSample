import Foundation
import Testing
@testable import Rill

/// `NotificationClient` のテスト
///
/// 本物の NotificationCenter を、テストごとに新しく作って使う。
struct NotificationClientTests {

    private static let name = Notification.Name("NotificationClientTests")

    @Test func notifications_届いた順に値にして流す() async {
        let center = NotificationCenter()
        let sut = NotificationClient.center(center)
        let stream = sut.notifications(named: Self.name) { $0.userInfo?["value"] as? Int }
        var iterator = stream.makeAsyncIterator()

        center.post(name: Self.name, object: nil, userInfo: ["value": 1])
        center.post(name: Self.name, object: nil, userInfo: ["other": 2]) // nil になる通知は流さない
        center.post(name: Notification.Name("ほかの通知"), object: nil, userInfo: ["value": 3])
        center.post(name: Self.name, object: nil, userInfo: ["value": 4])

        #expect(await iterator.next() == 1)
        #expect(await iterator.next() == 4)
    }

    @Test func notifications_受けているタスクを取り消すと_受け取りを止める() async {
        let center = NotificationCenter()
        let received = Counter.Recorded()
        let stream = NotificationClient.center(center).notifications(named: Self.name) { _ in
            received.increment()
            return ()
        }
        let task = Task {
            for await _ in stream {}
        }
        center.post(name: Self.name, object: nil)
        #expect(received.count == 1)

        task.cancel()
        await task.value
        center.post(name: Self.name, object: nil)

        #expect(received.count == 1)
    }

    @Test func testValue_何も届かない() async {
        let received = Counter.Recorded()
        let sut = NotificationClient.testValue
        let cancel = sut.observe(Self.name) { _ in received.increment() }
        NotificationCenter.default.post(name: Self.name, object: nil)
        cancel()

        #expect(received.count == 0)
    }
}

extension Counter {
    /// 通知を送ったスレッドから数える。
    nonisolated final class Recorded: @unchecked Sendable {
        private let lock = NSLock()
        private var value = 0

        var count: Int {
            lock.withLock { value }
        }

        func increment() {
            lock.withLock { value += 1 }
        }
    }
}
