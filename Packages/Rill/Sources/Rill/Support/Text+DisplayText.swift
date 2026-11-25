import SwiftUI

// trait `NoLocalization` のときは、`DisplayText` が `String` なので、SwiftUI の `Text(_:)` がそのまま使える。
#if !NoLocalization

public extension Text {
    /// `DisplayText` を出す。訳す文言は訳し、そのまま出す文言は訳さない。
    ///
    /// 文字列リテラルの `Text("...")` は、これまでどおり SwiftUI の書き方が選ばれる。
    @_disfavoredOverload
    init(_ text: DisplayText) {
        switch text {
        case let .localized(resource):
            self.init(resource)
        case let .verbatim(string):
            self.init(verbatim: string)
        }
    }
}

#endif
