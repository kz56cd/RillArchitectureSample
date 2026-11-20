import Foundation

/// 保存した読書の記録
nonisolated struct ReadingLog: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let pages: Int
    let rating: Int?
    let loggedAt: Date

    init(id: UUID, input: ReadingLogInput, loggedAt: Date) {
        self.id = id
        title = input.title
        pages = input.pages
        rating = input.rating
        self.loggedAt = loggedAt
    }
}

/// 確かめ終えた、保存する読書の記録
nonisolated struct ReadingLogInput: Equatable, Sendable {
    let title: String
    let pages: Int
    let rating: Int?
}
