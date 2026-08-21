import SwiftUI

// MARK: - ChequeMate Design System — Neo Poster / Zine
// Vibe: Hatsune Miku blue + hot magenta on warm paper.
// Ink frames, halftone dots, paper grain, blueprint grid, big numbers.

enum ChequeWave {
    // Paper + ink
    static let paper      = Color(red: 0.96, green: 0.93, blue: 0.87)
    static let paperDeep  = Color(red: 0.92, green: 0.88, blue: 0.80)
    static let paperMid   = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let ink        = Color(red: 0.07, green: 0.07, blue: 0.10)
    static let inkSoft    = Color(red: 0.38, green: 0.38, blue: 0.42)
    static let inkFaint   = Color(red: 0.58, green: 0.57, blue: 0.60)

    // Hero colors — blueprint blue + hot magenta (from the posters)
    static let blueprint      = Color(red: 0.18, green: 0.46, blue: 0.84)
    static let blueprintDeep  = Color(red: 0.10, green: 0.29, blue: 0.56)
    static let blueprintLight = Color(red: 0.55, green: 0.73, blue: 0.94)
    static let magenta        = Color(red: 0.91, green: 0.22, blue: 0.42)
    static let magentaDeep    = Color(red: 0.78, green: 0.12, blue: 0.30)
    static let mikuBlue       = Color(red: 0.23, green: 0.62, blue: 0.92)

    // Pastels kept for avatars (toned down)
    static let lavender = Color(red: 0.74, green: 0.68, blue: 0.92)
    static let mint     = Color(red: 0.58, green: 0.88, blue: 0.76)
    static let peach    = Color(red: 0.96, green: 0.77, blue: 0.65)
    static let sky      = Color(red: 0.62, green: 0.81, blue: 0.94)
    static let blush    = Color(red: 0.94, green: 0.68, blue: 0.74)

    static let positive = Color(red: 0.20, green: 0.62, blue: 0.48)
    static let negative = Color(red: 0.88, green: 0.24, blue: 0.36)
    static let accent   = blueprint

    // Gradients
    static let blueprintGradient = LinearGradient(colors: [blueprint, blueprintDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let magentaGradient   = LinearGradient(colors: [magenta, magentaDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let paperGradient     = LinearGradient(colors: [paperMid, paper], startPoint: .top, endPoint: .bottom)

    static let avatarGradients: [LinearGradient] = [
        LinearGradient(colors: [Color(red:0.22, green:0.58, blue:0.94), blueprintDeep], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [magenta, magentaDeep], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(red:0.16, green:0.58, blue:0.52), Color(red:0.08, green:0.40, blue:0.36)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(red:0.92, green:0.68, blue:0.18), Color(red:0.74, green:0.46, blue:0.08)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [lavender, Color(red:0.55, green:0.50, blue:0.84)], startPoint: .topLeading, endPoint: .bottomTrailing),
    ]
    static func gradient(for index: Int) -> LinearGradient { avatarGradients[index % avatarGradients.count] }
}

enum HueMotion {
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.78)
    static let snappy = Animation.spring(response: 0.28, dampingFraction: 0.82)
    static let slow   = Animation.spring(response: 0.7, dampingFraction: 0.9)
}

// MARK: - Paper grain + blueprint grid background

struct MeshBackground: View {
    var body: some View {
        ZStack {
            ChequeWave.paper.ignoresSafeArea()
            // faint blueprint grid
            Canvas { ctx, size in
                let step: CGFloat = 22
                let line = Path { p in
                    var x: CGFloat = 0
                    while x < size.width {
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: size.height))
                        x += step
                    }
                    var y: CGFloat = 0
                    while y < size.height {
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: size.width, y: y))
                        y += step
                    }
                }
                ctx.stroke(line, with: .color(ChequeWave.blueprint.opacity(0.05)), lineWidth: 0.5)
            }
            .ignoresSafeArea()
            // paper grain (tiny speckles)
            Canvas { ctx, size in
                let seed: UInt64 = 0x9E3779B97F4A7C15
                var rng = SeededRNG(seed: seed)
                for _ in 0..<1800 {
                    let x = CGFloat.random(in: 0..<size.width, using: &rng)
                    let y = CGFloat.random(in: 0..<size.height, using: &rng)
                    let r: CGFloat = CGFloat.random(in: 0.25...0.7, using: &rng)
                    let a = Double.random(in: 0.04...0.10, using: &rng)
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(.black.opacity(a)))
                }
            }
            .opacity(0.45)
            .ignoresSafeArea()
            // soft blueprint wash at top
            LinearGradient(colors: [ChequeWave.blueprint.opacity(0.08), .clear], startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

// simple seeded RNG for grain
private struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

// MARK: - Halftone dots overlay (like the pink block in image 2)

struct HalftoneDots: View {
    var color: Color = ChequeWave.ink.opacity(0.07)
    var spacing: CGFloat = 7
    var dot: CGFloat = 1.6
    var body: some View {
        Canvas { ctx, size in
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    let rect = CGRect(x: x, y: y, width: dot, height: dot)
                    ctx.fill(Path(ellipseIn: rect), with: .color(color))
                    x += spacing
                }
                y += spacing
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Thin rule

struct Rule: View {
    var color: Color = ChequeWave.ink.opacity(0.12)
    var body: some View { Rectangle().fill(color).frame(height: 0.75) }
}

// MARK: - Bracket frame (corner Ls like poster border)

struct BracketFrame: View {
    var color: Color = ChequeWave.ink
    var lineWidth: CGFloat = 1.2
    var corner: CGFloat = 12
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Path { p in
                // top-left
                p.move(to: CGPoint(x: 0, y: corner)); p.addLine(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: corner, y: 0))
                // top-right
                p.move(to: CGPoint(x: w - corner, y: 0)); p.addLine(to: CGPoint(x: w, y: 0)); p.addLine(to: CGPoint(x: w, y: corner))
                // bottom-left
                p.move(to: CGPoint(x: 0, y: h - corner)); p.addLine(to: CGPoint(x: 0, y: h)); p.addLine(to: CGPoint(x: corner, y: h))
                // bottom-right
                p.move(to: CGPoint(x: w - corner, y: h)); p.addLine(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: w, y: h - corner))
            }
            .stroke(color, lineWidth: lineWidth)
        }
    }
}

// MARK: - Poster card (thick ink frame + paper fill)

struct PosterCard<Content: View>: View {
    var content: Content
    var accent: Color? = nil
    init(accent: Color? = nil, @ViewBuilder content: () -> Content) {
        self.accent = accent
        self.content = content()
    }
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            if let accent {
                Rectangle().fill(accent).frame(width: 4)
            }
            content
                .padding(16)
            BracketFrame(color: ChequeWave.ink.opacity(0.9), lineWidth: 1.1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 0).strokeBorder(ChequeWave.ink, lineWidth: 1.4)
        }
    }
}

// GlassCard kept for compatibility — now maps to poster card without accent
struct GlassCard<Content: View>: View {
    var content: Content
    var cornerRadius: CGFloat = 18
    var tint: Color? = nil
    init(cornerRadius: CGFloat = 18, tint: Color? = nil, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius; self.tint = tint; self.content = content()
    }
    var body: some View {
        PosterCard(accent: tint) { content }
    }
}

struct GradientCard<Content: View>: View {
    let gradient: LinearGradient
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0).fill(gradient)
            content.padding(20)
            BracketFrame(color: .white.opacity(0.9), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .overlay { RoundedRectangle(cornerRadius: 0).strokeBorder(ChequeWave.ink, lineWidth: 1.4) }
        .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 8)
    }
}

// MARK: - Avatars / badges

struct PersonAvatar: View {
    let name: String
    let gradient: LinearGradient
    var size: CGFloat = 36
    var body: some View {
        ZStack {
            Circle().fill(gradient)
            Text(String(name.prefix(1).uppercased()))
                .font(.system(size: size * 0.42, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay { Circle().strokeBorder(.white, lineWidth: 1.2) }
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
    }
}

struct IconBadge: View {
    let icon: String
    let gradient: LinearGradient
    var size: CGFloat = 34
    var body: some View {
        ZStack {
            Rectangle().fill(gradient)
            Image(systemName: icon).font(.system(size: size * 0.42, weight: .bold)).foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay { Rectangle().strokeBorder(ChequeWave.ink, lineWidth: 1) }
    }
}

struct PastelPill: View {
    let text: String
    let tint: Color
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .black, design: .monospaced))
            .tracking(0.6)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background { Rectangle().fill(tint) }
            .overlay { Rectangle().strokeBorder(ChequeWave.ink, lineWidth: 0.8) }
    }
}

// Vertical kanji accent (decorative, like the posters)
struct KanjiSide: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(ChequeWave.ink.opacity(0.14))
            .rotationEffect(.degrees(90))
            .fixedSize()
    }
}

// Big number badge like "01" in image 1
struct BigNumber: View {
    let n: String
    var body: some View {
        Text(n)
            .font(.system(size: 44, weight: .black, design: .rounded))
            .foregroundStyle(ChequeWave.ink)
            .tracking(-2)
            .opacity(0.92)
    }
}

// MARK: - Buttons

struct GlassButton: View {
    let title: String
    let icon: String?
    var variant: Variant = .primary
    var isLoading: Bool = false
    let action: () -> Void
    enum Variant { case primary, secondary, ghost }
    @State private var pressed = false
    var body: some View {
        Button(action: action) { label }
            .buttonStyle(.plain)
            .scaleEffect(pressed ? 0.98 : 1)
            .animation(HueMotion.snappy, value: pressed)
            .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in pressed = true }.onEnded { _ in pressed = false })
            .disabled(isLoading)
    }
    private var label: some View {
        HStack(spacing: 8) {
            if isLoading { ProgressView().tint(variant == .primary ? .white : ChequeWave.ink) }
            else {
                if let icon { Image(systemName: icon).font(.system(size: 13, weight: .bold)) }
                Text(title.uppercased()).font(.system(size: 13, weight: .black, design: .rounded)).tracking(0.6)
            }
        }
        .foregroundStyle(variant == .primary ? AnyShapeStyle(.white) : AnyShapeStyle(ChequeWave.ink))
        .frame(maxWidth: variant == .ghost ? nil : .infinity)
        .frame(height: 46)
        .padding(.horizontal, 16)
        .background { bg }
        .overlay { Rectangle().strokeBorder(ChequeWave.ink, lineWidth: variant == .ghost ? 0 : 1.4) }
    }
    @ViewBuilder private var bg: some View {
        switch variant {
        case .primary: Rectangle().fill(ChequeWave.blueprint)
        case .secondary: Rectangle().fill(Color.white)
        case .ghost: Color.clear
        }
    }
}

struct GlassIconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 42
    var gradient: LinearGradient = ChequeWave.blueprintGradient
    @State private var pressed = false
    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle().fill(gradient)
                Image(systemName: icon).font(.system(size: size * 0.36, weight: .black)).foregroundStyle(.white)
            }
            .frame(width: size, height: size)
            .overlay { Rectangle().strokeBorder(ChequeWave.ink, lineWidth: 1.2) }
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.93 : 1)
        .animation(HueMotion.snappy, value: pressed)
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in pressed = true }.onEnded { _ in pressed = false })
    }
}

// MARK: - Section header — poster style

struct SectionHeader: View {
    let title: String
    let desc: String
    var icon: String? = nil
    var tint: Color = ChequeWave.blueprint
    var number: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Rule(color: ChequeWave.ink.opacity(0.18))
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if let number {
                    Text(number).font(.system(size: 11, weight: .black, design: .monospaced)).foregroundStyle(tint)
                }
                if let icon {
                    Image(systemName: icon).font(.system(size: 11, weight: .black)).foregroundStyle(tint)
                }
                Text(title.uppercased()).font(.system(size: 13, weight: .black, design: .rounded)).tracking(1).foregroundStyle(ChequeWave.ink)
                Spacer()
                Rectangle().fill(tint).frame(width: 18, height: 3)
            }
            if !desc.isEmpty {
                Text(desc).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(ChequeWave.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Text field — poster input

struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String?
    var keyboardType: UIKeyboardType = .default
    @FocusState private var focused: Bool
    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                ZStack {
                    Rectangle().fill(focused ? ChequeWave.blueprint : Color.black.opacity(0.06))
                    Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundStyle(focused ? .white : ChequeWave.inkFaint)
                }.frame(width: 28, height: 28)
            }
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(ChequeWave.inkFaint))
                .keyboardType(keyboardType).textInputAutocapitalization(.never).autocorrectionDisabled().focused($focused)
        }
        .font(.system(.callout, design: .rounded, weight: .medium))
        .foregroundStyle(ChequeWave.ink)
        .frame(height: 46)
        .padding(.horizontal, 12)
        .background { Rectangle().fill(Color.white) }
        .overlay { Rectangle().strokeBorder(focused ? ChequeWave.blueprint : ChequeWave.ink, lineWidth: focused ? 1.6 : 1.2) }
        .animation(HueMotion.spring, value: focused)
    }
}

// MARK: - Barcode strip (decorative like image 2 / 4)

struct BarcodeStrip: View {
    var body: some View {
        HStack(spacing: 2) {
            ForEach([4,2,6,1,3,5,2,4,1,6,2,3,5,2,4,3,2,5,1,4,2,6,3,2,5], id: \.self) { _ in
                Rectangle().fill(ChequeWave.ink).frame(width: CGFloat.random(in: 1...3), height: 18)
            }
            Spacer()
            Text("CHEQUEMATE — EST. 2026 — NO DATA LEAVES YOUR PHONE")
                .font(.system(size: 7, weight: .bold, design: .monospaced)).tracking(0.6).foregroundStyle(ChequeWave.inkFaint)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background { Rectangle().fill(Color.white) }
        .overlay { Rectangle().strokeBorder(ChequeWave.ink.opacity(0.12), lineWidth: 0.7) }
    }
}
