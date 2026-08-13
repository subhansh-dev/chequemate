import SwiftUI
import AVFoundation
import HuewavesAudio

// MARK: - Camera Preview (UIViewRepresentable)

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.cornerRadius = 0
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}

    class CameraPreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: - Wave Trail

struct WaveTrailPoint: Identifiable {
    let id = UUID()
    let point: CGPoint
    let color: Color
    let timestamp: TimeInterval
    let size: CGFloat
}

// MARK: - Instrument View

struct InstrumentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var handTracker = HandTracker()
    @StateObject private var synthEngine = SynthEngine()
    @StateObject private var haptics = HapticsController()

    @State private var waveTrails: [WaveTrailPoint] = []
    @State private var showSettings = false
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboardingComplete")
    @State private var particleBursts: [ParticleBurst] = []
    @State private var lastGesture: HandGesture = .open

    private let maxTrailPoints = 60
    private let trailFadeDuration: TimeInterval = 1.5

    var body: some View {
        ZStack {
            // Camera feed (dimmed)
            CameraPreview(session: handTracker.captureSession)
                .ignoresSafeArea()
                .overlay {
                    Color.black.opacity(0.35)
                }

            // Wave trail + hand landmarks overlay
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                Canvas { context, size in
                    drawWaveTrails(context: context, size: size, time: timeline.date)
                    drawHandLandmarks(context: context, size: size)
                    drawCenterIndicator(context: context, size: size)
                    drawParticleBursts(context: context, size: size, time: timeline.date)
                }
            }
            .ignoresSafeArea()

            // UI overlay
            VStack {
                topBar
                Spacer()
                bottomHUD
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .onAppear {
            synthEngine.start()
            handTracker.startTracking()
        }
        .onDisappear {
            handTracker.stopTracking()
            synthEngine.stop()
            haptics.stop()
        }
        .onChange(of: handTracker.pitch) { _, newFreq in
            updateAudio()
        }
        .onChange(of: handTracker.amplitude) { _, _ in
            updateAudio()
        }
        .onChange(of: handTracker.currentGesture) { _, newGesture in
            handleGestureChange(newGesture)
        }
        .onChange(of: handTracker.waveformType) { _, newType in
            synthEngine.setWaveform(SynthEngine.WaveformType(rawValue: newType) ?? .sine)
        }
        .sheet(isPresented: $showSettings) {
            SettingsPanel(handTracker: handTracker, synthEngine: synthEngine)
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Huewaves")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(HueWave.ink)
                Text(handTracker.isTracking ? "Tracking" : "Tap to start")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(handTracker.isTracking ? HueWave.mint : HueWave.inkFaint)
            }

            Spacer()

            // Gesture indicator
            if handTracker.handCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: handTracker.currentGesture.icon)
                        .font(.system(size: 13, weight: .semibold))
                    Text(handTracker.currentGesture.label)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(HueWave.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassEffect(.regular.tint(HueWave.peach.opacity(0.12)), in: .capsule)
            }

            // Waveform picker
            Button {
                synthEngine.cycleWaveform()
                handTracker.waveformType = synthEngine.currentWaveform.rawValue
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: synthEngine.currentWaveform.icon)
                        .font(.system(size: 13, weight: .semibold))
                    Text(synthEngine.currentWaveform.label)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(HueWave.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassEffect(.regular.interactive().tint(HueWave.peach.opacity(0.12)), in: .capsule)
            }

            // Settings
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(HueWave.inkSoft)
                    .frame(width: 38, height: 38)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
        }
    }

    // MARK: - Bottom HUD

    private var bottomHUD: some View {
        HStack(spacing: 0) {
            // Frequency / Note
            VStack(spacing: 4) {
                Text(noteName)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(HueWave.ink)
                Text(String(format: "%.0f Hz", handTracker.pitch))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(HueWave.inkSoft)
            }
            .frame(maxWidth: .infinity)

            // Amplitude meter
            VStack(spacing: 4) {
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(HueWave.ink.opacity(0.15))
                        .frame(width: 8, height: 60)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(HueWave.peach)
                        .frame(width: 8, height: CGFloat(handTracker.amplitude) * 60)
                        .animation(.easeOut(duration: 0.05), value: handTracker.amplitude)
                }
                Text("VOL")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(HueWave.inkFaint)
                    .tracking(1.5)
            }
            .frame(maxWidth: .infinity)

            // Filter cutoff
            VStack(spacing: 4) {
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(HueWave.ink.opacity(0.15))
                        .frame(width: 8, height: 60)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(HueWave.mint)
                        .frame(width: 8, height: CGFloat(handTracker.filterCutoff) * 60)
                        .animation(.easeOut(duration: 0.05), value: handTracker.filterCutoff)
                }
                Text("CUT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(HueWave.inkFaint)
                    .tracking(1.5)
            }
            .frame(maxWidth: .infinity)

            // Waveform type
            VStack(spacing: 4) {
                Image(systemName: synthEngine.currentWaveform.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(HueWave.peach)
                Text(synthEngine.currentWaveform.label.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(HueWave.inkFaint)
                    .tracking(1.5)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .glassEffect(.regular.tint(HueWave.bg.opacity(0.6)), in: .rect(cornerRadius: 24))
    }

    // MARK: - Drawing Functions

    private func drawWaveTrails(context: GraphicsContext, size: CGSize, time: Date) {
        let now = time.timeIntervalSinceReferenceDate

        // Prune old points
        waveTrails.removeAll { now - $0.timestamp > trailFadeDuration }

        guard waveTrails.count > 1 else { return }

        for i in 1..<waveTrails.count {
            let trail = waveTrails[i]
            let age = now - trail.timestamp
            let opacity = max(0, 1.0 - age / trailFadeDuration)
            let width = trail.size * CGFloat(opacity)

            var path = Path()
            path.move(to: waveTrails[i-1].point)
            path.addLine(to: trail.point)

            context.stroke(path, with: .color(trail.color.opacity(opacity)), lineWidth: width)
        }
    }

    private func drawHandLandmarks(context: GraphicsContext, size: CGSize) {
        // Draw left hand
        if let leftHand = handTracker.leftHand {
            drawHand(context: context, hand: leftHand, color: HueWave.peach)
        }

        // Draw right hand
        if let rightHand = handTracker.rightHand {
            drawHand(context: context, hand: rightHand, color: HueWave.mint)
        }
    }

    private func drawHand(context: GraphicsContext, hand: HandData, color: Color) {
        guard let screenPoints = try? hand.screenPoints else { return }

        // Draw connections between joints
        let connections: [(VNHumanHandPoseObservation.JointName, VNHumanHandPoseObservation.JointName)] = [
            (.wrist, .thumbCMC), (.thumbCMC, .thumbMP), (.thumbMP, .thumbIP), (.thumbIP, .thumbTip),
            (.wrist, .indexMCP), (.indexMCP, .indexPIP), (.indexPIP, .indexDIP), (.indexDIP, .indexTip),
            (.wrist, .middleMCP), (.middleMCP, .middlePIP), (.middlePIP, .middleDIP), (.middleDIP, .middleTip),
            (.wrist, .ringMCP), (.ringMCP, .ringPIP), (.ringPIP, .ringDIP), (.ringDIP, .ringTip),
            (.wrist, .littleMCP), (.littleMCP, .littlePIP), (.littlePIP, .littleDIP), (.littleDIP, .littleTip),
        ]

        for (j1, j2) in connections {
            guard let p1 = screenPoints[j1], let p2 = screenPoints[j2] else { continue }
            let start = CGPoint(x: p1.x * size.width, y: p1.y * size.height)
            let end = CGPoint(x: p2.x * size.width, y: p2.y * size.height)

            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            context.stroke(path, with: .color(color.opacity(0.4)), lineWidth: 2)
        }

        // Draw joints
        for (joint, point) in screenPoints {
            let x = point.x * size.width
            let y = point.y * size.height
            let radius: CGFloat = joint == .indexTip ? 8 : 4

            let circle = Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
            context.fill(circle, with: .color(joint == .indexTip ? color : color.opacity(0.7)))

            // Glow on index tip
            if joint == .indexTip {
                let glow = Path(ellipseIn: CGRect(x: x - radius * 2, y: y - radius * 2, width: radius * 4, height: radius * 4))
                context.fill(glow, with: .color(color.opacity(0.15)))

                // Add trail point
                let trailColor = Color(hue: Double(handTracker.pitch / 4000.0), saturation: 0.6, brightness: 0.9)
                let trailPoint = WaveTrailPoint(
                    point: CGPoint(x: x, y: y),
                    color: trailColor,
                    timestamp: Date().timeIntervalSinceReferenceDate,
                    size: CGFloat(2 + handTracker.amplitude * 8)
                )
                waveTrails.append(trailPoint)
                if waveTrails.count > maxTrailPoints {
                    waveTrails.removeFirst()
                }
            }
        }
    }

    private func drawCenterIndicator(context: GraphicsContext, size: CGSize) {
        guard handTracker.amplitude > 0.01 else { return }

        let centerX = size.width / 2
        let centerY = size.height / 2
        let radius = CGFloat(handTracker.amplitude) * 60

        let freqColor = Color(hue: Double(handTracker.pitch / 4000.0), saturation: 0.5, brightness: 0.9)

        let circle = Path(ellipseIn: CGRect(
            x: centerX - radius, y: centerY - radius,
            width: radius * 2, height: radius * 2
        ))
        context.fill(circle, with: .color(freqColor.opacity(0.12)))
    }

    private func drawParticleBursts(context: GraphicsContext, size: CGSize, time: Date) {
        let now = time.timeIntervalSinceReferenceDate
        particleBursts.removeAll { now - $0.timestamp > 0.8 }

        for burst in particleBursts {
            let age = now - burst.timestamp
            let progress = age / 0.8

            for i in 0..<burst.particleCount {
                let angle = Double(i) / Double(burst.particleCount) * .pi * 2
                let distance = progress * Double(burst.radius)
                let x = burst.center.x + CGFloat(cos(angle) * distance)
                let y = burst.center.y + CGFloat(sin(angle) * distance)
                let opacity = max(0, 1.0 - progress)
                let particleSize: CGFloat = 3 * CGFloat(opacity)

                let dot = Path(ellipseIn: CGRect(x: x - particleSize, y: y - particleSize,
                                                  width: particleSize * 2, height: particleSize * 2))
                context.fill(dot, with: .color(burst.color.opacity(opacity)))
            }
        }
    }

    // MARK: - Helpers

    private var noteName: String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let semitonesFromC4 = 12 * log2(handTracker.pitch / 261.63)
        let noteIndex = Int(round(semitonesFromC4)) % 12
        let octave = 4 + Int(round(semitonesFromC4)) / 12
        let safeIndex = noteIndex >= 0 ? noteIndex % 12 : (noteIndex % 12 + 12) % 12
        return "\(noteNames[safeIndex])\(octave)"
    }

    private func updateAudio() {
        synthEngine.writeParams(
            frequency: handTracker.pitch,
            amplitude: handTracker.amplitude,
            filterCutoff: handTracker.filterCutoff,
            waveform: handTracker.waveformType,
            gesture: handTracker.currentGesture == .fist ? 1 : 0
        )
    }

    private func handleGestureChange(_ gesture: HandGesture) {
        guard gesture != lastGesture else { return }
        lastGesture = gesture

        switch gesture {
        case .fist:
            haptics.playPercussive(intensity: 0.8)
            if let indexTip = handTracker.leftHand?.indexTip ?? handTracker.rightHand?.indexTip {
                let burst = ParticleBurst(
                    center: indexTip,
                    color: HueWave.peach,
                    particleCount: 12,
                    radius: 60,
                    timestamp: Date().timeIntervalSinceReferenceDate
                )
                particleBursts.append(burst)
            }
        case .pinch:
            haptics.playPercussive(intensity: 0.5)
        case .peace:
            haptics.playPercussive(intensity: 0.3)
        default:
            break
        }
    }
}

// MARK: - Particle Burst

struct ParticleBurst {
    let center: CGPoint
    let color: Color
    let particleCount: Int
    let radius: CGFloat
    let timestamp: TimeInterval
}

// MARK: - Settings Panel

struct SettingsPanel: View {
    @ObservedObject var handTracker: HandTracker
    @ObservedObject var synthEngine: SynthEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                HueWave.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Sensitivity
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Sensitivity")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(HueWave.ink)
                                HStack {
                                    Text("Responsive")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(HueWave.inkFaint)
                                    Slider(value: Binding(
                                        get: { Double(handTracker.sensitivity) },
                                        set: { handTracker.sensitivity = Float($0) }
                                    ), in: 0.5...0.95)
                                    .tint(HueWave.peach)
                                    Text("Smooth")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(HueWave.inkFaint)
                                }
                            }
                        }

                        // Frequency Range
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Frequency Range")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(HueWave.ink)
                                HStack(spacing: 12) {
                                    RangeButton(title: "Beginner", range: "80-2000 Hz", isSelected: handTracker.maxFrequency == 2000) {
                                        handTracker.maxFrequency = 2000
                                    }
                                    RangeButton(title: "Advanced", range: "80-4000 Hz", isSelected: handTracker.maxFrequency == 4000) {
                                        handTracker.maxFrequency = 4000
                                    }
                                }
                            }
                        }

                        // Waveform
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Waveform")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(HueWave.ink)
                                HStack(spacing: 8) {
                                    ForEach(SynthEngine.WaveformType.allCases, id: \.rawValue) { type in
                                        Button {
                                            synthEngine.setWaveform(type)
                                            handTracker.waveformType = type.rawValue
                                        } label: {
                                            VStack(spacing: 4) {
                                                Image(systemName: type.icon)
                                                    .font(.system(size: 18))
                                                Text(type.label)
                                                    .font(.system(.caption2, design: .rounded))
                                            }
                                            .foregroundStyle(synthEngine.currentWaveform == type ? HueWave.peach : HueWave.inkSoft)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .glassEffect(
                                                synthEngine.currentWaveform == type
                                                    ? .regular.tint(HueWave.peach.opacity(0.15))
                                                    : .regular,
                                                in: .rect(cornerRadius: 12)
                                            )
                                        }
                                    }
                                }
                            }
                        }

                        // Visual Mode
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Visual Mode")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(HueWave.ink)
                                Text("Show wave trails and particle effects")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(HueWave.inkSoft)
                            }
                        }

                        // Gesture Guide
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Gesture Guide")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(HueWave.ink)

                                GestureRow(gesture: "Point", desc: "Sustain — move for pitch & volume", icon: "hand.point.up.fill")
                                GestureRow(gesture: "Open Palm", desc: "Bright timbre, full filter", icon: "hand.raised.fill")
                                GestureRow(gesture: "Pinch", desc: "Dark/muted filter", icon: "hand.draw.fill")
                                GestureRow(gesture: "Fist", desc: "Percussive hit + particle burst", icon: "hand.raised.fist.fill")
                                GestureRow(gesture: "Peace", desc: "Mid-brightness, gentle haptic", icon: "hand.thumbsup.fill")
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(HueWave.peach)
                }
            }
        }
    }
}

// MARK: - Helpers

struct RangeButton: View {
    let title: String
    let range: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                Text(range)
                    .font(.system(.caption2, design: .monospaced))
            }
            .foregroundStyle(isSelected ? HueWave.ink : HueWave.inkSoft)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassEffect(
                isSelected ? .regular.tint(HueWave.peach.opacity(0.15)) : .regular,
                in: .rect(cornerRadius: 14)
            )
        }
    }
}

struct GestureRow: View {
    let gesture: String
    let desc: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(HueWave.peach)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(gesture)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(HueWave.ink)
                Text(desc)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(HueWave.inkSoft)
            }
        }
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    private let pages: [(title: String, subtitle: String, icon: String)] = [
        ("Move your hands. Make music.", "Your hands become the instrument — position controls pitch and volume.", "hand.raised.fill"),
        ("Left hand = pitch. Right hand = volume.", "Single hand works too — left side is pitch, right side is volume.", "arrow.left.arrow.right"),
        ("Pinch for timbre. Fist for percussion.", "Gesture changes the sound character. Fist triggers haptic feedback and particle bursts.", "hand.tap.fill")
    ]

    var body: some View {
        ZStack {
            MeshBackground()

            VStack(spacing: 40) {
                Spacer()

                // Icon
                Image(systemName: pages[currentPage].icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(HueWave.peach)
                    .frame(width: 120, height: 120)
                    .glassEffect(.regular.tint(HueWave.peach.opacity(0.1)), in: .circle)
                    .animation(.spring(response: 0.5), value: currentPage)

                // Text
                VStack(spacing: 12) {
                    Text(pages[currentPage].title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(HueWave.ink)
                        .multilineTextAlignment(.center)

                    Text(pages[currentPage].subtitle)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(HueWave.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                Spacer()

                // Page indicator + button
                VStack(spacing: 20) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Circle()
                                .fill(i == currentPage ? HueWave.peach : HueWave.inkFaint.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    if currentPage < pages.count - 1 {
                        GlassButton(title: "Next", icon: "arrow.right") {
                            withAnimation(.spring(response: 0.4)) {
                                currentPage += 1
                            }
                        }
                    } else {
                        GlassButton(title: "Start Playing", icon: "waveform") {
                            UserDefaults.standard.set(true, forKey: "onboardingComplete")
                            isPresented = false
                        }
                    }

                    Button("Skip") {
                        UserDefaults.standard.set(true, forKey: "onboardingComplete")
                        isPresented = false
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(HueWave.inkFaint)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}
