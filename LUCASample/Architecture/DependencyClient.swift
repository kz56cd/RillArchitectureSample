/// 外部との接続の決まり
///
/// API、保存先、時刻などを、`@Sendable` のクロージャを持つ構造体で表す。
/// 本番では `liveValue`、テストでは `testValue` を使う。
protocol DependencyClient: Sendable {
    static var liveValue: Self { get }
    static var testValue: Self { get }
}

/// `testValue` の一部を差し替えた依存を作る。
///
/// ```swift
/// let readingLogClient = testDependency(of: ReadingLogClient.self) {
///     $0.save = { _ in throw TestError() }
/// }
/// ```
func testDependency<D: DependencyClient>(of type: D.Type, injection: (inout D) -> Void) -> D {
    var dependency = type.testValue
    injection(&dependency)
    return dependency
}
