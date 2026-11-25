import Foundation

#if NoLocalization

/// 画面に出す文言(多言語化しないアプリ)
///
/// trait `NoLocalization` を有効にしたアプリでは、`String` そのもの。
/// 訳さないので、訳す文言とそのまま出す文言を分ける必要が無い。`String` と同じように使える。
///
/// あとで多言語化するときは trait を外す。`String` として使っていた所(`count` や `+` など)が
/// コンパイルエラーになるので、直す所が分かる。
public typealias DisplayText = String

#else

/// 画面に出す文言
///
/// 訳す文言(`LocalizedStringResource`)と、訳さずにそのまま出す文言(`String`)の両方を持てる。
/// 書き分けは SwiftUI の `Text` と同じにしている。
///
/// | 書き方 | 扱い |
/// |---|---|
/// | `"削除できませんでした"`(文字列リテラル) | 訳す。リテラルがキーになる |
/// | `"「\(title)」を削除しますか?"`(埋め込みのあるリテラル) | 訳す。キーは `「%@」を削除しますか?` |
/// | `DisplayText(resource)`(`LocalizedStringResource`) | 訳す |
/// | `DisplayText(serverMessage)`(`String` の変数) | 訳さず、そのまま出す |
///
/// 訳が見つからなければキー(書いた文字列)をそのまま出すので、多言語に対応していないアプリでも同じように使える。
///
/// ストアの状態に文言を持つときは、`String` ではなくこの型で持つ。
/// SwiftUI では `Text(displayText)`、UIKit やログでは `displayText.resolve()` で文字列にする。
nonisolated public enum DisplayText: Sendable, Equatable {
    /// 訳す文言
    case localized(LocalizedStringResource)
    /// 訳さずにそのまま出す文言
    case verbatim(String)

    // MARK: Initializers

    /// 訳す文言
    public init(_ resource: LocalizedStringResource) {
        self = .localized(resource)
    }

    /// 訳さずにそのまま出す文言。サーバーから届いた文言や、利用者が入れた値に使う
    @_disfavoredOverload
    public init<S: StringProtocol>(_ string: S) {
        self = .verbatim(String(string))
    }

    // MARK: Functions

    /// 文字列にする。訳す文言は、`locale` の言語の訳にする(訳が無ければキーのまま)。
    public func resolve(locale: Locale = .current) -> String {
        switch self {
        case var .localized(resource):
            resource.locale = locale
            return String(localized: resource)
        case let .verbatim(string):
            return string
        }
    }
}

extension DisplayText: ExpressibleByStringInterpolation {
    public typealias StringInterpolation = LocalizedStringResource.StringInterpolation

    public init(stringLiteral value: String) {
        self = .localized(LocalizedStringResource(stringLiteral: value))
    }

    public init(stringInterpolation: StringInterpolation) {
        self = .localized(LocalizedStringResource(stringInterpolation: stringInterpolation))
    }
}

#endif
