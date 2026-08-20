import SwiftUI

// MARK: - Token 使用 v3

struct TokenView: View {
    @Environment(AppStore.self) private var store

    @State private var year = Format.calendar.component(.year, from: Date())
    @State private var showNew = false
    @State private var filterScenario: String? = nil
    @State private var search = ""

    private var dailyActivity: [Date: Double] {
        var m: [Date: Double] = [:]
        let cal = Format.calendar
        for t in store.tokens {
            if let fs = filterScenario, t.scenario != fs { continue }
            m[cal.startOfDay(for: t.date), default: 0] += Double(t.inputTokens + t.outputTokens)
        }
        return m
    }

    private var scenarios: [String] {
        var order: [String] = []
        var seen = Set<String>()
        for t in store.tokens {
            if !seen.contains(t.scenario) { seen.insert(t.scenario); order.append(t.scenario) }
        }
        return order
    }

    private var filteredRecords: [TokenRecord] {
        var recs = store.tokens
        if let fs = filterScenario { recs = recs.filter { $0.scenario == fs } }
        if !search.isEmpty {
            recs = recs.filter {
                $0.scenario.localizedCaseInsensitiveContains(search) ||
                $0.model.localizedCaseInsensitiveContains(search) ||
                $0.maskedKey.localizedCaseInsensitiveContains(search)
            }
        }
        return recs
    }

    private var totalCost: Double { store.tokens.reduce(0) { $0 + $1.cost } }
    private var totalTokens: Int { store.tokens.reduce(0) { $0 + $1.inputTokens + $1.outputTokens } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SL.gapXL) {
                header
                summaryStrip
                groupedSection
                calendarSection
                recordsSection
            }
            .padding(.horizontal, SL.gapXXL)
            .padding(.vertical, SL.gapXL)
            .frame(maxWidth: 1100, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(SLBackground())
        .sheet(isPresented: $showNew) { NewTokenSheet() }
    }

    private var header: some View {
        SLPageHeader(
            title: L10n.s(.tokenTitle, store.language),
            subtitle: L10n.s(.tokenSubtitle, store.language),
            mascot: .computer
        )
        .overlay(alignment: .trailing) {
            Button {
                showNew = true
            } label: {
                Label(L10n.s(.tokenNew, store.language), systemImage: "plus")
            }
            .buttonStyle(SLPrimaryButtonStyle(tint: .slGreenDeep))
            .controlSize(.large)
        }
    }

    private var summaryStrip: some View {
        HStack(spacing: SL.gapL) {
            summaryCard(title: L10n.s(.totalTokens, store.language),
                        value: Format.int(totalTokens), icon: "number", color: .slGreenDeep)
            summaryCard(title: L10n.s(.totalCost, store.language),
                        value: Format.yen(totalCost), icon: "yensign.circle.fill", color: .slPinkDeep)
            summaryCard(title: L10n.s(.scenarioCount, store.language),
                        value: "\(scenarios.count)", icon: "square.stack.3d.up.fill", color: .slMuted)
        }
    }

    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 14) {
            SLIconBubble(systemName: icon, color: color, size: 42)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(value)
                    .slAmount(24, color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .slCard(padding: SL.gapL, corner: SL.cornerM)
    }

    // MARK: 按场景分组

    private var groupedSection: some View {
        VStack(alignment: .leading, spacing: SL.gapM) {
            Text(L10n.s(.tokenGrouped, store.language)).slSectionTitle()

            if scenarios.isEmpty {
                MascotEmptyState(
                    message: L10n.s(.noData, store.language),
                    pose: .computer,
                    actionTitle: L10n.s(.tokenNew, store.language)
                ) {
                    showNew = true
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: SL.gapL), GridItem(.flexible(), spacing: SL.gapL)],
                          spacing: SL.gapL) {
                    ForEach(scenarios, id: \.self) { scenario in
                        scenarioCard(scenario)
                    }
                }
            }
        }
        .slCard()
    }

    private func scenarioCard(_ scenario: String) -> some View {
        let recs = store.tokens.filter { $0.scenario == scenario }
        let totalIn = recs.reduce(0) { $0 + $1.inputTokens }
        let totalOut = recs.reduce(0) { $0 + $1.outputTokens }
        let totalCost = recs.reduce(0.0) { $0 + $1.cost }
        let models = Array(Set(recs.map(\.model))).sorted()
        let isFiltered = filterScenario == scenario

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(isFiltered ? Color.slGreenDeep : Color.slGreen.opacity(0.6))
                    .frame(width: 8, height: 8)
                Text(scenario)
                    .font(.system(.headline, design: .rounded))
                    .lineLimit(1)
                Spacer()
                Button {
                    filterScenario = (isFiltered ? nil : scenario)
                } label: {
                    Image(systemName: isFiltered ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundStyle(isFiltered ? Color.slGreenDeep : Color.slMuted)
                }
                .buttonStyle(.plain)
                .help(L10n.s(.filterScenario, store.language))
            }

            FlowLayout(spacing: 6) {
                ForEach(models, id: \.self) { m in
                    Text(m)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(.white.opacity(0.6)))
                        .overlay(Capsule().strokeBorder(Color.slLine, lineWidth: 1))
                }
            }

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Format.int(totalIn)) in · \(Format.int(totalOut)) out")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Text(L10n.s(.recordCount, store.language) + " \(recs.count)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Text(Format.yen(totalCost))
                    .slAmount(20, .slGreenDeep)
            }
        }
        .padding(SL.gapL)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: SL.cornerL, style: .continuous)
                .fill(LinearGradient(colors: [Color.slGreen.opacity(0.14), .white.opacity(0.6)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: SL.cornerL, style: .continuous)
                        .strokeBorder(.white.opacity(0.8), lineWidth: 1)
                )
        )
        .shadow(color: SL.shadow, radius: 10, x: 0, y: 4)
    }

    // MARK: 日历

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: SL.gapS) {
            HStack {
                Text(L10n.s(.tokenCalendar, store.language)).slSectionTitle()
                if let fs = filterScenario {
                    Text("· \(fs)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.slGreenDeep)
                }
                Spacer()
                yearStepper
            }
            YearHeatmapView(year: year, dailyValues: dailyActivity, levels: YearHeatmapView.greenLevels)
            HeatmapLegend(levels: YearHeatmapView.greenLevels, lang: store.language, showPeriod: false)
        }
        .slCard()
    }

    private var yearStepper: some View {
        HStack(spacing: 8) {
            Button { year -= 1 } label: { Image(systemName: "chevron.left") }.buttonStyle(.borderless)
            Text("\(year)")
                .font(.callout.monospacedDigit().weight(.semibold))
                .frame(minWidth: 48)
            Button { year += 1 } label: { Image(systemName: "chevron.right") }.buttonStyle(.borderless)
        }
    }

    // MARK: 明细

    private var recordsSection: some View {
        VStack(alignment: .leading, spacing: SL.gapS) {
            HStack(spacing: SL.gapM) {
                Text(L10n.s(.recordList, store.language)).slSectionTitle()
                Spacer()
                if filterScenario != nil {
                    Button {
                        filterScenario = nil
                    } label: {
                        Label(L10n.s(.clearFilter, store.language), systemImage: "xmark.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").font(.caption).foregroundStyle(.secondary)
                    TextField(L10n.s(.search, store.language), text: $search)
                        .textFieldStyle(.plain)
                        .font(.callout)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(.white.opacity(0.7))
                        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(Color.slLine, lineWidth: 1))
                )
                .frame(width: 180)
            }

            let recs = filteredRecords
            if recs.isEmpty {
                MascotEmptyState(
                    message: search.isEmpty ? L10n.s(.noData, store.language) : L10n.s(.noSearchResult, store.language),
                    pose: .computer
                )
            } else {
                ForEach(recs) { t in
                    tokenRow(t)
                    if t.id != recs.last?.id { Divider().opacity(0.4) }
                }
            }
        }
        .slCard()
    }

    private func tokenRow(_ t: TokenRecord) -> some View {
        HStack(spacing: 12) {
            SLIconBubble(systemName: "key.horizontal", color: .slGreenDeep, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(t.scenario) · \(t.model)")
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                Text("\(L10n.s(.apiKey, store.language)): \(t.maskedKey) · \(Format.date(t.date))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(Format.int(t.inputTokens)) / \(Format.int(t.outputTokens))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Text(Format.yen(t.cost))
                .slAmount(15, .slGreenDeep)

            Button {
                store.removeToken(id: t.id)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
            .help(L10n.s(.delete, store.language))
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 6)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: SL.cornerS, style: .continuous)
                .fill(.white.opacity(0.4))
        )
    }
}

// MARK: - 记一笔 sheet v3

struct NewTokenSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var scenario = ""
    @State private var model = ""
    @State private var apiKey = ""
    @State private var input = ""
    @State private var output = ""
    @State private var cost = ""
    @State private var date = Date()
    @State private var error: String?

    private var scenarioSuggestions: [String] {
        var order: [String] = []
        var seen = Set<String>()
        for t in store.tokens where !seen.contains(t.scenario) {
            seen.insert(t.scenario)
            order.append(t.scenario)
        }
        return order
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SL.gapM) {
            HStack(spacing: 10) {
                SiliangMascot(pose: .computer, size: 36)
                Text(L10n.s(.tokenNew, store.language))
                    .font(.system(.title2, design: .rounded).weight(.bold))
            }
            Form {
                TextField(L10n.s(.scenario, store.language) + " *", text: $scenario)
                if scenario.isEmpty, !scenarioSuggestions.isEmpty {
                    Section(L10n.s(.recentScenarios, store.language)) {
                        FlowLayout(spacing: 6) {
                            ForEach(scenarioSuggestions, id: \.self) { s in
                                Button {
                                    scenario = s
                                } label: {
                                    Text(s)
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(Capsule().fill(Color.slGreen.opacity(0.16)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                TextField(L10n.s(.model, store.language) + " *", text: $model)
                SecureField(L10n.s(.apiKey, store.language), text: $apiKey)
                HStack {
                    TextField(L10n.s(.inputTokens, store.language), text: $input)
                        .onChange(of: input) { _, v in input = Format.sanitizeNumberInput(v) }
                    TextField(L10n.s(.outputTokens, store.language), text: $output)
                        .onChange(of: output) { _, v in output = Format.sanitizeNumberInput(v) }
                }
                TextField(L10n.s(.cost, store.language), text: $cost)
                    .onChange(of: cost) { _, v in cost = Format.sanitizeNumberInput(v) }
                DatePicker(L10n.s(.date, store.language), selection: $date, displayedComponents: .date)
            }
            .formStyle(.grouped)

            if let error {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button(L10n.s(.cancel, store.language)) { dismiss() }.keyboardShortcut(.cancelAction)
                Button(L10n.s(.save, store.language)) { save() }
                    .buttonStyle(SLPrimaryButtonStyle(tint: .slGreenDeep))
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24).frame(width: 480)
    }

    private func save() {
        let s = scenario.trimmingCharacters(in: .whitespaces)
        let m = model.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty, !m.isEmpty else {
            error = L10n.s(.missingField, store.language)
            return
        }
        let inputV = Int(input) ?? 0
        let outputV = Int(output) ?? 0
        guard inputV > 0 || outputV > 0 else {
            error = L10n.s(.tokenCountInvalid, store.language)
            return
        }
        let costV = Double(cost.replacingOccurrences(of: ",", with: "")) ?? 0

        store.addToken(TokenRecord(
            scenario: s, model: m, apiKey: apiKey,
            inputTokens: inputV, outputTokens: outputV, cost: costV, date: date
        ))
        dismiss()
    }
}

// Simple flow layout for chips/tags.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
