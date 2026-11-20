import Observation
@testable import Architecture

/// 起きたことを順に溜める。
final class Recorder<Value> {

    // MARK: Properties

    private(set) var values: [Value] = []

    // MARK: Functions

    func record(_ value: Value) {
        values.append(value)
    }
}

/// テスト用のストア
///
/// `reduce` と親への通知が、どの順に呼ばれたかを `events` に溜める。
@Observable
final class Counter: Composable {

    enum Event: Equatable {
        case reduce(Action)
        case parent(Action)
    }

    // MARK: State

    private(set) var count: Int
    private(set) var child: Counter?

    // MARK: Properties

    let events: Recorder<Event>
    let action: (Action) async -> Void

    // MARK: Initializers

    init(count: Int = 0, events: Recorder<Event> = Recorder(), action: @escaping (Action) async -> Void = { _ in }) {
        self.count = count
        self.events = events
        self.action = { value in
            events.record(.parent(value))
            await action(value)
        }
    }

    // MARK: Functions

    func reduce(_ action: Action) async {
        events.record(.reduce(action))
        switch action {
        case .incrementButtonTapped:
            count += 1

        case .slowIncrementButtonTapped:
            // reduce の途中で待っても、send は終わりまで待つ。
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(10))
            count += 1

        case .loadButtonTapped:
            // reduce の中から send すると、結果が先に親へ届く。
            await send(.loadResponse(42))

        case let .loadResponse(value):
            count = value

        case .openChildButtonTapped:
            child = Counter()

        case .childDismissed:
            child = nil
        }
    }

    enum Action: Equatable, Sendable {
        case incrementButtonTapped
        case slowIncrementButtonTapped
        case loadButtonTapped
        case loadResponse(Int)
        case openChildButtonTapped
        case childDismissed
    }
}

/// `reduce` を書かないストア。既定の `reduce` が使われる
final class Relay: Composable {

    // MARK: Properties

    let action: (Action) async -> Void

    // MARK: Initializers

    init(action: @escaping (Action) async -> Void) {
        self.action = action
    }

    enum Action: Equatable, Sendable {
        case ping
    }
}
