import SwiftUI

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let dx: CGFloat
    let dy: CGFloat
    let rotation: Angle
    let delay: Double
}

struct ConfettiBurst: View {
    @Binding var trigger: Bool

    @State private var particles: [ConfettiParticle] = []
    @State private var burst = false

    private let palette: [Color] = [
        Color(red: 0.18, green: 0.46, blue: 0.84),
        Color(red: 0.91, green: 0.22, blue: 0.42),
        Color(red: 0.58, green: 0.88, blue: 0.76),
        Color(red: 0.96, green: 0.77, blue: 0.65)
    ]

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Rectangle()
                    .fill(particle.color)
                    .frame(width: 4, height: 8)
                    .rotationEffect(burst ? particle.rotation : .zero)
                    .offset(
                        x: burst ? particle.dx : 0,
                        y: burst ? particle.dy : 0
                    )
                    .opacity(burst ? 0 : 1)
                    .transition(.opacity.combined(with: .scale(scale: 0.3)))
                    .animation(
                        .timingCurve(0.2, 0.8, 0.4, 1.0, duration: 1.4)
                            .delay(particle.delay),
                        value: burst
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newValue in
            if newValue { fire() }
        }
    }

    private func fire() {
        let newParticles = (0..<30).map { _ -> ConfettiParticle in
            let angle = Double.random(in: 0..<(2 * .pi))
            let distance = Double.random(in: 60...160)
            let gravity = Double.random(in: 40...120)
            return ConfettiParticle(
                color: palette.randomElement() ?? .blue,
                dx: cos(angle) * distance,
                dy: sin(angle) * distance + gravity,
                rotation: Angle.degrees(Double.random(in: 90...360)),
                delay: Double.random(in: 0...0.1)
            )
        }

        withAnimation(.easeOut(duration: 0.15)) {
            particles = newParticles
            burst = false
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(30))
            withAnimation { burst = true }
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.easeOut(duration: 0.2)) {
                particles = []
                burst = false
                trigger = false
            }
        }
    }
}
