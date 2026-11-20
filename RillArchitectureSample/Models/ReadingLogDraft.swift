/// 入力中の読書の記録
///
/// 入力欄に打った文字列のまま持つ。数として読めるか、範囲に収まるかは `validate()` が判定する。
nonisolated struct ReadingLogDraft: Equatable, Sendable {

    // MARK: Static Properties

    /// 書名の最大の文字数
    private static let titleMaxLength = 50
    /// 読んだページ数の入力できる範囲
    private static let pagesRange = 1 ... 2000
    /// 評価の入力できる範囲
    private static let ratingRange = 1 ... 5

    // MARK: Properties

    var title = ""
    var pages = ""
    var rating = ""

    // MARK: Functions

    func validate() -> ReadingLogValidation {
        let titleValue = title.trimmingCharacters(in: .whitespaces)
        let pagesValue = Int(pages).flatMap { Self.pagesRange.contains($0) ? $0 : nil }
        // 評価は空欄を許す。何か入っているときだけ範囲を見る。
        let ratingValue = Int(rating).flatMap { Self.ratingRange.contains($0) ? $0 : nil }

        var invalidFields: Set<ReadingLogField> = []
        if titleValue.isEmpty || titleValue.count > Self.titleMaxLength {
            invalidFields.insert(.title)
        }
        if pagesValue == nil {
            invalidFields.insert(.pages)
        }
        if !rating.isEmpty, ratingValue == nil {
            invalidFields.insert(.rating)
        }
        guard invalidFields.isEmpty, let pagesValue else {
            return .invalid(invalidFields)
        }
        return .valid(ReadingLogInput(title: titleValue, pages: pagesValue, rating: ratingValue))
    }
}

/// 読書の記録の入力欄
nonisolated enum ReadingLogField: Hashable, Sendable, CaseIterable {
    case title
    case pages
    case rating
}

/// 入力した値を確かめた結果
nonisolated enum ReadingLogValidation: Equatable, Sendable {
    case valid(ReadingLogInput)
    /// 範囲外か未入力の欄がある
    case invalid(Set<ReadingLogField>)
}
