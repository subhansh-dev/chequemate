import SwiftUI

// MARK: - Design Tokens

enum HueWave {
    static let bg = Color(red: 0.012, green: 0.024, blue: 0.055)
    static let bgDeep = Color(red: 0.024, green: 0.047, blue: 0.102)
    static let surface = Color.white.opacity(0.04)
    static let surfaceRaised = Color.white.opacity(0.08)
    static let teal = Color(red: 0.831, green: 0.659, blue: 0.325)
    static let aqua = Color(red: 0.910, green: 0.788, blue: 0.478)
    static let rose = Color(red: 0.941, green: 0.565, blue: 0.675)
    static let ink = Color.white
    static let inkSoft = Color.white.opacity(0.6)
    static let inkFaint = Color.white.opacity(0.35)
    static let line = Color.white.opacity(0.09)
    static let lineStrong = Color.white.opacity(0.18)
}

// MARK: - Liquid Glass Card

struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 24
    var interactive: Bool = false

    init(cornerRadius: CGFloat = 24, interactive: Bool = false, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.interactive = interactive
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(HueWave.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(HueWave.line, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Neumorphic Panel

struct NeoPanel<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 24
    var pressed: Bool = false

    init(cornerRadius: CGFloat = 24, pressed: Bool = false, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.pressed = pressed
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(HueWave.bg)
                    .shadow(color: .black.opacity(0.5), radius: pressed ? 2 : 8, x: pressed ? 1 : 4, y: pressed ? 1 : 4)
                    .shadow(color: Color.white.opacity(0.04), radius: pressed ? 1 : 4, x: pressed ? -1 : -3, y: pressed ? -1 : -3)
            )
    }
}

// MARK: - Liquid Glass Button

struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var variant: Variant = .primary
    var isLoading: Bool = false

    enum Variant { case primary, secondary, ghost }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(variant == .primary ? HueWave.bg : HueWave.ink)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(buttonBackground)
            .foregroundStyle(variant == .primary ? HueWave.bg : HueWave.ink)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(borderColor, lineWidth: variant == .ghost ? 1 : 0)
            )
        }
        .disabled(isLoading)
    }

    private var buttonBackground: some ShapeStyle {
        switch variant {
        case .primary:
            return AnyShapeStyle(LinearGradient(colors: [HueWave.teal, HueWave.aqua], startPoint: .leading, endPoint: .trailing))
        case .secondary:
            return AnyShapeStyle(HueWave.surfaceRaised)
        case .ghost:
            return AnyShapeStyle(Color.clear)
        }
    }

    private var borderColor: Color {
        variant == .ghost ? HueWave.lineStrong : .clear
    }
}

// MARK: - Liquid Glass Icon Button

struct GlassIconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 48
    var tint: Color = HueWave.teal

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(HueWave.surface)
                        .overlay(Circle().strokeBorder(HueWave.line, lineWidth: 1))
                )
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let index: String
    let tag: String
    let title: String
    let desc: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(index)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(HueWave.teal)
                Text(tag.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(HueWave.inkFaint)
            }
            Text(title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(HueWave.ink)
                .lineSpacing(2)
            Text(desc)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(HueWave.inkSoft)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Glowing Dot

struct GlowDot: View {
    let color: Color
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.6), radius: 6)
    }
}

// MARK: - Animated Mesh Background

struct MeshBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [HueWave.bg, HueWave.bgDeep, HueWave.bg], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let cx = size.width / 2
                    let cy = size.height * 0.35

                    context.blendMode = .softLight
                    for i in 0..<3 {
                        let angle = Double(i) / 3 * .pi * 2 + t * 0.12
                        let dist = min(size.width, size.height) * (0.18 + 0.06 * sin(t * 0.3 + Double(i)))
                        let px = cx + CGFloat(cos(angle)) * dist
                        let py = cy + CGFloat(sin(angle)) * dist * 0.5
                        let color = i == 0 ? HueWave.teal : (i == 1 ? HueWave.rose : HueWave.aqua)
                        context.fill(
                            Path(ellipseIn: CGRect(x: px - 100, y: py - 100, width: 200, height: 200)),
                            with: .radialGradient(
                                Gradient(colors: [color.opacity(0.12), .clear]),
                                center: CGPoint(x: px, y: py),
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Text Field

struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String?
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(HueWave.inkFaint)
                    .frame(width: 20)
            }
            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                }
            }
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(HueWave.ink)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(HueWave.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(HueWave.line, lineWidth: 1))
        )
        .overlay(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(HueWave.inkFaint)
                    .padding(.leading, icon != nil ? 50 : 18)
                    .allowsHitTesting(false)
            }
        }
    }
}
