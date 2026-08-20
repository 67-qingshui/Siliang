import SwiftUI

private enum SplitSheet: String, Identifiable {
    case expense, repayment, member
    var id: String { rawValue }
}

// MARK: - 割り勘 主页 v3

struct SplitView: View {
    @Environment(AppStore.self) private var store

    @State private var month = Date()
    @State private var activeSheet: SplitSheet?
    @State private var search = ""
    @State private var filterDirection: Direction? = nil

    private var settlement: SettlementEngine.Result {
        SettlementEngine.compute(
            expenses: store.expenses,
            repayments: store.repayments,
            members: store.members
        )
    }

    private var dailyAmounts: [Date: Double] {
        var map: [Date: Double] = [:]
        let cal = Format.calendar
        for e in store.expenses {
            let sign: Double = e.direction == .income ? 1 : -1
            let day = cal.startOfDay(for: e.date)
            map[day, default: 0] += sign * e.amount
        }
        return map
    }

    private var monthInOut: (income: Double, expense: Double) {
        let start = Format.calendar.date(from: Format.calendar.dateComponents([.year, .month], from: month))!
        var income = 0.0, expense = 0.0
        for e in store.expenses where Format.calendar.isDate(e.date, equalTo: start, toGranularity: .month) {
            if e.direction == .income { income += e.amount } else { expense += e.amount }
        }
        return (income, expense)
    }

    private var filteredRows: [Row] {
        var rows = (store.expenses.map { e -> Row in
            Row(id: e.id, title: e.title, subtitle: "\(memberName(e.paidBy)) · \(Format.date(e.date))",
                amount: (e.direction == .income ? 1 : -1) * e.amount, date: e.date, kind: .expense)
        } + store.repayments.map { r -> Row in
            Row(id: r.id, title: "\(memberName(r.from)) → \(memberName(r.to))",
                subtitle: L10n.s(.splitNewRepayment, store.language) + " · " + Format.date(r.date),
                amount: r.amount, date: r.date, kind: .repayment)
        }).sorted { $0.date > $1.date }

        if let dir = filterDirection {
            rows = rows.filter {
                guard $0.kind == .expense else { return false }
                return ($0.amount >= 0) == (dir == .income)
            }
        }
        if !search.isEmpty {
            rows = rows.filter { $0.title.localizedCaseInsensitiveContains(search) || $0.subtitle.localizedCaseInsensitiveContains(search) }
        }
        return rows
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SL.gapXL) {
                header
                summaryStrip
                settlementSection
                bottomGrid
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
            case .expense: NewExpenseSheet()
            case .repayment: NewRepaymentSheet()
            case .member: AddMemberSheet()
            }
        }
    }

    // MARK: 页头

    private var header: some View {
        SLPageHeader(
            title: L10n.s(.splitTitle, store.language),
            subtitle: L10n.s(.splitSubtitle, store.language),
            mascot: .money
        )
        .overlay(alignment: .trailing) {
            HStack(spacing: SL.gapS) {
                Button {
                    activeSheet = .member
                } label: {
                    Label(L10n.s(.addMember, store.language), systemImage: "person.badge.plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    activeSheet = .repayment
                } label: {
                    Label(L10n.s(.splitNewRepayment, store.language), systemImage: "arrow.left.arrow.right.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    activeSheet = .expense
                } label: {
                    Label(L10n.s(.splitNew, store.language), systemImage: "plus")
                }
                .buttonStyle(SLPrimaryButtonStyle(tint: .slPinkDeep))
                .controlSize(.large)
            }
        }
    }

    // MARK: 本月概览

    private var summaryStrip: some View {
        let (income, expense) = monthInOut
        return HStack(spacing: SL.gapL) {
            summaryCard(title: L10n.s(.monthIncome, store.language),
                        value: income, color: .slIncome, icon: "arrow.down.circle.fill")
            summaryCard(title: L10n.s(.monthExpense, store.language),
                        value: expense, color: .slExpense, icon: "arrow.up.circle.fill")
            summaryCard(title: L10n.s(.monthBalance, store.language),
                        value: income - expense, color: income - expense >= 0 ? .slGreenDeep : .slPinkDeep,
                        icon: "chart.pie.fill")
        }
    }

    private func summaryCard(title: String, value: Double, color: Color, icon: String) -> some View {
        HStack(spacing: 14) {
            SLIconBubble(systemName: icon, color: color, size: 42)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(Format.yen(value))
                    .slAmount(24, color)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .slCard(padding: SL.gapL, corner: SL.cornerM)
    }

    // MARK: 结算

    private var settlementSection: some View {
        VStack(alignment: .leading, spacing: SL.gapM) {
            HStack {
                Text(L10n.s(.splitSettlement, store.language)).slSectionTitle()
                Spacer()
                Text(L10n.s(.settlementHint, store.language))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if settlement.transfers.isEmpty && settlement.nets.values.allSatisfy({ abs($0) < 0.01 }) {
                MascotEmptyState(
                    message: L10n.s(.noData, store.language),
                    pose: .money,
                    actionTitle: L10n.s(.splitNew, store.language)
                ) {
                    activeSheet = .expense
                }
            } else {
                HStack(alignment: .top, spacing: SL.gapXL) {
                    transfersPanel
                    netsPanel
                }
            }
        }
        .slCard()
    }

    private var transfersPanel: some View {
        VStack(alignment: .leading, spacing: SL.gapS) {
            Text(L10n.s(.oweTitle, store.language))
                .font(.system(.subheadline, design: .rounded).weight(.bold))
            if settlement.transfers.isEmpty {
                Text(L10n.s(.noData, store.language))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(settlement.transfers) { t in
                    HStack(spacing: 10) {
                        avatarDot(memberName(t.debtor), color: .slExpense)
                        Text(memberName(t.debtor))
                            .font(.callout.weight(.semibold))
                            .lineLimit(1)
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.slMuted)
                        avatarDot(memberName(t.creditor), color: .slIncome)
                        Text(memberName(t.creditor))
                            .font(.callout.weight(.semibold))
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(Format.yen(t.amount))
                            .slAmount(17, .slPinkDeep)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: SL.cornerS, style: .continuous)
                            .fill(Color.slPink.opacity(0.10))
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var netsPanel: some View {
        VStack(alignment: .leading, spacing: SL.gapS) {
            Text(L10n.s(.netTitle, store.language))
                .font(.system(.subheadline, design: .rounded).weight(.bold))
            let nets = settlement.nets.filter { abs($0.value) >= 0.01 }.sorted { $0.value > $1.value }
            if nets.isEmpty {
                Text(L10n.s(.noData, store.language))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(nets.indices, id: \.self) { i in
                    let id = nets[i].key
                    let net = nets[i].value
                    HStack(spacing: 10) {
                        Text(memberName(id))
                            .font(.callout.weight(.medium))
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer(minLength: 8)
                        Text(net > 0 ? L10n.s(.receivable, store.language) : L10n.s(.toPay, store.language))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(Format.yen(abs(net)))
                            .slAmount(16, net > 0 ? .slIncome : .slExpense)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 5)
                    if i < nets.count - 1 { Divider().opacity(0.4) }
                }
            }
        }
        .padding(.leading, SL.gapL)
        .overlay(alignment: .leading) {
            Rectangle().fill(Color.slLine.opacity(0.6)).frame(width: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func avatarDot(_ name: String, color: Color) -> some View {
        Text(String(name.prefix(1)))
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(Circle().fill(color))
    }

    // MARK: 底部两栏 (成员 | 月历)

    private var bottomGrid: some View {
        HStack(alignment: .top, spacing: SL.gapXL) {
            membersSection
            calendarSection
        }
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.s(.membersTitle, store.language)).slSectionTitle()
            if store.members.isEmpty {
                Text(L10n.s(.noMembers, store.language))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(store.members) { m in
                        HStack(spacing: 6) {
                            Circle().fill(Color.slIncome.opacity(0.7)).frame(width: 7, height: 7)
                            Text(m.name).font(.callout.weight(.medium)).lineLimit(1)
                            Button {
                                store.removeMember(id: m.id)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                            .help(L10n.s(.delete, store.language))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(Color.slPink.opacity(0.10))
                                .overlay(Capsule().strokeBorder(Color.slPink.opacity(0.28), lineWidth: 1))
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .slCard()
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.s(.splitCalendar, store.language)).slSectionTitle()
                Spacer()
                monthStepper
            }
            MonthAmountCalendarView(
                month: month,
                dailyAmounts: dailyAmounts,
                accent: .slPinkDeep,
                lang: store.language
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .slCard()
    }

    private var monthStepper: some View {
        HStack(spacing: 8) {
            Button {
                month = Format.calendar.date(byAdding: .month, value: -1, to: month) ?? month
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.borderless)

            Text(Format.monthYear(month)).font(.callout.monospacedDigit())

            Button {
                month = Format.calendar.date(byAdding: .month, value: 1, to: month) ?? month
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.borderless)
        }
    }

    // MARK: 明细

    private var recordsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: SL.gapM) {
                Text(L10n.s(.recordList, store.language)).slSectionTitle()
                Spacer()
                Picker("", selection: $filterDirection) {
                    Text(L10n.s(.all, store.language)).tag(Optional<Direction>.none)
                    Text(L10n.s(.income, store.language)).tag(Optional<Direction>.some(.income))
                    Text(L10n.s(.expense, store.language)).tag(Optional<Direction>.some(.expense))
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 220)

                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField(L10n.s(.search, store.language), text: $search)
                        .textFieldStyle(.plain)
                        .font(.callout)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(.white.opacity(0.7))
                        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(Color.slLine, lineWidth: 1))
                )
                .frame(width: 200)
            }

            let rows = filteredRows
            if rows.isEmpty {
                MascotEmptyState(
                    message: search.isEmpty ? L10n.s(.noData, store.language) : L10n.s(.noSearchResult, store.language),
                    pose: .empty
                )
            } else {
                ForEach(rows) { row in
                    HStack(spacing: 12) {
                        SLIconBubble(systemName: rowIcon(row), color: rowColor(row), size: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.title)
                                .font(.callout.weight(.medium))
                                .lineLimit(1)
                            Text(row.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text(Format.sign(row.amount) + Format.yen(abs(row.amount)))
                            .slAmount(15, rowColor(row))
                            .lineLimit(1)
                            .layoutPriority(1)
                        Button {
                            if row.kind == .repayment { store.removeRepayment(id: row.id) }
                            else { store.removeExpense(id: row.id) }
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
                    if row.id != rows.last?.id { Divider().opacity(0.4) }
                }
            }
        }
        .slCard()
    }

    private func rowIcon(_ row: Row) -> String {
        switch row.kind {
        case .repayment: return "arrow.left.arrow.right"
        case .expense: return row.amount >= 0 ? "arrow.down" : "arrow.up"
        }
    }

    private func rowColor(_ row: Row) -> Color {
        switch row.kind {
        case .repayment: return .slGreenDeep
        case .expense: return row.amount >= 0 ? .slIncome : .slExpense
        }
    }

    private func memberName(_ id: UUID) -> String {
        store.memberName(id, deletedFallback: "·")
    }

    private struct Row: Identifiable {
        enum Kind { case expense, repayment }
        let id: UUID
        let title: String
        let subtitle: String
        let amount: Double
        let date: Date
        let kind: Kind
    }
}

// MARK: - 记一笔 sheet v3

struct NewExpenseSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var amount = ""
    @State private var direction: Direction = .expense
    @State private var paidBy: UUID?
    @State private var splitMode: SplitMode = .equal
    @State private var selected: Set<UUID> = []
    @State private var customAmounts: [UUID: String] = [:]
    @State private var date = Date()
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: SL.gapM) {
            HStack(spacing: 10) {
                SiliangMascot(pose: .money, size: 36)
                Text(L10n.s(.splitNew, store.language))
                    .font(.system(.title2, design: .rounded).weight(.bold))
            }

            formBody

            if let error {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button(L10n.s(.cancel, store.language)) { dismiss() }.keyboardShortcut(.cancelAction)
                Button(L10n.s(.save, store.language)) { save() }
                    .buttonStyle(SLPrimaryButtonStyle(tint: .slPinkDeep))
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 480)
        .onAppear {
            if paidBy == nil { paidBy = store.members.first?.id }
            selected = Set(store.members.map(\.id))
        }
    }

    private var formBody: some View {
        Form {
            TextField(L10n.s(.titlePlaceholder, store.language), text: $title)
            HStack {
                TextField(L10n.s(.amount, store.language), text: $amount)
                    .onChange(of: amount) { _, newValue in
                        amount = Format.sanitizeNumberInput(newValue)
                    }
                Picker("", selection: $direction) {
                    Text(L10n.s(.expense, store.language)).tag(Direction.expense)
                    Text(L10n.s(.income, store.language)).tag(Direction.income)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 150)
            }

            Picker(L10n.s(.payer, store.language), selection: $paidBy) {
                ForEach(store.members) { m in Text(m.name).tag(Optional(m.id)) }
            }

            Picker(L10n.s(.splitMode, store.language), selection: $splitMode) {
                Text(L10n.s(.equal, store.language)).tag(SplitMode.equal)
                Text(L10n.s(.custom, store.language)).tag(SplitMode.custom)
            }
            .pickerStyle(.segmented)

            DatePicker(L10n.s(.date, store.language), selection: $date, displayedComponents: .date)

            participantEditor
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var participantEditor: some View {
        if store.members.isEmpty {
            Text(L10n.s(.addMemberFirst, store.language)).foregroundStyle(.secondary)
        } else {
            Section(L10n.s(.participants, store.language)) {
                ForEach(store.members) { m in
                    HStack {
                        Toggle(isOn: binding(for: m.id)) {
                            Text(m.name)
                                .font(.callout.weight(m.id == paidBy ? .semibold : .regular))
                            if m.id == paidBy {
                                Text(L10n.s(.payerTag, store.language))
                                    .slBadge(.slPinkDeep)
                            }
                        }
                        .toggleStyle(.checkbox)

                        Spacer()

                        if splitMode == .custom {
                            TextField("¥", text: bindingAmount(for: m.id))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)
                                .disabled(!selected.contains(m.id))
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
        }
    }

    private func binding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { selected.contains(id) },
            set: { on in
                if on { selected.insert(id) }
                else { selected.remove(id) }
            }
        )
    }

    private func bindingAmount(for id: UUID) -> Binding<String> {
        Binding(
            get: { customAmounts[id] ?? "" },
            set: { customAmounts[id] = Format.sanitizeNumberInput($0) }
        )
    }

    private func save() {
        guard let total = Double(amount.replacingOccurrences(of: ",", with: "")), total > 0 else {
            error = L10n.s(.amountInvalid, store.language)
            return
        }
        guard let payer = paidBy else {
            error = L10n.s(.addMemberFirst, store.language)
            return
        }
        let participantIds = selected.isEmpty ? [payer] : Array(selected)

        var shares: [SplitShare] = []
        switch splitMode {
        case .equal:
            shares = participantIds.map { SplitShare(memberId: $0, amount: total / Double(max(participantIds.count, 1))) }
        case .custom:
            shares = participantIds.compactMap { id -> SplitShare? in
                let v = Double(customAmounts[id]?.replacingOccurrences(of: ",", with: "") ?? "") ?? 0
                return v > 0 ? SplitShare(memberId: id, amount: v) : nil
            }
            let sum = shares.reduce(0) { $0 + $1.amount }
            if abs(sum - total) > 0.01 {
                error = L10n.s(.customSumMismatch, store.language) + Format.yen(total) + " ≠ " + Format.yen(sum)
                return
            }
        }

        let e = SplitExpense(
            title: title.trimmingCharacters(in: .whitespaces).isEmpty ? L10n.s(.none, store.language) : title,
            amount: total,
            direction: direction,
            paidBy: payer,
            splitMode: splitMode,
            shares: shares.isEmpty ? [SplitShare(memberId: payer, amount: total)] : shares,
            date: date
        )
        store.addExpense(e)
        dismiss()
    }
}

// MARK: - 登记还款 sheet v3

struct NewRepaymentSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var from: UUID?
    @State private var to: UUID?
    @State private var amount = ""
    @State private var date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: SL.gapM) {
            HStack(spacing: 10) {
                SiliangMascot(pose: .receipt, size: 36)
                Text(L10n.s(.splitNewRepayment, store.language))
                    .font(.system(.title2, design: .rounded).weight(.bold))
            }
            Form {
                Picker(L10n.s(.repaymentFrom, store.language), selection: $from) {
                    ForEach(store.members) { m in Text(m.name).tag(Optional(m.id)) }
                }
                Picker(L10n.s(.repaymentTo, store.language), selection: $to) {
                    ForEach(store.members) { m in Text(m.name).tag(Optional(m.id)) }
                }
                TextField(L10n.s(.repaymentAmount, store.language), text: $amount)
                    .onChange(of: amount) { _, newValue in
                        amount = Format.sanitizeNumberInput(newValue)
                    }
                DatePicker(L10n.s(.date, store.language), selection: $date, displayedComponents: .date)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button(L10n.s(.cancel, store.language)) { dismiss() }.keyboardShortcut(.cancelAction)
                Button(L10n.s(.save, store.language)) {
                    if let f = from, let t = to, let v = Double(amount.replacingOccurrences(of: ",", with: "")), v > 0 {
                        store.addRepayment(Repayment(from: f, to: t, amount: v, date: date))
                        dismiss()
                    }
                }
                .buttonStyle(SLPrimaryButtonStyle(tint: .slGreenDeep))
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 440)
        .onAppear {
            if from == nil { from = store.members.first?.id }
            if to == nil { to = store.members.dropFirst().first?.id ?? store.members.first?.id }
        }
    }
}

// MARK: - 添加成员 sheet v3

struct AddMemberSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                SiliangMascot(pose: .hello, size: 36)
                Text(L10n.s(.addMember, store.language))
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
        .padding(24)
        .frame(width: 380)
    }

    private func save() {
        if store.addMember(name: name) { dismiss() }
    }
}
