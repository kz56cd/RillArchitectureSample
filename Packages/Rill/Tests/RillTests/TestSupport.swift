import Foundation
import Observation
@testable import Rill

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
final class Counter: Composable, nonisolated IdentityHashable {

    struct State {
        var count = 0
        var child: Counter?
        var path: [Counter] = []
        var alert: AlertState<Action>?
    }

    enum Event: Equatable {
        case reduce(Action)
        case parent(Action)
    }

    // MARK: State

    private(set) var state: State

    // MARK: Properties

    let events: Recorder<Event>
    let action: (Action) async -> Void

    // MARK: Initializers

    init(state: State = State(), events: Recorder<Event> = Recorder(), action: @escaping (Action) async -> Void = { _ in }) {
        self.state = state
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
            state.count += 1

        case .slowIncrementButtonTapped:
            // reduce の途中で待っても、send は終わりまで待つ。
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(10))
            state.count += 1

        case .loadButtonTapped:
            // reduce の中から send すると、結果が先に親へ届く。
            await send(.loadResponse(42))

        case let .loadResponse(value):
            state.count = value

        case .openChildButtonTapped:
            state.child = Counter()

        case .childDismissed:
            state.child = nil

        case .pushButtonTapped:
            state.path.append(Counter())

        case let .pathPopped(count):
            state.path.removeLast(state.path.count - count)

        case let .countSelected(value):
            state.count = value

        case .resetButtonTapped:
            state.alert = AlertState(
                title: "数を 0 に戻しますか?",
                buttons: [
                    AlertButton("戻す", role: .destructive, action: .resetConfirmed),
                    AlertButton("キャンセル", role: .cancel)
                ]
            )

        case .resetConfirmed:
            state.count = 0

        case .alertDismissed:
            state.alert = nil
        }
    }

    enum Action: Equatable, Sendable {
        case incrementButtonTapped
        case slowIncrementButtonTapped
        case loadButtonTapped
        case loadResponse(Int)
        case openChildButtonTapped
        case childDismissed
        case pushButtonTapped
        case pathPopped(count: Int)
        case countSelected(Int)
        case resetButtonTapped
        case resetConfirmed
        case alertDismissed
    }
}

/// `reduce` を書かないストア。既定の `reduce` が使われる
final class Relay: Composable {

    struct State {}

    // MARK: Properties

    let state = State()
    let action: (Action) async -> Void

    // MARK: Initializers

    init(action: @escaping (Action) async -> Void) {
        self.action = action
    }

    enum Action: Equatable, Sendable {
        case ping
    }
}

/// テスト用の行き先。`counter://count/5` を `.count(5)` にする
enum CounterLink: DeepLink, Equatable {
    case count(Int)

    init?(url: URL) {
        guard url.scheme == "counter", url.host() == "count",
              let value = Int(url.lastPathComponent) else {
            return nil
        }
        self = .count(value)
    }
}
