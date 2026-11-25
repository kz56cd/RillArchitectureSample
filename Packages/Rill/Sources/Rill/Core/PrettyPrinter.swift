import Foundation

/// 値を、入れ子を字下げした文字列にする。
///
/// ```
/// LogList.State(
///   logs: [
///     ReadingLog(
///       title: "見本の本",
///       pages: 120
///     )
///   ],
///   detail: nil
/// )
/// ```
///
/// - ストア(`Composable`)は、その `state` を並べる。親の状態から、子のストアの状態まで 1 つの木で見られる。
/// - 集合と辞書は順番が決まらないので、並べ替えて出す。何度出しても同じ文字列になる。
/// - 型の名前からモジュールの名前は外す。
public enum PrettyPrinter {

    // MARK: Static Properties

    private static let indentUnit = "  "

    // MARK: Static Functions

    public static func format(_ value: Any) -> String {
        var visiting: Set<ObjectIdentifier> = []
        return format(value, indent: 0, visiting: &visiting)
    }

    private static func format(_ value: Any, indent: Int, visiting: inout Set<ObjectIdentifier>) -> String {
        if let store = value as? any Composable {
            let id = ObjectIdentifier(store)
            // 子のストアが親を状態に持つような循環があっても、止まるようにする。
            guard visiting.insert(id).inserted else {
                return "\(typeName(of: store))(…)"
            }
            defer { visiting.remove(id) }
            return format(store.state, indent: indent, visiting: &visiting)
        }

        switch value {
        case let string as String:
            return string.debugDescription
        case let character as Character:
            return String(character).debugDescription
        case is UUID, is Date, is URL, is Decimal:
            return String(describing: value)
        case let resource as LocalizedStringResource:
            // 中身(表、ロケール、バンドルなど)は並べず、キーだけを出す。どの言語で動かしても同じ文字列になる。
            return resource.key.debugDescription
        default:
            break
        }

        let mirror = Mirror(reflecting: value)
        switch mirror.displayStyle {
        case .optional:
            guard let wrapped = mirror.children.first?.value else {
                return "nil"
            }
            return format(wrapped, indent: indent, visiting: &visiting)

        case .struct, .class:
            let name = typeName(of: value)
            var fields: [String] = []
            for child in mirror.children {
                fields.append("\(child.label ?? "_"): \(format(child.value, indent: indent + 1, visiting: &visiting))")
            }
            return block(open: "\(name)(", close: ")", items: fields, indent: indent)

        case .enum:
            guard let payload = mirror.children.first else {
                return ".\(value)"
            }
            let caseName = ".\(payload.label ?? "")"
            let payloadMirror = Mirror(reflecting: payload.value)
            var items: [String] = []
            if payloadMirror.displayStyle == .tuple {
                // 関連値が複数あるときは、1 組の括弧に並べる。
                for child in payloadMirror.children {
                    items.append(labeled(child.label, format(child.value, indent: indent + 1, visiting: &visiting)))
                }
            } else {
                items.append(format(payload.value, indent: indent + 1, visiting: &visiting))
            }
            return inlineOrBlock(open: "\(caseName)(", close: ")", items: items, indent: indent)

        case .tuple:
            var items: [String] = []
            for child in mirror.children {
                items.append(labeled(child.label, format(child.value, indent: indent + 1, visiting: &visiting)))
            }
            return inlineOrBlock(open: "(", close: ")", items: items, indent: indent)

        case .collection:
            var items: [String] = []
            for child in mirror.children {
                items.append(format(child.value, indent: indent + 1, visiting: &visiting))
            }
            return block(open: "[", close: "]", items: items, indent: indent)

        case .set:
            var items: [String] = []
            for child in mirror.children {
                items.append(format(child.value, indent: indent + 1, visiting: &visiting))
            }
            return block(open: "Set([", close: "])", items: items.sorted(), indent: indent)

        case .dictionary:
            var items: [String] = []
            for child in mirror.children {
                let pair = Array(Mirror(reflecting: child.value).children)
                guard pair.count == 2 else { continue }
                let key = format(pair[0].value, indent: indent + 1, visiting: &visiting)
                let value = format(pair[1].value, indent: indent + 1, visiting: &visiting)
                items.append("\(key): \(value)")
            }
            guard !items.isEmpty else {
                return "[:]"
            }
            return block(open: "[", close: "]", items: items.sorted(), indent: indent)

        default:
            return String(describing: value)
        }
    }

    /// 要素を 1 行ずつ字下げして並べる。要素が無いときは 1 行で閉じる。
    private static func block(open: String, close: String, items: [String], indent: Int) -> String {
        guard !items.isEmpty else {
            return open + close
        }
        let inner = String(repeating: indentUnit, count: indent + 1)
        let outer = String(repeating: indentUnit, count: indent)
        let lines = items.map { inner + $0 }.joined(separator: ",\n")
        return "\(open)\n\(lines)\n\(outer)\(close)"
    }

    /// どの要素も 1 行なら 1 行に並べ、そうでなければ字下げして並べる。
    private static func inlineOrBlock(open: String, close: String, items: [String], indent: Int) -> String {
        guard items.contains(where: { $0.contains("\n") }) else {
            return open + items.joined(separator: ", ") + close
        }
        return block(open: open, close: close, items: items, indent: indent)
    }

    /// タプルのラベル。`.0` のような名前の無いラベルは付けない。
    private static func labeled(_ label: String?, _ text: String) -> String {
        guard let label, !label.hasPrefix(".") else {
            return text
        }
        return "\(label): \(text)"
    }

    /// モジュールの名前を外した型の名前。`RillArchitectureSample.LogList.State` なら `LogList.State`
    ///
    /// ジェネリクスの型引数の中も外す。`Rill.AlertState<RillTests.Counter.Action>` なら `AlertState<Counter.Action>`
    private static func typeName(of value: Any) -> String {
        let name = String(reflecting: type(of: value))
        var result = ""
        var component = ""
        for character in name {
            if "<>, ".contains(character) {
                result += withoutModule(component) + String(character)
                component = ""
            } else {
                component.append(character)
            }
        }
        return result + withoutModule(component)
    }

    /// `RillTests.Counter.Action` のような型の名前から、頭のモジュールの名前を外す。
    private static func withoutModule(_ name: String) -> String {
        guard let dot = name.firstIndex(of: ".") else {
            return name
        }
        return String(name[name.index(after: dot)...])
    }
}
