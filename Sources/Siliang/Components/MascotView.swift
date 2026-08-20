import SwiftUI

// MARK: - Irasutoya 风格插画小人 (手绘矢量)
// 画风: 粗黑描边 + 圆润造型 + 豆豆眼 + 腮红 + 纯色填充
// 全局替换 logo / 空状态 / 登录页插画

struct SiliangMascot: View {
    enum Pose {
        case hello          // 打招呼 (logo)
        case money          // 记账 / 数钱
        case receipt        // 拿收据 (割り勘)
        case star           // 积分
        case box            // 物品 / 箱子
        case computer       // Token / 电脑
        case empty          // 空状态 (摊手)
    }

    var pose: Pose = .hello
    var size: CGFloat = 96
    var animated: Bool = false

    @State private var bounce = false

    private var scale: CGFloat { size / 100 }

    var body: some View {
        ZStack {
            // 底座阴影
            Ellipse()
                .fill(Color.black.opacity(0.08))
                .frame(width: size * 0.72, height: size * 0.1)
                .offset(y: size * 0.42)

            Canvas { ctx, _ in
                draw(ctx: &ctx)
            }
            .frame(width: size, height: size)
            .scaleEffect(animated && bounce ? 1.04 : 1)
            .animation(animated ? .spring(response: 0.4, dampingFraction: 0.6).repeatForever(autoreverses: true) : nil, value: bounce)
        }
        .onAppear { if animated { bounce = true } }
    }

    // MARK: 绘制

    private func draw(ctx: inout GraphicsContext) {
        let S = scale
        let skin = Color(red: 1.0, green: 0.87, blue: 0.76)
        let ink = Color(red: 0.22, green: 0.20, blue: 0.20)
        let blush = Color(red: 0.98, green: 0.62, blue: 0.62).opacity(0.65)
        let shirt = Color(red: 0.95, green: 0.82, blue: 0.87)   // 樱花粉衣
        let shirtDeep = Color(red: 0.88, green: 0.62, blue: 0.72)

        func stroke(_ p: Path, _ w: CGFloat = 2.2) {
            ctx.stroke(p, with: .color(ink), lineWidth: w * S)
        }
        func fillStroke(_ p: Path, _ c: Color, _ w: CGFloat = 2.2) {
            ctx.fill(p, with: .color(c))
            ctx.stroke(p, with: .color(ink), lineWidth: w * S)
        }

        // ---- 道具 (先画在身体后面) ----
        drawProp(ctx: ctx, S: S, ink: ink, fillStroke: fillStroke)

        // ---- 身体 ----
        let body = Path { p in
            p.addRoundedRect(in: CGRect(x: 34 * S, y: 60 * S, width: 32 * S, height: 26 * S), cornerSize: CGSize(width: 10 * S, height: 10 * S))
        }
        fillStroke(body, shirt, 2.4)

        // 衣领 V
        let collar = Path { p in
            p.move(to: CGPoint(x: 50 * S, y: 60 * S))
            p.addLine(to: CGPoint(x: 43 * S, y: 70 * S))
            p.addLine(to: CGPoint(x: 57 * S, y: 70 * S))
            p.closeSubpath()
        }
        ctx.fill(collar, with: .color(shirtDeep.opacity(0.5)))

        // ---- 手 ----
        drawArms(ctx: ctx, S: S, ink: ink, skin: skin, fillStroke: fillStroke)

        // ---- 头 ----
        let head = Path(ellipseIn: CGRect(x: 30 * S, y: 14 * S, width: 40 * S, height: 36 * S))
        fillStroke(head, skin, 2.4)

        // 头发 (刘海)
        let hair = Path { p in
            p.addArc(center: CGPoint(x: 50 * S, y: 30 * S), radius: 18 * S,
                     startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
            p.addLine(to: CGPoint(x: 50 * S, y: 30 * S))
            p.closeSubpath()
        }
        ctx.fill(hair, with: .color(ink))
        ctx.stroke(hair, with: .color(ink), lineWidth: 2.2 * S)

        // 呆毛
        let ahoge = Path { p in
            p.move(to: CGPoint(x: 52 * S, y: 17 * S))
            p.addQuadCurve(to: CGPoint(x: 58 * S, y: 8 * S),
                           control: CGPoint(x: 62 * S, y: 14 * S))
            p.addQuadCurve(to: CGPoint(x: 56 * S, y: 16 * S),
                           control: CGPoint(x: 56 * S, y: 12 * S))
        }
        ctx.stroke(ahoge, with: .color(ink), lineWidth: 2.0 * S)

        // 眼睛 (豆豆眼)
        for ex in [42.0, 58.0] {
            let eye = Path(ellipseIn: CGRect(x: (ex - 2.4) * S, y: 32 * S, width: 4.8 * S, height: 6.2 * S))
            ctx.fill(eye, with: .color(ink))
        }

        // 腮红
        for bx in [33.0, 61.0] {
            let b = Path(ellipseIn: CGRect(x: bx * S, y: 38 * S, width: 7 * S, height: 4.4 * S))
            ctx.fill(b, with: .color(blush))
        }

        // 嘴 (微笑弧)
        let mouth = Path { p in
            p.move(to: CGPoint(x: 45 * S, y: 42 * S))
            p.addQuadCurve(to: CGPoint(x: 55 * S, y: 42 * S),
                           control: CGPoint(x: 50 * S, y: 46 * S))
        }
        ctx.stroke(mouth, with: .color(ink), lineWidth: 1.8 * S)
    }

    private func drawArms(ctx: GraphicsContext, S: CGFloat, ink: Color, skin: Color, fillStroke: (Path, Color, CGFloat) -> Void) {
        // GraphicsContext.stroke 不支持 style 参数, 用 StrokeStyle 包装 lineWidth
        func roundStroke(_ p: Path, _ w: CGFloat) {
            ctx.stroke(p, with: .color(ink), lineWidth: w * S)
        }

        switch pose {
        case .hello:
            // 右手举起打招呼
            let arm = Path { p in
                p.move(to: CGPoint(x: 66 * S, y: 64 * S))
                p.addLine(to: CGPoint(x: 76 * S, y: 52 * S))
                p.addLine(to: CGPoint(x: 80 * S, y: 50 * S))
            }
            roundStroke(arm, 4.4)
            let hand = Path(ellipseIn: CGRect(x: 76 * S, y: 45 * S, width: 9 * S, height: 8 * S))
            fillStroke(hand, skin, 2.0)
            // 左手下垂
            let arm2 = Path { p in
                p.move(to: CGPoint(x: 34 * S, y: 66 * S))
                p.addLine(to: CGPoint(x: 28 * S, y: 76 * S))
            }
            roundStroke(arm2, 4.4)

        case .empty, .money, .receipt, .star, .box, .computer:
            // 双手在两侧
            let armL = Path { p in
                p.move(to: CGPoint(x: 34 * S, y: 66 * S))
                p.addLine(to: CGPoint(x: 27 * S, y: 76 * S))
            }
            roundStroke(armL, 4.2)
            let armR = Path { p in
                p.move(to: CGPoint(x: 66 * S, y: 66 * S))
                p.addLine(to: CGPoint(x: 73 * S, y: 76 * S))
            }
            roundStroke(armR, 4.2)
        }
    }

    private func drawProp(ctx: GraphicsContext, S: CGFloat, ink: Color, fillStroke: (Path, Color, CGFloat) -> Void) {
        let yellow = Color(red: 0.98, green: 0.85, blue: 0.35)
        let green = Color(red: 0.72, green: 0.88, blue: 0.66)
        let blue = Color(red: 0.70, green: 0.84, blue: 0.96)
        let orange = Color(red: 0.98, green: 0.72, blue: 0.45)
        let cream = Color(red: 0.98, green: 0.96, blue: 0.90)

        switch pose {
        case .money:
            // 手中金币
            let coins: [(dx: CGFloat, row: Int)] = [(52, 0), (64, 1), (58, 0)]
            for coinSpec in coins {
                let dx = coinSpec.dx
                let y = 44.0 + Double(coinSpec.row) * 10
                let coin = Path(ellipseIn: CGRect(x: dx * S, y: y * S, width: 13 * S, height: 13 * S))
                fillStroke(coin, yellow, 2.0)
                // ¥ 符号简化: 两条线
                let mark = Path { p in
                    p.move(to: CGPoint(x: (dx + 5.5) * S, y: (y + 3) * S))
                    p.addLine(to: CGPoint(x: (dx + 7.5) * S, y: (y + 9.5) * S))
                    p.move(to: CGPoint(x: (dx + 7.5) * S, y: (y + 9.5) * S))
                    p.addLine(to: CGPoint(x: (dx + 5.8) * S, y: (y + 9.5) * S))
                }
                ctx.stroke(mark, with: .color(ink), lineWidth: 1.2 * S)
            }

        case .receipt:
            // 手上拿收据
            let rect = Path { p in
                p.addRoundedRect(in: CGRect(x: 62 * S, y: 40 * S, width: 24 * S, height: 32 * S), cornerSize: CGSize(width: 3 * S, height: 3 * S))
            }
            fillStroke(rect, cream, 2.0)
            // 收据横线
            for i in 0..<3 {
                let y: CGFloat = 48 + CGFloat(i) * 7
                let line = Path { p in
                    p.move(to: CGPoint(x: 66 * S, y: y * S))
                    p.addLine(to: CGPoint(x: 82 * S, y: y * S))
                }
                ctx.stroke(line, with: .color(ink.opacity(0.5)), lineWidth: 1.4 * S)
            }
            // 锯齿底
            let zig = Path { p in
                p.move(to: CGPoint(x: 62 * S, y: 72 * S))
                for i in 0..<5 {
                    let x = 62.0 + Double(i) * 4.8
                    let up = Double(i % 2) * 3
                    p.addLine(to: CGPoint(x: x * S, y: (72 + up) * S))
                }
            }
            ctx.stroke(zig, with: .color(ink), lineWidth: 1.6 * S)

        case .star:
            // 头顶星星
            let star = starPath(center: CGPoint(x: 76 * S, y: 16 * S), r: 10 * S)
            fillStroke(star, yellow, 2.0)
            // 手中小星
            let star2 = starPath(center: CGPoint(x: 28 * S, y: 78 * S), r: 7 * S)
            fillStroke(star2, yellow, 1.8)

        case .box:
            // 抱箱子
            let box = Path { p in
                p.addRoundedRect(in: CGRect(x: 60 * S, y: 58 * S, width: 30 * S, height: 24 * S), cornerSize: CGSize(width: 4 * S, height: 4 * S))
            }
            fillStroke(box, orange, 2.2)
            // 箱盖线
            let lid = Path { p in
                p.move(to: CGPoint(x: 60 * S, y: 66 * S))
                p.addLine(to: CGPoint(x: 90 * S, y: 66 * S))
            }
            ctx.stroke(lid, with: .color(ink), lineWidth: 1.6 * S)
            // 封条
            let tape = Path { p in
                p.move(to: CGPoint(x: 72 * S, y: 58 * S))
                p.addLine(to: CGPoint(x: 72 * S, y: 82 * S))
            }
            ctx.stroke(tape, with: .color(ink.opacity(0.6)), lineWidth: 2.0 * S)

        case .computer:
            // 笔记本电脑
            let screen = Path { p in
                p.addRoundedRect(in: CGRect(x: 58 * S, y: 44 * S, width: 34 * S, height: 22 * S), cornerSize: CGSize(width: 3 * S, height: 3 * S))
            }
            fillStroke(screen, blue, 2.2)
            // 屏幕内容
            let code = Path { p in
                p.move(to: CGPoint(x: 62 * S, y: 52 * S))
                p.addLine(to: CGPoint(x: 70 * S, y: 52 * S))
                p.move(to: CGPoint(x: 62 * S, y: 57 * S))
                p.addLine(to: CGPoint(x: 76 * S, y: 57 * S))
            }
            ctx.stroke(code, with: .color(ink.opacity(0.55)), lineWidth: 1.6 * S)
            // 底座
            let base = Path { p in
                p.move(to: CGPoint(x: 56 * S, y: 66 * S))
                p.addLine(to: CGPoint(x: 94 * S, y: 66 * S))
                p.addLine(to: CGPoint(x: 90 * S, y: 71 * S))
                p.addLine(to: CGPoint(x: 60 * S, y: 71 * S))
                p.closeSubpath()
            }
            fillStroke(base, green, 2.0)

        case .hello, .empty:
            break
        }
    }

    private func starPath(center: CGPoint, r: CGFloat) -> Path {
        var p = Path()
        for i in 0..<10 {
            let angle = Double(i) * .pi / 5 - .pi / 2
            let radius = i % 2 == 0 ? r : r * 0.45
            let pt = CGPoint(x: center.x + CGFloat(cos(angle)) * radius,
                             y: center.y + CGFloat(sin(angle)) * radius)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - 可复用: 侧边栏 logo (小人 + 名字)

struct SiliangLogo: View {
    var size: CGFloat = 96
    var animated: Bool = false

    var body: some View {
        SiliangMascot(pose: .hello, size: size, animated: animated)
    }
}

// MARK: - 空状态 (插画 + 文案)

struct MascotEmptyState: View {
    var message: String
    var pose: SiliangMascot.Pose = .empty
    var size: CGFloat = 84
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            SiliangMascot(pose: pose, size: size, animated: false)
            Text(message)
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(.secondary)
            if let actionTitle, let action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
    }
}
