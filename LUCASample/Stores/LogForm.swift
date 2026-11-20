import Architecture
import Observation

/// 記録の入力欄のストア
@Observable
final class LogForm: Composable {

    struct State {
        var draft = ReadingLogDraft()
        var invalidFields: Set<ReadingLogField> = []
        var isSaving = false
        var saveFailed = false
    }

    // MARK: State

    private(set) var state: State

    /// 入力欄の値。`TextField` は同期で書き換える必要があるので、例外として View から直接束縛させる。
    /// 値を使う判断(確かめる、保存する)は `saveButtonTapped` の中で行う。
    var draft: ReadingLogDraft {
        get { state.draft }
        set { state.draft = newValue }
    }

    // MARK: Properties

    private let readingLogClient: ReadingLogClient
    let action: (Action) async -> Void

    // MARK: Initializers

    init(_ appDependencies: AppDependencies, state: State = State(), action: @escaping (Action) async -> Void = { _ in }) {
        self.state = state
        readingLogClient = appDependencies.readingLogClient
        self.action = action
    }

    // MARK: Functions

    func reduce(_ action: Action) async {
        switch action {
        case .saveButtonTapped:
            switch state.draft.validate() {
            case let .invalid(fields):
                state.invalidFields = fields
            case let .valid(input):
                state.invalidFields = []
                state.isSaving = true
                state.saveFailed = false
                do {
                    let saved = try await readingLogClient.save(input)
                    await send(.saveResponse(.success(saved)))
                } catch {
                    await send(.saveResponse(.failure(error)))
                }
            }

        case .saveResponse(.success):
            // 保存したあとの画面への切り替えは親(NewLog)が行う。
            state.isSaving = false

        case .saveResponse(.failure):
            state.isSaving = false
            state.saveFailed = true
        }
    }

    enum Action: Sendable {
        case saveButtonTapped
        case saveResponse(Result<ReadingLog, any Error>)
    }
}
