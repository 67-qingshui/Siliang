import SwiftUI

private enum PointsSheet: String, Identifiable {
    case record, plan
    var id: String { rawValue }
}

// MARK: - 积分记录 v3

struct PointsView: View {
    @Environment(AppStore.self) private var store

    @State private var year = Format.calendar.component(.year, from: Date())
    @State private var activeSheet: PointsSheet?
    @State private var filterPlan: UUID? = nil
    @State private var search = ""

    private var dailyNet: [Date: Double] {
        var m: [Date: Double] = [:]
        let cal = Format.calendar
        for p in store.points where !p.isPending {
            if let fp = filterPlan, p.planId != fp { continue }
            let sign: Double = p.kind == .earned ? 1 : -1
            m[cal.startOfDay(for: p.date), default: 0] += sign * p.amount
        }
        return m
    }

    private var filteredRecords: [PointsRecord] {
        var recs = store.points
        if let fp = filterPlan { recs = recs.filter { $0.planId == fp } }
        if !search.isEmpty {
            recs = recs.filter { $0.memo.localizedCaseInsensitiveContains(search) }
        }
        return recs
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SL.gapXL) {
                header
                balanceSection
                calendarSection
                recordsSection
            }
            .padding(.horizontal, SL.gapXXL)
            .padding(.vertical, SL.gapXL)
            .frame(maxWidth: 1100, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(SLBackground())
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .record: NewPointsSheet()
            case .plan: AddPlanSheet()
            }
        }
    }

    private var header: some View {
        SLPageHeader(
            title: L10n.s(.pointsTitle, store.language),
            subtitle: L10n.s(.pointsSubtitle, store.language),
            mascot: .star
        )
        .overlay(alignment: .trailing) {
            HStack(spacing: SL.gapS) {
                Button {
                    activeSheet = .plan
                } label: {
                    Label(L10n.s(.addPlan, store.language), systemImage: "rectangle.stack.badge.plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    activeSheet = .record
                } label: {
                    Label(L10n.s(.pointsNew, store.language), systemImage: "plus")
                }
                .buttonStyle(SLPrimaryButtonStyle(tint: .slGreenDeep))
                .controlSize(.large)
            }
        }
    }

    // MARK: 余额面板

    private var balanceSection: some View {
        VStack(alignment: .leading, spacing: SL.gapM) {
            Text(L10n.s(.pointsBalance, store.language)).slSectionTitle()

            if store.plans.isEmpty {
                MascotEmptyState(
                    message: L10n.s(.noData, store.language),
                    pose: .star,
                    actionTitle: L10n.s(.addPlan, store.language)
                ) {
                    activeSheet = .plan
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: SL.gapL), GridItem(.flexible(), spacing: SL.gapL)],
                          spacing: SL.gapL) {
                    ForEach(store.plans) { plan in
                        planBalanceCard(plan)
                    }
                }
            }
        }
        .slCard()
    }

    private func planBalanceCard(_ plan: PointsPlan) -> some View {
        let recs = store.points.filter { $0.planId == plan.id }
        let balance = recs.filter { !$0.isPending }.reduce(0) { $0 + ($1.kind == .earned ? $1.amount : -$1.amount) }
        let pending = recs.filter { $0.isPending }.reduce(0) { $0 + ($1.kind == .earned ? $1.amount : -$1.amount) }

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(filterPlan == plan.id ? Color.slGreenDeep : Color.slGreen.opacity(0.6))
                    .frame(width: 8, height: 8)
                Text(plan.name)
                    .font(.system(.headline, design: .rounded))
                    .lineLimit(1)
                Spacer()
                Button {
                    filterPlan = (filterPlan == plan.id ? nil : plan.id)
                } label: {
                    Image(systemName: filterPlan == plan.id ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundStyle(filterPlan == plan.id ? Color.slGreenDeep : Color.slMuted)
                }
                .buttonStyle(.plain)
                .help(L10n.s(.filterPlan, store.language))
                Button {
                    store.removePlan(id: plan.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .help(L10n.s(.delete, store.language))
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(Format.number(balance))
                    .slAmount(26, balance >= 0 ? .slGreenDeep : .slExpense)
                Text(L10n.s(.pointsUnit, store.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if pending != 0 {
                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("\(L10n.s(.pending, store.language)) \(pending > 0 ? "+" : "")\(Format.number(pending))")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(pending > 0 ? Color.slGreenDeep : Color.slExpense)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill((pending > 0 ? Color.slGreenDeep : Color.slExpense).opacity(0.12)))
            } else {
                Text(L10n.s(.noPending, store.language))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
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
                Text(L10n.s(.pointsCalendar, store.language)).slSectionTitle()
                Spacer()
                yearStepper
            }
            YearHeatmapView(year: year, dailyValues: dailyNet, levels: YearHeatmapView.greenLevels)
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
                if filterPlan != nil {
                    Button {
                        filterPlan = nil
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
                    pose: .star
                )
            } else {
                ForEach(recs) { r in
                    pointsRow(r)
                    if r.id != recs.last?.id { Divider().opacity(0.4) }
                }
            }
        }
        .slCard()
    }

    private func pointsRow(_ r: PointsRecord) -> some View {
        let sign: Double = r.kind == .earned ? 1 : -1
        let color = r.kind == .earned ? Color.slIncome : Color.slExpense

        return HStack(spacing: 12) {
            SLIconBubble(systemName: r.kind == .earned ? "plus" : "minus", color: color, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(planName(r.planId)).font(.callout.weight(.semibold))
                    if r.isPending {
                        Text(L10n.s(.pending, store.language))
                            .slBadge(.slPinkDeep)
                    }
                }
                Text((r.memo.isEmpty ? "" : r.memo + " · ") + Format.date(r.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if r.isPending, let e = r.expectedDate {
                    Text(L10n.s(.expectedDate, store.language) + " " + Format.date(e))
                        .font(.caption2)
                        .foregroundStyle(Color.slPinkDeep)
                }
            }
            Spacer()
            Text("\(sign > 0 ? "+" : "")\(Format.number(r.amount))")
                .slAmount(16, color)
            Button {
                store.removePoints(id: r.id)
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
                .fill(.white.opacity(r.isPending ? 0.2 : 0.4))
        )
    }

    private func planName(_ id: UUID) -> String {
        store.plans.first { $0.id == id }?.name ?? L10n.s(.deleted, store.language)
    }
}

// MARK: - Sheets

struct AddPlanSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                SiliangMascot(pose: .star, size: 36)
                Text(L10n.s(.addPlan, store.language))
                    .font(.system(.title3, design: .rounded).weight(.bold))
            }
            TextField(L10n.s(.name, store.language), text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit { save() }
            HStack {
                Spacer()
                Button(L10n.s(.cancel, store.language)) { dismiss() }.keyboardShortcut(.cancelAction)
                Button(L10n.s(.save, store.language)) { save() }
                    .buttonStyle(SLPrimaryButtonStyle(tint: .slGreenDeep))
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24).frame(width: 380)
    }

    private func save() {
        if store.addPlan(name: name) != nil { dismiss() }
    }
}

struct NewPointsSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var planId: UUID?
    @State private var kind: PointsKind = .earned
    @State private var amount = ""
    @State private var isPending = false
    @State private var expectedDate = Date()
    @State private var date = Date()
    @State private var memo = ""
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: SL.gapM) {
            HStack(spacing: 10) {
                SiliangMascot(pose: .star, size: 36)
                Text(L10n.s(.pointsNew, store.language))
                    .font(.system(.title2, design: .rounded).weight(.bold))
            }
            Form {
                Picker(L10n.s(.plan, store.language), selection: $planId) {
                    ForEach(store.plans) { p in Text(p.name).tag(Optional(p.id)) }
                }
                Picker(L10n.s(.pointsNew, store.language), selection: $kind) {
                    Text(L10n.s(.earned, store.language)).tag(PointsKind.earned)
                    Text(L10n.s(.spent, store.language)).tag(PointsKind.spent)
                }
                .pickerStyle(.segmented)
                TextField(L10n.s(.amount, store.language), text: $amount)
                    .onChange(of: amount) { _, newValue in
                        amount = Format.sanitizeNumberInput(newValue)
                    }
                Toggle(L10n.s(.pending, store.language), isOn: $isPending)
                if isPending {
                    DatePicker(L10n.s(.expectedDate, store.language), selection: $expectedDate, displayedComponents: .date)
                }
                DatePicker(L10n.s(.date, store.language), selection: $date, displayedComponents: .date)
                TextField(L10n.s(.memo, store.language), text: $memo)
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
        .onAppear { if planId == nil { planId = store.plans.first?.id } }
    }

    private func save() {
        guard let pid = planId else {
            error = L10n.s(.addPlanFirst, store.language)
            return
        }
        guard let v = Double(amount.replacingOccurrences(of: ",", with: "")), v > 0 else {
            error = L10n.s(.amountInvalid, store.language)
            return
        }
        let r = PointsRecord(
            planId: pid, kind: kind, amount: v, isPending: isPending,
            expectedDate: isPending ? expectedDate : nil, date: date, memo: memo
        )
        store.addPoints(r)
        dismiss()
    }
}
