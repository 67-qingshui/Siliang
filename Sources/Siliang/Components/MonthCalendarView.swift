import SwiftUI

// MARK: - 月历收支 v2
// 格子写当天收支金额, 今日高亮, 顶部当月合计.
struct MonthAmountCalendarView: View {
    var month: Date
    var dailyAmounts: [Date: Double] = [:]
    var accent: Color = .slGreenDeep
    var lang: AppLanguage = .zh

    private var cal: Calendar { Format.calendar }

    var body: some View {
        let start = cal.date(from: cal.dateComponents([.year, .month], from: month))!
        let firstWeekday = (cal.component(.weekday, from: start) + 5) % 7  // Monday-first
        let days = cal.range(of: .day, in: .month, for: start)!.count
        let symbols = ["一", "二", "三", "四", "五", "六", "日"]
        let total = monthlyTotal(start: start, days: days)
        let today = cal.startOfDay(for: Date())

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(Format.monthYear(start))
                    .font(.system(.headline, design: .rounded).weight(.bold))
                Spacer()
                HStack(spacing: 6) {
                    Text(L10n.s(.monthTotal, lang))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(signedMoney(total))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(total > 0 ? Color.slIncome : (total < 0 ? Color.slExpense : Color.slMuted))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule().fill((total > 0 ? Color.slIncome : Color.slExpense).opacity(0.1)))
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
                ForEach(0..<7, id: \.self) { i in
                    Text(symbols[i])
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(i >= 5 ? accent.opacity(0.8) : Color.slMuted)
                }
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Color.clear.frame(height: 46)
                }
                ForEach(1...days, id: \.self) { d in
                    let date = cal.date(byAdding: .day, value: d - 1, to: start)!
                    let v = dailyAmounts[cal.startOfDay(for: date)] ?? 0
                    dayCell(day: d, value: v, isToday: date == today, accent: accent)
                }
            }
        }
    }

    private func dayCell(day: Int, value: Double, isToday: Bool, accent: Color) -> some View {
        VStack(spacing: 2) {
            ZStack {
                if isToday {
                    Circle()
                        .fill(accent.opacity(0.85))
                        .frame(width: 20, height: 20)
                }
                Text("\(day)")
                    .font(.system(size: 11, weight: isToday ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isToday ? .white : .primary)
            }
            .frame(height: 20)

            if value != 0 {
                Text(signedShort(value))
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(value > 0 ? Color.slIncome : Color.slExpense)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill((value > 0 ? Color.slIncome : Color.slExpense).opacity(0.09))
                    )
            } else {
                Text(" ")
                    .font(.system(size: 8.5))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
        .contentShape(Rectangle())
    }

    private func monthlyTotal(start: Date, days: Int) -> Double {
        let end = cal.date(byAdding: .day, value: days, to: start)!
        return dailyAmounts.reduce(0) { partial, pair in
            let d = cal.startOfDay(for: pair.key)
            return (d >= start && d < end) ? partial + pair.value : partial
        }
    }

    private func signedMoney(_ v: Double) -> String {
        return Format.sign(v) + Format.yen(abs(v))
    }

    private func signedShort(_ v: Double) -> String {
        let a = abs(v)
        let sign = v > 0 ? "+" : "-"
        if a >= 1_000_000 { return sign + String(format: "%.1fM", a / 1_000_000) }
        if a >= 10_000 { return sign + String(format: "%.0f万", a / 10_000) }
        return sign + Format.int(Int(a.rounded()))
    }
}
