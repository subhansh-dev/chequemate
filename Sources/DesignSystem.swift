import SwiftUI

// MARK: - ChequeMate Design System â€” "Liquid Dusk"
// Apple-native Liquid Glass (iOS 26). Dark-first, lacquered, physical.

// MARK: - Color Tokens
enum ChequeWave {
    // Surfaces â€” layered near-black with warm undertone
    static let bg       = Color(red: 0.024, green: 0.024, blue: 0.031)   // void
    static let bgDeep   = Color(red: 0.055, green: 0.051, blue: 0.075)   // raised
    static let bgWarm   = Color(red: 0.086, green: 0.066, blue: 0.094)   // atmospheric

    // Ink â€” never pure white, always luminous
    static let ink      = Color.white.opacity(0.94)
    static let inkSoft  = Color.white.opacity(0.58)
    static let inkFaint = Color.white.opacity(0.30)

    // Accents â€” calibrated like stage lighting, not crayons
    static let peach      = Color(red: 1.00, green: 0.72, blue: 0.47)   // primary energy
    static let peachDeep  = Color(red: 0.94, green: 0.52, blue: 0.24)
    static let peachLight = Color(red: 1.00, green: 0.86, blue: 0.68)
    static let coral      = Color(red: 0.99, green: 0.42, blue: 0.36)
    static let mint       = Color(red: 0.45, green: 0.90, blue: 0.76)
    static let blush      = Color(red: 0.97, green: 0.63, blue: 0.78)
    static let sand       = Color(red: 0.91, green: 0.86, blue: 0.78)

    // Signature gradients
    static let aurora = LinearGradient(
        colors: [peach, coral, blush, mint],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let peachBeam = LinearGradient(
        colors: [peachLight, peach, peachDeep],
        startPoint: .top, endPoint: .bottom)

    static let emberRadial = RadialGradient(
        colors: [peach.opacity(0.55), coral.opacity(0.18), .clear],
        center: .center, startRadius: 0, endRadius: 220)
}

// MARK: - Motion Tokens
enum HueMotion {
    static let spring  = Animation.spring(response: 0.42, dampingFraction: 0.72)
    static let snappy  = Animation.spring(response: 0.28, dampingFraction: 0.78)
    static let slow    = Animation.spring(response: 0.8,  dampingFraction: 0.9)
    static let breathe = Animation.easeInOut(duration: 3.2)
}

// MARK: - Specular hairline (the "lacquered edge" that sells real glass)
struct SpecularEdge: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let inset = rect.insetBy(dx: 0.5, dy: 0.5)
        let r = inset.height * 0.28
        p.addRoundedRect(in: inset, cornerRadii: RectangleCornerRadii(topLeading: r, bottomLeading: r, bottomTrailing: r, topTrailing: r), style: .continuous)
        return p
    }
}

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var cornerRadius: CGFloat = 28
    var interactive: Bool = false

    var body: some View {
        content
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(ChequeWave.ink.opacity(0.02))
            }
            .glassEffect(
                (interactive ? Glass.regular.interactive() : Glass.regular)
                    .tint(ChequeWave.peach.opacity(0.05)),
                in: .rect(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [ChequeWave.ink.opacity(0.28), ChequeWave.ink.opacity(0.05),
                                     ChequeWave.ink.opacity(0.02), ChequeWave.peach.opacity(0.16)],
                            startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
    }
}

// MARK: - Glass Button (press physics + light sweep)
struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var variant: Variant = .primary
    var isLoading: Bool = false
    enum Variant { case primary, secondary, ghost }

    @State private var pressed = false

    var body: some View {
        Button(action: action) { label }
            .buttonStyle(.plain)
            .scaleEffect(pressed ? 0.965 : 1)
            .animation(HueMotion.snappy, value: pressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !pressed { pressed = true } }
                    .onEnded { _ in pressed = false })
            .disabled(isLoading)
    }

    private var label: some View {
        HStack(spacing: 10) {
            if isLoading { ProgressView().tint(.black.opacity(0.7)) }
            else {
                if let icon { Image(systemName: icon).font(.system(size: 15, weight: .semibold)) }
                Text(title).font(.system(.callout, design: .rounded, weight: .semibold))
            }
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: variant == .ghost ? nil : .infinity)
        .frame(height: 54)
        .padding(.horizontal, variant == .ghost ? 8 : 20)
        .background { fill }
        .glassEffect(glass, in: .capsule)
        .overlay { sheen }
    }

    private var foreground: some ShapeStyle {
        switch variant {
        case .primary: return AnyShapeStyle(Color.black.opacity(0.82))
        case .secondary: return AnyShapeStyle(ChequeWave.ink)
        case .ghost: return AnyShapeStyle(ChequeWave.inkSoft)
        }
    }

    @ViewBuilder private var fill: some View {
        if variant == .primary {
            Capsule().fill(ChequeWave.peachBeam)
                .shadow(color: ChequeWave.peach.opacity(0.45), radius: 18, x: 0, y: 8)
        }
    }

    private var glass: Glass {
        switch variant {
        case .primary: return Glass.regular.interactive().tint(ChequeWave.peach.opacity(0.35))
        case .secondary: return Glass.regular.interactive().tint(ChequeWave.ink.opacity(0.04))
        case .ghost: return Glass.identity
        }
    }

    @ViewBuilder private var sheen: some View {
        if variant != .ghost {
            Capsule().strokeBorder(
                LinearGradient(colors: [ChequeWave.ink.opacity(0.5), ChequeWave.ink.opacity(0.06)],
                               startPoint: .top, endPoint: .bottom),
                lineWidth: 0.5)
        }
    }
}

// MARK: - Glass Icon Button
struct GlassIconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 48
    var tint: Color = ChequeWave.peach
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .glassEffect(.regular.interactive().tint(tint.opacity(0.12)), in: .circle)
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.88 : 1)
        .animation(HueMotion.snappy, value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !pressed { pressed = true } }
                .onEnded { _ in pressed = false })
    }
}

// MARK: - Section Header â€” editorial, keynote rhythm
struct SectionHeader: View {
    let index: String
    let tag: String
    let title: String
    let desc: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(index)
                    .font(.system(.caption, design: .monospaced, weight: .medium))
                    .foregroundStyle(ChequeWave.peach)
                Text(tag.uppercased())
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(ChequeWave.inkFaint)
            }
            Text(title)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(ChequeWave.ink)
            if !desc.isEmpty {
                Text(desc)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(ChequeWave.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Glow Dot
struct GlowDot: View {
    let color: Color
    var size: CGFloat = 8
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.9), radius: size * 1.2)
    }
}

// MARK: - Ambient Background â€” slow aurora, filmic depth
struct MeshBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let base = CGRect(origin: .zero, size: size)
                ctx.fill(Path(base), with: .color(ChequeWave.bg))

                let blobs: [(Double, Color, Double, Double)] = [
                    // (phase, color, sizeFactor, speed)
                    (0.0, ChequeWave.peachDeep, 1.15, 0.05),
                    (2.1, ChequeWave.coral,     0.95, 0.07),
                    (4.2, ChequeWave.mint,      0.80, 0.06),
                    (1.2, ChequeWave.blush,     0.70, 0.08),
                ]
                for (phase, color, sf, speed) in blobs {
                    let a = phase + t * speed
                    let cx = size.width * (0.5 + 0.34 * cos(a))
                    let cy = size.height * (0.42 + 0.26 * sin(a * 1.3))
                    let r = min(size.width, size.height) * 0.62 * sf
                    let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                    ctx.fill(
                        Path(ellipseIn: rect),
                        with: .radialGradient(
                            Gradient(colors: [color.opacity(0.16), color.opacity(0.05), .clear]),
                            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: r))
                }
            }
        }
        .blur(radius: 60)
        .overlay {
            // vignette to seat the glass
            RadialGradient(colors: [.clear, .black.opacity(0.55)],
                           center: .center, startRadius: 120, endRadius: 460)
                .ignoresSafeArea()
        }
        .background(ChequeWave.bg.ignoresSafeArea())
        .ignoresSafeArea()
    }
}

// MARK: - Glass Text Field
struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String?
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(focused ? ChequeWave.peach : ChequeWave.inkFaint)
            }
            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundStyle(ChequeWave.inkFaint))
                    .focused($focused)
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(ChequeWave.inkFaint))
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focused)
            }
        }
        .font(.system(.callout, design: .rounded))
        .foregroundStyle(ChequeWave.ink)
        .frame(height: 54)
        .padding(.horizontal, 18)
        .glassEffect(.regular.interactive().tint((focused ? ChequeWave.peach : ChequeWave.ink).opacity(focused ? 0.14 : 0.04)),
                     in: .rect(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(ChequeWave.peach.opacity(focused ? 0.45 : 0), lineWidth: 1)
                .animation(HueMotion.spring, value: focused)
        }
    }
}

// MARK: - Marquee-free helpers
extension View {
    /// Subtle 3D tilt driven by drag â€” passes live angles out.
    func tilt3D(x: Binding<CGFloat>, y: Binding<CGFloat>) -> some View {
        self.rotation3DEffect(.degrees(Double(y.wrappedValue)), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            .rotation3DEffect(.degrees(Double(x.wrappedValue)), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
    }
}
