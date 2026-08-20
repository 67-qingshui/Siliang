import SwiftUI
import AppKit

private enum AdminSheet: Identifiable {
    case addUser, password(UserRecord)
    var id: String {
        switch self { case .addUser: return "add"; case .password(let u): return u.id.uuidString }
    }
}

// MARK: - 管理员 v3

struct AdminView: View {
    @Environment(AppStore.self) private var store

    @State private var activeSheet: AdminSheet?
    @State private var showKey = false
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SL.gapXL) {
                header
                recoveryKeySection
                usersSection
            }
            .padding(.horizontal, SL.gapXXL)
            .padding(.vertical, SL.gapXL)
            .frame(maxWidth: 1100, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(SLBackground())
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addUser: AddUserSheet()
            case .password(let u): ChangePasswordSheet(user: u)
            }
        }
    }

    private var header: some View {
        SLPageHeader(
            title: L10n.s(.adminTitle, store.language),
            subtitle: L10n.s(.adminSubtitle, store.language),
            mascot: .hello
        )
    }

    // MARK: 恢复密钥

    private var recoveryKeySection: some View {
        VStack(alignment: .leading, spacing: SL.gapM) {
            Text(L10n.s(.recoveryKey, store.language)).slSectionTitle()

            HStack(spacing: 14) {
                SiliangMascot(pose: .star, size: 40)
                Text(showKey ? store.recoveryKey : "•••• •••• •••• ••••")
                    .font(.system(.body, design: .monospaced).weight(.semibold))
                    .kerning(1)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    showKey.toggle()
                } label: {
                    Image(systemName: showKey ? "eye.slash" : "eye")
                }
                .buttonStyle(.borderless)
                .help(L10n.s(.showHide, store.language))

                Button(action: copyKey) {
                    Label(copied ? L10n.s(.copied, store.language) : L10n.s(.copyRecoveryKey, store.language),
                          systemImage: copied ? "checkmark.circle.fill" : "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .tint(copied ? .slGreenDeep : nil)

                Button(role: .destructive) {
                    _ = store.regenerateRecoveryKey()
                    showKey = true
                } label: {
                    Label(L10n.s(.regenerate, store.language), systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)
            }
            .padding(SL.gapL)
            .background(
                RoundedRectangle(cornerRadius: SL.cornerL, style: .continuous)
                    .fill(Color.slPink.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: SL.cornerL, style: .continuous)
                            .strokeBorder(Color.slPink.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .slCard()
    }

    // MARK: 用户管理

    private var usersSection: some View {
        VStack(alignment: .leading, spacing: SL.gapM) {
            HStack {
                Text(L10n.s(.usersTitle, store.language)).slSectionTitle()
                Spacer()
                Button {
                    activeSheet = .addUser
                } label: {
                    Label(L10n.s(.addUser, store.language), systemImage: "person.badge.plus")
                }
                .buttonStyle(.bordered)
            }

            if store.users.isEmpty {
                MascotEmptyState(message: L10n.s(.noData, store.language), pose: .empty)
            } else {
                ForEach(store.users) { user in
                    userRow(user)
                    if user.id != store.users.last?.id { Divider().opacity(0.4) }
                }
            }
        }
        .slCard()
    }

    private func userRow(_ user: UserRecord) -> some View {
        let isSelf = user.id == store.currentUser?.id
        return HStack(spacing: 12) {
            Circle()
                .fill(user.role == .admin ? Color.slPinkDeep : Color.slGreenDeep)
                .frame(width: 34, height: 34)
                .overlay(
                    Text(String(user.username.prefix(1)))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                )
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(user.username).font(.callout.weight(.semibold))
                    if isSelf {
                        Text(L10n.s(.you, store.language))
                            .slBadge(.slMuted)
                    }
                }
                Text(user.role == .admin ? L10n.s(.adminRole, store.language) : L10n.s(.memberRole, store.language))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Picker("", selection: roleBinding(user.id)) {
                Text(L10n.s(.adminRole, store.language)).tag(Role.admin)
                Text(L10n.s(.memberRole, store.language)).tag(Role.member)
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
            .disabled(isSelf)

            Button {
                activeSheet = .password(user)
            } label: {
                Image(systemName: "key")
            }
            .help(L10n.s(.changePassword, store.language))
            .buttonStyle(.borderless)

            Button {
                store.removeUser(id: user.id)
            } label: {
                Image(systemName: "trash").foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .disabled(isSelf)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: SL.cornerS, style: .continuous)
                .fill(.white.opacity(0.4))
        )
    }

    private func roleBinding(_ id: UUID) -> Binding<Role> {
        Binding(
            get: { store.users.first { $0.id == id }?.role ?? .member },
            set: { store.setRole(id: id, role: $0) }
        )
    }

    private func copyKey() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(store.recoveryKey, forType: .string)
        copied = true
    }
}

// MARK: - Sheets

struct AddUserSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var username = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var role: Role = .member
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                SiliangMascot(pose: .hello, size: 36)
                Text(L10n.s(.addUser, store.language))
                    .font(.system(.title3, design: .rounded).weight(.bold))
            }
            Form {
                TextField(L10n.s(.username, store.language), text: $username)
                SecureField(L10n.s(.password, store.language), text: $password)
                SecureField(L10n.s(.passwordConfirm, store.language), text: $passwordConfirm)
                Picker(L10n.s(.role, store.language), selection: $role) {
                    Text(L10n.s(.adminRole, store.language)).tag(Role.admin)
                    Text(L10n.s(.memberRole, store.language)).tag(Role.member)
                }
                .pickerStyle(.segmented)
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
        .padding(24).frame(width: 420)
    }

    private func save() {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty, !password.isEmpty else {
            error = L10n.s(.missingField, store.language)
            return
        }
        guard password == passwordConfirm else {
            error = L10n.s(.passwordMismatch, store.language)
            return
        }
        if store.addUser(username: username, password: password, role: role) {
            dismiss()
        } else {
            error = L10n.s(.userExists, store.language)
        }
    }
}

struct ChangePasswordSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let user: UserRecord
    @State private var newPassword = ""
    @State private var newPasswordConfirm = ""
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                SiliangMascot(pose: .receipt, size: 36)
                Text(L10n.s(.changePassword, store.language))
                    .font(.system(.title3, design: .rounded).weight(.bold))
            }
            Text(user.username).font(.callout).foregroundStyle(.secondary)
            SecureField(L10n.s(.newPassword, store.language), text: $newPassword)
                .textFieldStyle(.roundedBorder)
            SecureField(L10n.s(.passwordConfirm, store.language), text: $newPasswordConfirm)
                .textFieldStyle(.roundedBorder)

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
                    .disabled(newPassword.isEmpty || newPasswordConfirm.isEmpty)
            }
        }
        .padding(24).frame(width: 420)
    }

    private func save() {
        guard newPassword == newPasswordConfirm else {
            error = L10n.s(.passwordMismatch, store.language)
            return
        }
        store.changePassword(id: user.id, newPassword: newPassword)
        dismiss()
    }
}
