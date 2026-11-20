import Observation

/// 記録の入力欄のストア
@Observable
final class LogForm: Composable {

    // MARK: State

    /// 入力欄の値。`TextField` は同期で書き換える必要があるので、例外として View から直接束縛させる。
    /// 値を使う判断(確かめる、保存する)は `saveButtonTapped` の中で行う。
    var draft: ReadingLogDraft
    private(set) var invalidFields: Set<ReadingLogField>
    private(set) var isSaving: Bool
    private(set) var saveFailed: Bool

    // MARK: Properties

    private let readingLogClient: ReadingLogClient
    let action: (Action) async -> Void

    // MARK: Initializers

    init(
        _ appDependencies: AppDependencies,
        draft: ReadingLogDraft = ReadingLogDraft(),
        invalidFields: Set<ReadingLogField> = [],
        isSaving: Bool = false,
        saveFailed: Bool = false,
        action: @escaping (Action) async -> Void = { _ in }
    ) {
        self.draft = draft
        self.invalidFields = invalidFields
        self.isSaving = isSaving
        self.saveFailed = saveFailed
        readingLogClient = appDependencies.readingLogClient
        self.action = action
    }

    // MARK: Functions

    func reduce(_ action: Action) async {
        switch action {
        case .saveButtonTapped:
            switch draft.validate() {
            case let .invalid(fields):
                invalidFields = fields
            case let .valid(input):
                invalidFields = []
                isSaving = true
                saveFailed = false
                do {
                    let saved = try await readingLogClient.save(input)
                    await send(.saveResponse(.success(saved)))
                } catch {
                    await send(.saveResponse(.failure(error)))
                }
            }

        case .saveResponse(.success):
            // 保存したあとの画面への切り替えは親(NewLog)が行う。
            isSaving = false

        case .saveResponse(.failure):
            isSaving = false
            saveFailed = true
        }
    }

    enum Action: Sendable {
        case saveButtonTapped
        case saveResponse(Result<ReadingLog, any Error>)
    }
}
