import SwiftUI
import AppKit

// MARK: - 登录 v3

struct LoginView: View {
    @Environment(AppStore.self) private var store

    @State private var username = ""
    @State private var password = ""
    @State private var error: String?
    @State private var showReset = false

    var body: some View {
        AuthShell {
            VStack(spacing: 24) {
                SiliangMascot(pose: .hello, size: 96, animated: false)
                VStack(spacing: 4) {
                    Text(L10n.s(.appName, store.language))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .tracking(-1)
                    Text("SILIANG")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .kerning(5)
                        .textCase(.uppercase)
                }

                VStack(spacing: 12) {
                    TextField(L10n.s(.username, store.language), text: $username)
                        .textFieldStyle(SLTextFieldStyle(icon: "person"))
                        .textContentType(.username)

                    SecureField(L10n.s(.password, store.language), text: $password)
                        .textFieldStyle(SLTextFieldStyle(icon: "lock"))
                        .onSubmit { attemptLogin() }

                    if let error {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .transition(.opacity)
                    }

                    Button(action: attemptLogin) {
                        Text(L10n.s(.loginSubmit, store.language))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SLPrimaryButtonStyle(tint: .slPinkDeep))
                    .controlSize(.large)
                    .disabled(username.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty)

                    Button(L10n.s(.forgotPassword, store.language)) {
                        showReset = true
                    }
                    .buttonStyle(.link)
                    .foregroundStyle(Color.slMuted)
                    .font(.callout)
                }
                .frame(maxWidth: 320)
            }
            .padding(.vertical, 12)
        }
        .sheet(isPresented: $showReset) {
            ResetView()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: error != nil)
    }

    private func attemptLogin() {
        if store.login(username: username.trimmingCharacters(in: .whitespaces), password: password) {
            error = nil
        } else {
            error = L10n.s(.loginError, store.language)
        }
    }
}

// MARK: - 首次启动 v3

struct OnboardingView: View {
    @Environment(AppStore.self) private var store

    @State private var username = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var recoveryKey: String?
    @State private var copied = false
    @State private var error: String?

    var body: some View {
        AuthShell {
            if let key = recoveryKey {
                recoveryKeyCard(key)
            } else {
                form
            }
        }
    }

    private var form: some View {
        VStack(spacing: 20) {
            SiliangMascot(pose: .hello, size: 96, animated: false)
            VStack(spacing: 4) {
                Text(L10n.s(.appName, store.language))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .tracking(-1)
                Text(L10n.s(.onboardSubtitle, store.language))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                TextField(L10n.s(.username, store.language), text: $username)
                    .textFieldStyle(SLTextFieldStyle(icon: "person"))
                SecureField(L10n.s(.password, store.language), text: $password)
                    .textFieldStyle(SLTextFieldStyle(icon: "lock"))
                SecureField(L10n.s(.passwordConfirm, store.language), text: $passwordConfirm)
                    .textFieldStyle(SLTextFieldStyle(icon: "lock.fill"))

                if let error {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button(action: createAdmin) {
                    Text(L10n.s(.createAndLogin, store.language))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SLPrimaryButtonStyle(tint: .slGreenDeep))
                .controlSize(.large)
                .disabled(username.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty || passwordConfirm.isEmpty)
            }
            .frame(maxWidth: 320)
        }
        .padding(.vertical, 8)
    }

    private func recoveryKeyCard(_ key: String) -> some View {
        VStack(spacing: 16) {
            SiliangMascot(pose: .star, size: 88, animated: false)
            VStack(spacing: 4) {
                Text(L10n.s(.recoveryKeyTitle, store.language))
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text(L10n.s(.recoveryKeyHint, store.language))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            Text(key)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .kerning(2)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.slGreen.opacity(0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.slGreenDeep.opacity(0.3), lineWidth: 1)
                        )
                )
                .textSelection(.enabled)

            HStack(spacing: 12) {
                Button(action: copy) {
                    Label(copied ? L10n.s(.copied, store.language) : L10n.s(.copyRecoveryKey, store.language),
                          systemImage: copied ? "checkmark.circle.fill" : "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .tint(copied ? .slGreenDeep : nil)

                Button(action: { store.logout() }) {
                    Text(L10n.s(.continueToApp, store.language))
                }
                .buttonStyle(SLPrimaryButtonStyle(tint: .slGreenDeep))
            }
        }
        .padding(.vertical, 8)
    }

    private func createAdmin() {
        let u = username.trimmingCharacters(in: .whitespaces)
        guard !u.isEmpty, !password.isEmpty else {
            error = L10n.s(.missingField, store.language)
            return
        }
        guard password == passwordConfirm else {
            error = L10n.s(.passwordMismatch, store.language)
            return
        }
        let key = store.createAdmin(username: u, password: password)
        recoveryKey = key
    }

    private func copy() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(store.recoveryKey, forType: .string)
        copied = true
    }
}

// MARK: - 忘记密码 v3

struct ResetView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var key = ""
    @State private var newPassword = ""
    @State private var newPasswordConfirm = ""
    @State private var message: String?
    @State private var isError = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                SiliangMascot(pose: .receipt, size: 40)
                Text(L10n.s(.resetTitle, store.language))
                    .font(.system(.title2, design: .rounded).weight(.bold))
            }
            Text(L10n.s(.resetHint, store.language))
                .font(.callout)
                .foregroundStyle(.secondary)

            TextField(L10n.s(.recoverKey, store.language), text: $key)
                .textFieldStyle(SLTextFieldStyle(icon: "key"))
                .font(.system(.body, design: .monospaced))

            SecureField(L10n.s(.newPassword, store.language), text: $newPassword)
                .textFieldStyle(SLTextFieldStyle(icon: "lock"))

            SecureField(L10n.s(.passwordConfirm, store.language), text: $newPasswordConfirm)
                .textFieldStyle(SLTextFieldStyle(icon: "lock.fill"))

            if let message {
                Label(message, systemImage: isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(isError ? Color.red : Color.slGreenDeep)
            }

            HStack {
                Button(L10n.s(.cancel, store.language)) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.s(.resetSubmit, store.language)) { doReset() }
                    .buttonStyle(SLPrimaryButtonStyle(tint: .slPinkDeep))
                    .keyboardShortcut(.defaultAction)
                    .disabled(key.isEmpty || newPassword.isEmpty || newPasswordConfirm.isEmpty)
            }
        }
        .padding(28)
        .frame(width: 420)
    }

    private func doReset() {
        guard newPassword == newPasswordConfirm else {
            message = L10n.s(.passwordMismatch, store.language)
            isError = true
            return
        }
        if store.resetPassword(recoveryKey: key, newPassword: newPassword) {
            message = L10n.s(.resetDone, store.language)
            isError = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
        } else {
            message = L10n.s(.resetInvalid, store.language)
            isError = true
        }
    }
}

// MARK: - 输入框样式 (带图标)

struct SLTextFieldStyle: TextFieldStyle {
    var icon: String

    func _body(configuration: TextField<Self._Label>) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 16)
            configuration
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.white.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(Color.slLine, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 认证外壳 v3

struct AuthShell<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.96, blue: 0.95),
                    Color(red: 0.98, green: 0.985, blue: 0.97)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.slPink.opacity(0.32))
                .frame(width: 460, height: 460)
                .blur(radius: 100)
                .offset(x: -400, y: -280)
                .allowsHitTesting(false)
            Circle()
                .fill(Color.slGreen.opacity(0.30))
                .frame(width: 460, height: 460)
                .blur(radius: 100)
                .offset(x: 400, y: 300)
                .allowsHitTesting(false)

            content
                .padding(44)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .strokeBorder(.white.opacity(0.7), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.08), radius: 32, x: 0, y: 14)
        }
    }
}
