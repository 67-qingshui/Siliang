import SwiftUI

// MARK: - 司量 v3 设计系统
// 方向: 克制配色 + 毛玻璃 + 大圆角 + 精致层次
// 品牌: 樱花粉 × 抹茶绿 (低饱和高级感)

extension Color {
    // 品牌主色
    static let slPink      = Color(red: 0.95, green: 0.80, blue: 0.84)   // 樱花粉
    static let slPinkDeep  = Color(red: 0.86, green: 0.55, blue: 0.64)   // 深樱
    static let slGreen     = Color(red: 0.82, green: 0.90, blue: 0.80)   // 抹茶
    static let slGreenDeep = Color(red: 0.47, green: 0.66, blue: 0.48)   // 深抹茶

    // 语义色
    static let slIncome    = Color(red: 0.40, green: 0.64, blue: 0.44)
    static let slExpense   = Color(red: 0.85, green: 0.48, blue: 0.60)

    // 中性
    static let slInk       = Color(red: 0.24, green: 0.23, blue: 0.26)
    static let slMuted     = Color(red: 0.53, green: 0.51, blue: 0.55)
    static let slLine      = Color(red: 0.90, green: 0.89, blue: 0.90)
}

// MARK: - 间距 / 圆角

enum SL {
    static let gapXS: CGFloat = 4
    static let gapS: CGFloat = 8
    static let gapM: CGFloat = 12
    static let gapL: CGFloat = 18
    static let gapXL: CGFloat = 24
    static let gapXXL: CGFloat = 34

    static let cornerS: CGFloat = 10
    static let cornerM: CGFloat = 14
    static let cornerL: CGFloat = 20
    static let cornerXL: CGFloat = 28

    static let shadow = Color.black.opacity(0.05)
}

// MARK: - 背景 (柔和渐变)

struct SLBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.97, blue: 0.96),
                    Color(red: 0.98, green: 0.985, blue: 0.97)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            // 顶部两团柔和光晕 (不允许命中测试, 否则拦截点击)
            Circle()
                .fill(Color.slPink.opacity(0.30))
                .frame(width: 520, height: 520)
                .blur(radius: 110)
                .offset(x: -420, y: -300)
                .allowsHitTesting(false)
            Circle()
                .fill(Color.slGreen.opacity(0.28))
                .frame(width: 520, height: 520)
                .blur(radius: 110)
                .offset(x: 420, y: -320)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

// MARK: - 卡片

struct SLCardStyle: ViewModifier {
    var padding: CGFloat = SL.gapL
    var corner: CGFloat = SL.cornerL

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(.white.opacity(0.62))
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .strokeBorder(.white.opacity(0.9), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.045), radius: 18, x: 0, y: 6)
    }
}

extension View {
    func slCard(padding: CGFloat = SL.gapL, corner: CGFloat = SL.cornerL) -> some View {
        modifier(SLCardStyle(padding: padding, corner: corner))
    }

    func slSectionTitle() -> some View {
        self.font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.slMuted)
            .textCase(.uppercase)
            .kerning(0.6)
    }
}

// MARK: - 顶部标签按钮样式 (ButtonStyle 内做 background, 保证 hit-testing 正常)

struct SLTabButtonStyle: ButtonStyle {
    var isSelected: Bool
    var tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? .white : Color.slMuted)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(
                    isSelected
                        ? AnyShapeStyle(LinearGradient(colors: [tint, tint.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                        : AnyShapeStyle(Color.white.opacity(0.55))
                )
            )
            .overlay(
                Capsule().strokeBorder(isSelected ? .white.opacity(0.25) : Color.slLine, lineWidth: 1)
                    .allowsHitTesting(false)
            )
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - 主按钮 (渐变胶囊)

struct SLPrimaryButtonStyle: ButtonStyle {
    var tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [tint.opacity(0.92), tint.opacity(0.78)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            )
            .foregroundStyle(.white)
            .shadow(color: tint.opacity(configuration.isPressed ? 0.15 : 0.30),
                    radius: 6, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - 徽章

struct SLBadgeStyle: ViewModifier {
    var color: Color
    func body(content: Content) -> some View {
        content
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.13)))
            .overlay(Capsule().strokeBorder(color.opacity(0.25), lineWidth: 1))
    }
}

extension View {
    func slBadge(_ color: Color) -> some View {
        modifier(SLBadgeStyle(color: color))
    }
}

// MARK: - 数字 / 图标

extension Text {
    func slAmount(_ size: CGFloat = 24, _ color: Color = .primary) -> some View {
        self.font(.system(size: size, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(color)
    }
}

struct SLIconBubble: View {
    var systemName: String
    var color: Color
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(Circle().fill(color.opacity(0.13)))
    }
}

// MARK: - 页面大标题

struct SLPageHeader: View {
    var title: String
    var subtitle: String
    var mascot: SiliangMascot.Pose? = nil

    var body: some View {
        HStack(spacing: 14) {
            if let mascot {
                SiliangMascot(pose: mascot, size: 52, animated: false)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .tracking(-0.3)
                Text(subtitle)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
        }
    }
}
