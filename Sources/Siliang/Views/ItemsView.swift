import SwiftUI

private enum ItemsSheet: Identifiable {
    case new, edit(Item)
    var id: String {
        switch self { case .new: return "new"; case .edit(let i): return i.id.uuidString }
    }
}

// MARK: - 物品使用 v3

struct ItemsView: View {
    @Environment(AppStore.self) private var store

    @State private var activeSheet: ItemsSheet?
    @State private var year = Format.calendar.component(.year, from: Date())
    @State private var filterStatus: ItemStatus? = nil
    @State private var filterCategory: String? = nil
    @State private var search = ""

    private var categories: [String] {
        var order: [String] = []
        var seen = Set<String>()
        for i in store.items where !seen.contains(i.category) {
            seen.insert(i.category)
            order.append(i.category)
        }
        return order
    }

    private var periods: [(start: Date, end: Date)] {
        store.items.map { item in
            (start: item.startDate, end: item.endDate ?? Date())
        }
    }

    private var filteredItems: [Item] {
        var items = store.items
        if let fs = filterStatus { items = items.filter { $0.status == fs } }
        if let fc = filterCategory { items = items.filter { $0.category == fc } }
        if !search.isEmpty {
            items = items.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.category.localizedCaseInsensitiveContains(search) }
        }
        return items
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SL.gapXL) {
                header
                summaryStrip
                calendarSection
                itemsSection
            }
            .padding(.horizontal, SL.gapXXL)
            .padding(.vertical, SL.gapXL)
            .frame(maxWidth: 1100, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(SLBackground())
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .new: ItemEditorSheet(item: nil)
            case .edit(let item): ItemEditorSheet(item: item)
            }
        }
    }

    private var header: some View {
        SLPageHeader(
            title: L10n.s(.itemsTitle, store.language),
            subtitle: L10n.s(.itemsSubtitle, store.language),
            mascot: .box
        )
        .overlay(alignment: .trailing) {
            Button {
                activeSheet = .new
            } label: {
                Label(L10n.s(.itemsNew, store.language), systemImage: "plus")
            }
            .buttonStyle(SLPrimaryButtonStyle(tint: .slPinkDeep))
            .controlSize(.large)
        }
    }

    private var summaryStrip: some View {
        let activeCount = store.items.filter { $0.status == .active }.count
        let finishedCount = store.items.count - activeCount
        return HStack(spacing: SL.gapL) {
            summaryCard(title: L10n.s(.totalItems, store.language),
                        value: "\(store.items.count)", icon: "shippingbox.fill", color: .slGreenDeep)
            summaryCard(title: L10n.s(.active, store.language),
                        value: "\(activeCount)", icon: "play.circle.fill", color: .slPinkDeep)
            summaryCard(title: L10n.s(.finished, store.language),
                        value: "\(finishedCount)", icon: "checkmark.circle.fill", color: .slMuted)
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
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .slCard(padding: SL.gapL, corner: SL.cornerM)
    }

    // MARK: 区间热力图

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: SL.gapS) {
            HStack {
                Text(L10n.s(.itemsCalendar, store.language)).slSectionTitle()
                Spacer()
                yearStepper
            }
            YearHeatmapView(
                year: year,
                periods: periods,
                levels: YearHeatmapView.pinkLevels,
                periodColor: .slPinkDeep
            )
            HeatmapLegend(levels: YearHeatmapView.pinkLevels, periodColor: .slPinkDeep, lang: store.language, showPeriod: true)
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

    // MARK: 物品列表

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: SL.gapS) {
            HStack(spacing: SL.gapM) {
                Text(L10n.s(.itemList, store.language)).slSectionTitle()
                Spacer()
                Picker("", selection: $filterStatus) {
                    Text(L10n.s(.all, store.language)).tag(Optional<ItemStatus>.none)
                    Text(L10n.s(.active, store.language)).tag(Optional<ItemStatus>.some(.active))
                    Text(L10n.s(.finished, store.language)).tag(Optional<ItemStatus>.some(.finished))
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 200)

                if !categories.isEmpty {
                    Menu {
                        Button(L10n.s(.all, store.language)) { filterCategory = nil }
                        ForEach(categories, id: \.self) { c in
                            Button(c) { filterCategory = c }
                        }
                    } label: {
                        Label(filterCategory ?? L10n.s(.category, store.language), systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
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

            let items = filteredItems
            if items.isEmpty {
                MascotEmptyState(
                    message: search.isEmpty ? L10n.s(.noData, store.language) : L10n.s(.noSearchResult, store.language),
                    pose: .box
                )
            } else {
                ForEach(items) { item in
                    itemRow(item)
                    if item.id != items.last?.id { Divider().opacity(0.4) }
                }
            }
        }
        .slCard()
    }

    private func itemRow(_ item: Item) -> some View {
        let active = item.status == .active
        return HStack(spacing: 12) {
            SLIconBubble(systemName: itemIcon(item.category), color: active ? .slPinkDeep : .slMuted, size: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(item.category)
                        .slBadge(.slMuted)
                    Text("\(Format.date(item.startDate)) → \(item.endDate.map { Format.date($0) } ?? L10n.s(.toToday, store.language))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                Text(durationText(from: item.startDate, to: item.endDate ?? Date()))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(active ? Color.slPinkDeep : Color.slMuted)
                Text(active ? L10n.s(.active, store.language) : L10n.s(.finished, store.language))
                    .slBadge(active ? .slGreenDeep : .slMuted)
            }

            Button {
                activeSheet = .edit(item)
            } label: {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.7))
            }
            .buttonStyle(.plain)
            .help(L10n.s(.edit, store.language))

            Button {
                store.removeItem(id: item.id)
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

    private func itemIcon(_ category: String) -> String {
        switch category {
        case "订阅", "サブスク": return "repeat.circle"
        case "工具", "ツール": return "wrench.and.screwdriver"
        case "电子", "デジタル": return "desktopcomputer"
        case "生活": return "house"
        default: return "shippingbox"
        }
    }

    private func durationText(from start: Date, to end: Date) -> String {
        let cal = Format.calendar
        let comps = cal.dateComponents([.year, .month, .day], from: cal.startOfDay(for: start), to: cal.startOfDay(for: end))
        var parts: [String] = []
        if let y = comps.year, y > 0 { parts.append("\(y)" + L10n.s(.yearUnit, store.language)) }
        if let m = comps.month, m > 0 { parts.append("\(m)" + L10n.s(.monthUnit, store.language)) }
        if let d = comps.day, d > 0 { parts.append("\(d)" + L10n.s(.dayUnit, store.language)) }
        let value = parts.isEmpty ? "0" + L10n.s(.dayUnit, store.language) : parts.joined()
        return L10n.s(.usedDuration, store.language) + " " + value
    }
}

// MARK: - Editor (add / edit an item)

struct ItemEditorSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let item: Item?

    @State private var name = ""
    @State private var category = ""
    @State private var startDate = Date()
    @State private var status: ItemStatus = .active
    @State private var endDate = Date()
    @State private var error: String?

    private let suggestions = ["订阅", "工具", "电子", "生活", "运动", "学习"]

    var body: some View {
        VStack(alignment: .leading, spacing: SL.gapM) {
            HStack(spacing: 10) {
                SiliangMascot(pose: .box, size: 36)
                Text(item == nil ? L10n.s(.itemsNew, store.language) : L10n.s(.edit, store.language))
                    .font(.system(.title2, design: .rounded).weight(.bold))
            }
            Form {
                TextField(L10n.s(.name, store.language), text: $name)
                TextField(L10n.s(.category, store.language), text: $category)
                if category.isEmpty {
                    Section(L10n.s(.categorySuggest, store.language)) {
                        FlowLayout(spacing: 6) {
                            ForEach(suggestions, id: \.self) { s in
                                Button {
                                    category = s
                                } label: {
                                    Text(s)
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(Capsule().fill(Color.slPink.opacity(0.14)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                DatePicker(L10n.s(.startTime, store.language), selection: $startDate, displayedComponents: .date)
                Picker("", selection: $status) {
                    Text(L10n.s(.active, store.language)).tag(ItemStatus.active)
                    Text(L10n.s(.finished, store.language)).tag(ItemStatus.finished)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                if status == .finished {
                    DatePicker(L10n.s(.endTime, store.language), selection: $endDate, displayedComponents: .date)
                }
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
                    .buttonStyle(SLPrimaryButtonStyle(tint: .slPinkDeep))
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24).frame(width: 460)
        .onAppear {
            if let item {
                name = item.name
                category = item.category
                startDate = item.startDate
                if let e = item.endDate { endDate = e }
                status = item.endDate == nil ? .active : .finished
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            error = L10n.s(.nameRequired, store.language)
            return
        }
        if status == .finished && endDate < startDate {
            error = L10n.s(.endBeforeStart, store.language)
            return
        }
        let category = category.trimmingCharacters(in: .whitespaces).isEmpty ? L10n.s(.none, store.language) : category
        if let item {
            var updated = item
            updated.name = trimmed
            updated.category = category
            updated.startDate = startDate
            updated.endDate = status == .finished ? endDate : nil
            store.updateItem(updated)
        } else {
            store.addItem(Item(
                name: trimmed, category: category, startDate: startDate,
                endDate: status == .finished ? endDate : nil
            ))
        }
        dismiss()
    }
}
