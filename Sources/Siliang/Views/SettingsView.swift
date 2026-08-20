import SwiftUI
import AppKit

// MARK: - 设置 v3

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var synced = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SL.gapXL) {
                header
                languageSection
                syncSection
                aboutSection
            }
            .padding(.horizontal, SL.gapXXL)
            .padding(.vertical, SL.gapXL)
            .frame(maxWidth: 1100, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(SLBackground())
    }

    private var header: some View {
        SLPageHeader(
            title: L10n.s(.settingsTitle, store.language),
            subtitle: L10n.s(.settingsSubtitle, store.language),
            mascot: .hello
        )
    }

    // MARK: 语言

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: SL.gapM) {
            HStack(spacing: 10) {
                SLIconBubble(systemName: "globe", color: .slGreenDeep, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.s(.language, store.language))
                        .font(.system(.headline, design: .rounded))
                    Text(L10n.s(.languageHint, store.language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Picker("", selection: languageBinding) {
                Text(L10n.s(.chinese, store.language)).tag(AppLanguage.zh)
                Text(L10n.s(.japanese, store.language)).tag(AppLanguage.ja)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 280)
            .labelsHidden()
        }
        .slCard()
    }

    // MARK: 同步

    private var syncSection: some View {
        VStack(alignment: .leading, spacing: SL.gapM) {
            HStack(spacing: 10) {
                SLIconBubble(systemName: "arrow.triangle.2.circlepath", color: .slPinkDeep, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.s(.syncFolder, store.language))
                        .font(.system(.headline, design: .rounded))
                    Text(L10n.s(.syncHint, store.language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                Label {
                    Text(store.syncFolderPath ?? L10n.s(.noSyncFolder, store.language))
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } icon: {
                    Image(systemName: store.syncFolderPath == nil ? "folder.badge.questionmark" : "folder.fill")
                        .foregroundStyle(store.syncFolderPath == nil ? Color.secondary : Color.slGreenDeep)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(L10n.s(.chooseFolder, store.language)) { chooseFolder() }
                    .buttonStyle(.bordered)

                Button {
                    store.syncAll()
                    synced = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { synced = false }
                } label: {
                    Label(synced ? L10n.s(.synced, store.language) : L10n.s(.syncNow, store.language),
                          systemImage: synced ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                }
                .buttonStyle(SLPrimaryButtonStyle(tint: .slGreenDeep))
            }
            .padding(SL.gapM)
            .background(
                RoundedRectangle(cornerRadius: SL.cornerM, style: .continuous)
                    .fill(.white.opacity(0.5))
            )

            Text("LWW + tombstone · \(L10n.s(.syncDesc, store.language))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .slCard()
    }

    // MARK: 关于

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: SL.gapM) {
            HStack(spacing: 12) {
                SiliangMascot(pose: .hello, size: 44, animated: false)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.s(.appName, store.language) + " · Siliang")
                        .font(.system(.headline, design: .rounded))
                    Text("v1.0.0 · macOS 14+")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .slCard()
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { store.language },
            set: { store.language = $0 }
        )
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = L10n.s(.chooseFolder, store.language)
        if panel.runModal() == .OK, let url = panel.url {
            store.setSyncFolder(url.path)
            store.syncAll()
        }
    }
}
