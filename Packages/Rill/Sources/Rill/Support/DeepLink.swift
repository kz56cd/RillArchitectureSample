import Foundation

/// 外から開かれた URL(カスタム URL スキーム、ユニバーサルリンク)を、アプリの中の行き先にする。
///
/// 行き先は enum で表し、ストアは `switch` で受ける。`default` を書かなければ、
/// 行き先を足したときに受け忘れがコンパイルエラーになる。
///
/// ```swift
/// enum AppLink: DeepLink {
///     case logList
///     case log(id: ReadingLog.ID)
///
///     init?(url: URL) { ... }
/// }
/// ```
///
/// URL の解釈は値の型の中で閉じるので、ストアや View を作らずにテストできる。
nonisolated public protocol DeepLink: Sendable {
    /// 解釈できない URL なら nil
    init?(url: URL)
}

public extension Composable {
    /// URL を行き先にして、Action として送る。
    ///
    /// ディープリンクも、ほかの操作と同じく Action で状態を変える。一番上のストアに送り、
    /// 各ストアは自分の状態を変えてから、残りを子へ `send` で渡す。
    ///
    /// - Returns: 解釈できない URL なら何も送らず false
    @discardableResult
    func open<Link: DeepLink>(_ url: URL, as type: Link.Type, action: (Link) -> Action) async -> Bool {
        guard let link = Link(url: url) else {
            return false
        }
        await send(action(link))
        return true
    }
}
