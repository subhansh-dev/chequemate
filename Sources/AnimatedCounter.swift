import SwiftUI

struct AnimatedCounter: View {
    let target: Double
    let currencySymbol: String

    @State private var displayedValue: Double = 0
    @State private var velocity: Double = 0
    @State private var timer: Timer?

    private let stiffness: Double = 90
    private let damping: Double = 9
    private let tickInterval: TimeInterval = 1.0 / 120.0

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(currencySymbol)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(ChequeWave.blueprint)
            Text(formattedValue)
                .font(.system(size: 44, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(ChequeWave.ink)
        }
        .onAppear(perform: startTimer)
        .onDisappear { timer?.invalidate() }
        .onChange(of: target) { restart() }
    }

    private var formattedValue: String {
        let rounded = (displayedValue * 100).rounded() / 100
        if rounded.rounded() == rounded {
            return String(Int(rounded))
        }
        return String(format: "%.2f", rounded)
    }

    private func startTimer() {
        timer?.invalidate()
        displayedValue = 0
        velocity = 0

        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { _ in
            step()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func restart() {
        displayedValue = 0
        velocity = 0
        startTimer()
    }

    private func step() {
        let dt = tickInterval
        let displacement = displayedValue - target

        let springForce = -stiffness * displacement
        let dampingForce = -damping * velocity
        velocity += (springForce + dampingForce) * dt
        displayedValue += velocity * dt

        if abs(displacement) < 0.005 && abs(velocity) < 0.005 {
            displayedValue = target
            timer?.invalidate()
            timer = nil
        }
    }
}
