import SwiftUI

// MARK: - Design Tokens

enum HueWave {
    static let bg = Color(red: 0.97, green: 0.95, blue: 0.92)
    static let bgDeep = Color(red: 0.94, green: 0.91, blue: 0.87)
    static let bgWarm = Color(red: 0.99, green: 0.97, blue: 0.94)
    static let peach = Color(red: 0.98, green: 0.68, blue: 0.50)
    static let peachLight = Color(red: 1.0, green: 0.82, blue: 0.70)
    static let peachDeep = Color(red: 0.88, green: 0.52, blue: 0.38)
    static let coral = Color(red: 0.92, green: 0.42, blue: 0.42)
    static let sand = Color(red: 0.86, green: 0.80, blue: 0.70)
    static let blush = Color(red: 0.93, green: 0.62, blue: 0.58)
    static let mint = Color(red: 0.50, green: 0.78, blue: 0.68)
    static let ink = Color(red: 0.16, green: 0.14, blue: 0.12)
    static let inkSoft = Color(red: 0.42, green: 0.38, blue: 0.35)
    static let inkFaint = Color(red: 0.62, green: 0.58, blue: 0.55)
}

// MARK: - Glass Card (Native Liquid Glass)

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
            .padding(interactive ? 4 : 0)
            .glassEffect(.regular.tint(HueWave.peach.opacity(0.06)), in: .rect(cornerRadius: cornerRadius))
    }
}

// MARK: - Glass Button

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
                        .tint(variant == .primary ? .white : HueWave.ink)
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
            .foregroundStyle(variant == .primary ? .white : HueWave.ink)
            .glassEffect(.regular.tint(variant == .primary ? HueWave.peach : .clear), in: .capsule)
        }
        .disabled(isLoading)
    }
}

// MARK: - Glass Icon Button

struct GlassIconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 48
    var tint: Color = HueWave.peach

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .glassEffect(.regular.tint(tint.opacity(0.12)), in: .circle)
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
                    .foregroundStyle(HueWave.peach)
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
            .shadow(color: color.opacity(0.5), radius: 4)
    }
}

// MARK: - Animated Mesh Background

struct MeshBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [HueWave.bgWarm, HueWave.bg, HueWave.bgDeep],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let cx = size.width / 2
                    let cy = size.height * 0.35

                    context.blendMode = .softLight

                    let blobs: [(Double, Color, Double)] = [
                        (0, HueWave.peachLight, 0.20),
                        (2.094, HueWave.blush, 0.18),
                        (4.189, HueWave.sand, 0.16),
                        (1.0, HueWave.mint, 0.12),
                    ]

                    for (offset, color, opacity) in blobs {
                        let angle = offset + t * 0.06
                        let dist = min(size.width, size.height) * (0.22 + 0.04 * sin(t * 0.15 + offset))
                        let px = cx + CGFloat(cos(angle)) * dist
                        let py = cy + CGFloat(sin(angle)) * dist * 0.5
                        context.fill(
                            Path(ellipseIn: CGRect(x: px - 140, y: py - 140, width: 280, height: 280)),
                            with: .radialGradient(
                                Gradient(colors: [color.opacity(opacity), .clear]),
                                center: CGPoint(x: px, y: py),
                                startRadius: 0,
                                endRadius: 160
                            )
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Text Field (Neumorphic Inset)

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
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
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
