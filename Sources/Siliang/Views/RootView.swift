import SwiftUI

// MARK: - 页面定义

enum Page: String, CaseIterable, Identifiable, Hashable {
    case split, points, items, token, admin, settings
    var id: String { rawValue }

    func title(_ lang: AppLanguage) -> String {
        switch self {
        case .split: return L10n.s(.navSplit, lang)
        case .points: return L10n.s(.navPoints, lang)
        case .items: return L10n.s(.navItems, lang)
        case .token: return L10n.s(.navToken, lang)
        case .admin: return L10n.s(.navAdmin, lang)
        case .settings: return L10n.s(.navSettings, lang)
        }
    }

    var icon: String {
        switch self {
        case .split: return "person.2.wave.2.fill"
        case .points: return "star.fill"
        case .items: return "shippingbox.fill"
        case .token: return "key.horizontal.fill"
        case .admin: return "person.crop.circle.badge.checkmark"
        case .settings: return "gearshape.fill"
        }
    }

    var mascot: SiliangMascot.Pose {
        switch self {
        case .split: return .money
        case .points: return .star
        case .items: return .box
        case .token: return .computer
        case .admin: return .hello
        case .settings: return .hello
        }
    }
}

// MARK: - Root (登录分流)

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Group {
            if store.isLoggedIn {
                MainView()
            } else if store.isInitialized {
                LoginView()
            } else {
                OnboardingView()
            }
        }
    }
}

// MARK: - 主界面 v4: 原生 TabView (顶部标签, 点击可靠)

struct MainView: View {
    @Environment(AppStore.self) private var store
    @State private var selection: Page = .split

    private var pages: [Page] {
        var pages: [Page] = [.split, .points, .items, .token]
        if store.currentUser?.role == .admin { pages.append(.admin) }
        pages.append(.settings)
        return pages
    }

    var body: some View {
        ZStack {
            SLBackground()
                .allowsHitTesting(false)
            TabView(selection: $selection) {
                SplitView().tag(Page.split)
                    .tabItem { Label(Page.split.title(store.language), systemImage: Page.split.icon) }
                PointsView().tag(Page.points)
                    .tabItem { Label(Page.points.title(store.language), systemImage: Page.points.icon) }
                ItemsView().tag(Page.items)
                    .tabItem { Label(Page.items.title(store.language), systemImage: Page.items.icon) }
                TokenView().tag(Page.token)
                    .tabItem { Label(Page.token.title(store.language), systemImage: Page.token.icon) }
                if store.currentUser?.role == .admin {
                    AdminView().tag(Page.admin)
                        .tabItem { Label(Page.admin.title(store.language), systemImage: Page.admin.icon) }
                }
                SettingsView().tag(Page.settings)
                    .tabItem { Label(Page.settings.title(store.language), systemImage: Page.settings.icon) }
            }
            .tabViewStyle(.automatic)
        }
        .overlay(alignment: .topTrailing) {
            // 用户徽章 (右上角, 不拦截 TabView 点击)
            if let u = store.currentUser {
                Menu {
                    Text(u.username).font(.caption)
                    Text(u.role == .admin ? L10n.s(.adminRole, store.language) : L10n.s(.memberRole, store.language))
                        .font(.caption).foregroundStyle(.secondary)
                    Divider()
                    Button(role: .destructive) {
                        store.logout()
                    } label: {
                        Label(L10n.s(.logout, store.language), systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(u.role == .admin ? Color.slPinkDeep : Color.slGreenDeep)
                            .frame(width: 22, height: 22)
                            .overlay(
                                Text(String(u.username.prefix(1)).uppercased())
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            )
                        Text(u.username)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.slInk)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .contentShape(Capsule())
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .padding(.top, 44)
                .padding(.trailing, 16)
            }
        }
    }
}
