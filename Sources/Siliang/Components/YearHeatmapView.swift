import SwiftUI

// MARK: - 年度热力图 v2
// GitHub-style annual heatmap: 数值热力 + 周期区间叠加 + hover tooltip + 今天高亮.
struct YearHeatmapView: View {
    var year: Int
    var dailyValues: [Date: Double] = [:]
    var periods: [(start: Date, end: Date)] = []
    var levels: [Color] = YearHeatmapView.greenLevels
    var periodColor: Color = .slPinkDeep
    var cell: CGFloat = 13
    var gap: CGFloat = 3

    @State private var hovered: Date?

    static let greenLevels: [Color] = [
        Color.slGreen.opacity(0.18),
        Color.slGreen.opacity(0.42),
        Color.slGreen.opacity(0.65),
        Color.slGreenDeep.opacity(0.85),
        Color(red: 0.28, green: 0.48, blue: 0.33)
    ]
    static let pinkLevels: [Color] = [
        Color.slPink.opacity(0.22),
        Color.slPink.opacity(0.45),
        Color.slPink.opacity(0.68),
        Color.slPinkDeep.opacity(0.85),
        Color(red: 0.70, green: 0.28, blue: 0.44)
    ]

    private let cal = Format.calendar

    var body: some View {
        let layout = HeatmapLayout.layout(year: year, cal: cal)
        let maxVal = max(dailyValues.values.max() ?? 1, 1)
        let today = cal.startOfDay(for: Date())

        VStack(alignment: .leading, spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                Canvas { ctx, size in
                    let topPad: CGFloat = 26
                    let leftPad: CGFloat = 0

                    // 月份标签
                    for (col, label) in layout.monthLabels {
                        let x = leftPad + CGFloat(col) * (cell + gap) + cell / 2
                        ctx.draw(
                            Text(label)
                                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.slMuted),
                            at: CGPoint(x: x, y: topPad / 2 + 2)
                        )
                    }

                    // 星期标签 (周一 ~ 周日, 第一行)
                    let weekdaySymbols = ["一", "三", "五", "日"]
                    for (i, s) in weekdaySymbols.enumerated() {
                        let row = i * 2
                        let y = topPad + CGFloat(row) * (cell + gap) + cell / 2
                        ctx.draw(
                            Text(s)
                                .font(.system(size: 8.5, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.slMuted.opacity(0.8)),
                            at: CGPoint(x: leftPad - 12, y: y)
                        )
                    }

                    // 格子
                    for day in layout.cells {
                        guard cal.component(.year, from: day.date) == year else { continue }
                        let rect = CGRect(
                            x: leftPad + CGFloat(day.column) * (cell + gap),
                            y: topPad + CGFloat(day.row) * (cell + gap),
                            width: cell,
                            height: cell
                        )
                        let r = cell * 0.24
                        let p = Path(roundedRect: rect, cornerRadius: r)

                        let isToday = day.date == today
                        let inPeriod = isInPeriod(day.date)
                        let value = dailyValues[day.date] ?? 0

                        if inPeriod {
                            ctx.fill(p, with: .color(periodColor.opacity(0.55)))
                            // 周期内叠加数值热力 (深色条纹感)
                            if value > 0 {
                                ctx.fill(p, with: .color(levelColor(for: day.date, maxValue: maxVal).opacity(0.85)))
                            }
                            ctx.stroke(p, with: .color(periodColor.opacity(0.9)), lineWidth: 1)
                        } else {
                            ctx.fill(p, with: .color(levelColor(for: day.date, maxValue: maxVal)))
                        }

                        if isToday {
                            ctx.stroke(p, with: .color(.slInk.opacity(0.85)), lineWidth: 1.6)
                        }
                        if day.date == hovered {
                            ctx.stroke(p, with: .color(.slInk.opacity(0.4)), lineWidth: 1.2)
                        }
                    }
                }
                .frame(
                    width: layout.width(cell: cell, gap: gap),
                    height: layout.height(cell: cell, gap: gap)
                )
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            hovered = dateAt(layout: layout, location: value.location, topPad: 26)
                        }
                        .onEnded { _ in }
                )
                .padding(6)
            }
            .overlay(alignment: .topTrailing) {
                if let h = hovered, let v = dailyValues[h] {
                    tooltip(date: h, value: v)
                        .padding(.top, 26)
                        .padding(.trailing, 10)
                }
            }
        }
    }

    private func dateAt(layout: HeatmapLayout, location: CGPoint, topPad: CGFloat) -> Date? {
        let col = Int((location.x - 6) / (cell + gap))
        let row = Int((location.y - topPad - 6) / (cell + gap))
        guard col >= 0, row >= 0 else { return nil }
        let idx = row + col * 7
        guard idx >= 0, idx < layout.cells.count else { return nil }
        return layout.cells[idx].date
    }

    private func tooltip(date: Date, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Format.date(date))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
            Text(Format.number(value))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.slPinkDeep)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.slPink.opacity(0.3), lineWidth: 1)
        )
    }

    private func levelColor(for date: Date, maxValue: Double) -> Color {
        let v = dailyValues[date] ?? 0
        guard v > 0 else { return levels[0] }
        let t = min(1.0, v / maxValue)
        let idx = 1 + Int(t * Double(Swift.max(levels.count - 2, 1)))
        return levels[min(idx, levels.count - 1)]
    }

    private func isInPeriod(_ date: Date) -> Bool {
        let d = cal.startOfDay(for: date)
        return periods.contains { p in
            let s = cal.startOfDay(for: p.start)
            let e = cal.startOfDay(for: p.end)
            return d >= s && d <= e
        }
    }
}

// MARK: - 布局计算

struct HeatmapLayout {
    struct DayCell { var date: Date; var column: Int; var row: Int }
    var cells: [DayCell] = []
    var weekCount: Int = 0
    var monthLabels: [(col: Int, label: String)] = []

    static func layout(year: Int, cal: Calendar) -> HeatmapLayout {
        guard let start = cal.date(from: DateComponents(year: year, month: 1, day: 1)) else {
            return HeatmapLayout()
        }
        let leading = (cal.component(.weekday, from: start) + 5) % 7  // Monday-first
        guard let firstCell = cal.date(byAdding: .day, value: -leading, to: start),
              let nextYear = cal.date(byAdding: .year, value: 1, to: start),
              let end = cal.date(byAdding: .day, value: -1, to: nextYear) else {
            return HeatmapLayout()
        }
        let daysInYear = cal.dateComponents([.day], from: start, to: end).day! + 1
        let total = leading + daysInYear
        let weekCount = (total + 6) / 7

        var cells: [DayCell] = []
        for i in 0..<(weekCount * 7) {
            if let date = cal.date(byAdding: .day, value: i, to: firstCell) {
                cells.append(DayCell(date: date, column: i / 7, row: i % 7))
            }
        }

        let monthF = DateFormatter()
        monthF.locale = Format.locale
        monthF.dateFormat = "M月"
        var labels: [(Int, String)] = []
        for m in 1...12 {
            if let d = cal.date(from: DateComponents(year: year, month: m, day: 1)) {
                let diff = cal.dateComponents([.day], from: firstCell, to: d).day ?? 0
                labels.append((diff / 7, monthF.string(from: d)))
            }
        }

        return HeatmapLayout(cells: cells, weekCount: weekCount, monthLabels: labels)
    }

    func width(cell: CGFloat, gap: CGFloat) -> CGFloat {
        max(CGFloat(weekCount) * (cell + gap) - gap, 0)
    }

    func height(cell: CGFloat, gap: CGFloat) -> CGFloat {
        26 + 7 * (cell + gap) - gap + 8
    }
}

// MARK: - 图例

struct HeatmapLegend: View {
    var levels: [Color] = YearHeatmapView.greenLevels
    var periodColor: Color = .slPinkDeep
    var lang: AppLanguage = .zh
    var showPeriod: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            Text(L10n.s(.heatmapLess, lang)).font(.caption2).foregroundStyle(.secondary)
            ForEach(0..<levels.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(levels[i])
                    .frame(width: 11, height: 11)
                    .overlay(RoundedRectangle(cornerRadius: 2.5).strokeBorder(.white.opacity(0.5), lineWidth: 0.5))
            }
            Text(L10n.s(.heatmapMore, lang)).font(.caption2).foregroundStyle(.secondary)
            if showPeriod {
                Spacer(minLength: 12)
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(periodColor.opacity(0.55))
                    .frame(width: 11, height: 11)
                    .overlay(RoundedRectangle(cornerRadius: 2.5).strokeBorder(periodColor.opacity(0.9), lineWidth: 1))
                Text(L10n.s(.periodRange, lang)).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}
