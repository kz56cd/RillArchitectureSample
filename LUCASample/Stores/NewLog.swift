import Architecture
import Observation

/// 記録する画面のストア
///
/// 入力中(子の `LogForm`)と保存したあとを、`phase` で出し分ける。
/// 子から保存できたと届いたら、保存したあとへ切り替える。
@Observable
final class NewLog: Composable {

    struct State {
        var phase: Phase
    }

    enum Phase {
        case editing(LogForm)
        case saved(ReadingLog)
    }

    // MARK: State

    private(set) var state: State

    // MARK: Properties

    private let appDependencies: AppDependencies
    let action: (Action) async -> Void

    // MARK: Initializers

    init(_ appDependencies: AppDependencies, action: @escaping (Action) async -> Void = { _ in }) {
        // self を捕まえる方法は AppRoot の init と同じ。
        weak var parent: NewLog?
        state = State(phase: .editing(LogForm(appDependencies, action: { await parent?.send(.form($0)) })))
        self.appDependencies = appDependencies
        self.action = action
        parent = self
    }

    // MARK: Functions

    func reduce(_ action: Action) async {
        switch action {
        case .writeAnotherButtonTapped:
            state.phase = .editing(LogForm(appDependencies, action: { [weak self] in await self?.send(.form($0)) }))

        case let .form(.saveResponse(.success(saved))):
            state.phase = .saved(saved)

        case .form:
            break
        }
    }

    enum Action: Sendable {
        case writeAnotherButtonTapped
        case form(LogForm.Action)
    }
}
