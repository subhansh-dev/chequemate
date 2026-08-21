import SwiftUI

// MARK: - Boot Animation — Cinematic Splash

struct BootAnimationView: View {
    @State private var phase = 0
    @State private var iconScale: CGFloat = 0
    @State private var iconRotation: Double = 0
    @State private var typedText = ""
    @State private var taglineOpacity: Double = 0
    @State private var gridOpacity: Double = 0
    @State private var halftoneOffset: CGFloat = -400
    @State private var fadeOut: Bool = false

    private let fullTitle = "CHEQUEMATE"
    private let tagline = "Split it. Settle it. Checkmate."

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Blueprint grid — fades in from center
            BootGrid()
                .opacity(gridOpacity)
                .ignoresSafeArea()

            // Halftone sweep
            HalftoneSweep(offset: halftoneOffset)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Checkerboard shield icon
                ZStack {
                    Circle()
                        .fill(ChequeWave.blueprint.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: "checkerboard.shield")
                        .font(.system(size: 56, weight: .black))
                        .foregroundStyle(ChequeWave.blueprint)
                }
                .scaleEffect(iconScale)
                .rotation3DEffect(.degrees(iconRotation), axis: (x: 0, y: 1, z: 0))

                // Typed title
                HStack(spacing: 2) {
                    ForEach(Array(fullTitle.enumerated()), id: \.offset) { index, char in
                        Text(String(char))
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .opacity(index < typedText.count ? 1 : 0)
                            .offset(y: index < typedText.count ? 0 : 8)
                    }
                }
                .frame(height: 46)

                // Tagline
                Text(tagline)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(ChequeWave.blueprintLight)
                    .opacity(taglineOpacity)

                Spacer()

                // Bottom barcode
                HStack(spacing: 2) {
                    ForEach(0..<24, id: \.self) { _ in
                        Rectangle()
                            .fill(.white.opacity(0.3))
                            .frame(width: CGFloat.random(in: 1...3), height: 12)
                    }
                }
                .padding(.bottom, 40)
                .opacity(taglineOpacity)
            }
        }
        .opacity(fadeOut ? 0 : 1)
        .onAppear { runSequence() }
    }

    private func runSequence() {
        // Phase 1: Icon bounces in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            iconScale = 1.0
        }
        withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
            iconRotation = 360
        }

        // Phase 2: Grid fades in
        withAnimation(.easeIn(duration: 0.8).delay(0.2)) {
            gridOpacity = 0.3
        }

        // Phase 3: Halftone sweep
        withAnimation(.linear(duration: 1.0).delay(0.4)) {
            halftoneOffset = 400
        }

        // Phase 4: Typewriter
        for (index, _) in fullTitle.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8 + Double(index) * 0.08) {
                withAnimation(.easeOut(duration: 0.05)) {
                    typedText = String(fullTitle.prefix(index + 1))
                }
            }
        }

        // Phase 5: Tagline fade in
        let taglineDelay = 0.8 + Double(fullTitle.count) * 0.08 + 0.3
        withAnimation(.easeIn(duration: 0.6).delay(taglineDelay)) {
            taglineOpacity = 1
        }

        // Phase 6: Fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                fadeOut = true
            }
        }
    }
}

// MARK: - Boot Grid

private struct BootGrid: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 28
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
            ctx.stroke(line, with: .color(ChequeWave.blueprint.opacity(0.4)), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Halftone Sweep

private struct HalftoneSweep: View {
    let offset: CGFloat
    var body: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 8
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    let shiftedX = x + offset
                    let rect = CGRect(x: shiftedX, y: y, width: 2, height: 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(ChequeWave.magenta.opacity(0.12)))
                    x += spacing
                }
                y += spacing
            }
        }
        .allowsHitTesting(false)
    }
}
