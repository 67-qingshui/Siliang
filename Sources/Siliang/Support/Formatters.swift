import Foundation

// 数据格式固定 ja-JP
enum Format {
    static let locale = Locale(identifier: "ja_JP")

    static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = locale
        c.firstWeekday = 1   // Sunday
        c.minimumDaysInFirstWeek = 1
        return c
    }

    private static let dayF: DateFormatter = {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "M/d"
        return f
    }()

    private static let fullDateF: DateFormatter = {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "yyyy/MM/dd"
        return f
    }()

    private static let dateTimeF: DateFormatter = {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "yyyy/MM/dd HH:mm"
        return f
    }()

    private static let monthYearF: DateFormatter = {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "yyyy年M月"
        return f
    }()

    static func day(_ d: Date) -> String { dayF.string(from: d) }
    static func date(_ d: Date) -> String { fullDateF.string(from: d) }
    static func dateTime(_ d: Date) -> String { dateTimeF.string(from: d) }
    static func monthYear(_ d: Date) -> String { monthYearF.string(from: d) }

    static func yen(_ v: Double) -> String {
        let nf = NumberFormatter()
        nf.locale = locale
        nf.numberStyle = .currency
        nf.currencyCode = "JPY"
        nf.maximumFractionDigits = 0
        return nf.string(from: NSNumber(value: v)) ?? "¥\(Int(v.rounded()))"
    }

    static func number(_ v: Double) -> String {
        let nf = NumberFormatter()
        nf.locale = locale
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        return nf.string(from: NSNumber(value: v)) ?? "\(v)"
    }

    static func int(_ v: Int) -> String {
        let nf = NumberFormatter()
        nf.locale = locale
        nf.numberStyle = .decimal
        return nf.string(from: NSNumber(value: v)) ?? "\(v)"
    }

    static func sign(_ v: Double) -> String {
        if v > 0 { return "+" }
        if v < 0 { return "-" }
        return ""
    }

    /// 数字输入清洗: 去除非数字字符 (保留 . 和数字, 全角转半角)
    static func sanitizeNumberInput(_ s: String) -> String {
        var out = ""
        var hasDot = false
        for ch in s {
            let c = String(ch)
            if c == "." {
                if hasDot { continue }
                hasDot = true
                out += "."
            } else if c == "。", !hasDot {
                hasDot = true
                out += "."
            } else if let v = Int(c), v >= 0, v <= 9 {
                out += c
            } else if c == "０" { out += "0" }
            else if c == "１" { out += "1" }
            else if c == "２" { out += "2" }
            else if c == "３" { out += "3" }
            else if c == "４" { out += "4" }
            else if c == "５" { out += "5" }
            else if c == "６" { out += "6" }
            else if c == "７" { out += "7" }
            else if c == "８" { out += "8" }
            else if c == "９" { out += "9" }
        }
        return out
    }
}