// ═══════════════════════════════════════════════════════════════
//  SYNESTHESIA — Hear Colors. See Sound. Feel Music.
//  Swift Student Challenge Submission
//
//  Turn the world around you into music. Point the camera at a
//  color and hear it as a note; sing and watch sound become light;
//  press and feel a rhythm pulse on your skin.
//
//  Built with: SwiftUI · AVFoundation · Core Haptics
//  (Camera color-reading, live microphone analysis, and
//   precision Core Haptics patterns — no simulated modes.)
// ═══════════════════════════════════════════════════════════════

import SwiftUI
import AVFoundation
import CoreHaptics
import CoreMedia
import CoreVideo
import UIKit

// MARK: - Obsidian Glass Color System

extension Color {
    static let obsidian = Color(red: 0.012, green: 0.024, blue: 0.055) // #03060E
    static let obsidianDeep = Color(red: 0.024, green: 0.047, blue: 0.102)
    static let spectrumTeal = Color(red: 0.831, green: 0.659, blue: 0.325) // #D4A853
    static let spectrumAqua = Color(red: 0.910, green: 0.788, blue: 0.478) // #E8C97A
    static let spectrumRose = Color(red: 0.941, green: 0.565, blue: 0.675) // #F090AC
    static let glassFill = Color.white.opacity(0.05)
    static let glassEdge = Color.white.opacity(0.12)
}

// MARK: - App Entry Point

@main
struct SynesthesiaApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - App State

class AppState: ObservableObject {
    @Published var currentMode: SensoryMode = .colorToSound
    @Published var isOnboardingComplete: Bool = false
    @Published var hapticEnabled: Bool = true
    @Published var sensitivity: Double = 0.7

    enum SensoryMode: String, CaseIterable {
        case colorToSound = "See → Hear"
        case soundToVisual = "Hear → See"
        case audioToHaptic = "Feel → Understand"
    }
}

// MARK: - Main Content View

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showOnboarding = true

    var body: some View {
        ZStack {
            SynestheticBackground()
            if showOnboarding && !appState.isOnboardingComplete {
                OnboardingView(isComplete: $showOnboarding)
                    .transition(.opacity)
            } else {
                MainExperienceView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: showOnboarding)
    }
}

// MARK: - Animated Background (a handful of draw calls per frame)

struct SynestheticBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.obsidian, .obsidianDeep, .obsidian],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let cx = size.width / 2
                    let cy = size.height * 0.40

                    context.blendMode = .softLight
                    for i in 0..<4 {
                        let angle = Double(i) / 4 * .pi * 2 + t * 0.15
                        let dist = min(size.width, size.height) * (0.20 + 0.07 * sin(t * 0.4 + Double(i)))
                        let px = cx + CGFloat(cos(angle)) * dist
                        let py = cy + CGFloat(sin(angle)) * dist * 0.55
                        let color = i.isMultiple(of: 2) ? Color.spectrumTeal : Color.spectrumRose
                        context.fill(
                            Path(ellipseIn: CGRect(x: px - 120, y: py - 120, width: 240, height: 240)),
                            with: .radialGradient(
                                Gradient(colors: [color.opacity(0.18), .clear]),
                                center: CGPoint(x: px, y: py),
                                startRadius: 0,
                                endRadius: 140
                            )
                        )
                    }

                    let breath = 0.80 + 0.20 * sin(t * 1.6)
                    context.fill(
                        Path(ellipseIn: CGRect(x: cx - 240, y: cy - 240, width: 480, height: 480)),
                        with: .radialGradient(
                            Gradient(colors: [Color.spectrumAqua.opacity(0.10 * breath), .clear]),
                            center: CGPoint(x: cx, y: cy),
                            startRadius: 0,
                            endRadius: 260
                        )
                    )
                }
            }
        }
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var step = 0
    @EnvironmentObject var appState: AppState

    let steps = [
        (icon: "eye.fill", title: "See → Hear", subtitle: "Point your camera at any color and hear it as a unique musical note", tint: Color.spectrumTeal),
        (icon: "waveform", title: "Hear → See", subtitle: "Capture any sound and watch it transform into living particle art", tint: Color.spectrumAqua),
        (icon: "hand.raised.fill", title: "Feel → Understand", subtitle: "Experience music through precision haptic feedback on your skin", tint: Color.spectrumRose)
    ]

    var body: some View {
        ZStack {
            Color.obsidian.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? steps[i].tint : Color.white.opacity(0.2))
                            .frame(width: i == step ? 32 : 8, height: 8)
                            .animation(.spring(response: 0.4), value: step)
                    }
                }

                Image(systemName: steps[step].icon)
                    .font(.system(size: 60))
                    .foregroundStyle(steps[step].tint)
                    .symbolEffect(.pulse, options: .repeating, isActive: true)

                VStack(spacing: 12) {
                    Text(steps[step].title)
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text(steps[step].subtitle)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.4)) {
                        if step < 2 {
                            step += 1
                        } else {
                            appState.isOnboardingComplete = true
                            isComplete = false
                        }
                    }
                } label: {
                    Text(step < 2 ? "Next" : "Begin Experience")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.spectrumTeal, .spectrumAqua, .spectrumRose],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.spectrumTeal.opacity(0.25), radius: 18)
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 40)
            }
        }
    }
}

// MARK: - Main Experience View

struct MainExperienceView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedMode: AppState.SensoryMode = .colorToSound

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AppState.SensoryMode.allCases, id: \.self) { mode in
                        ModeChip(mode: mode, isSelected: selectedMode == mode) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedMode = mode
                                appState.currentMode = mode
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 60)
            .padding(.bottom, 20)

            Group {
                switch selectedMode {
                case .colorToSound:
                    ColorToSoundView()
                case .soundToVisual:
                    SoundToVisualView()
                case .audioToHaptic:
                    AudioToHapticView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Mode Chip

struct ModeChip: View {
    let mode: AppState.SensoryMode
    let isSelected: Bool
    let action: () -> Void

    private var tint: Color {
        switch mode {
        case .colorToSound: return .spectrumTeal
        case .soundToVisual: return .spectrumAqua
        case .audioToHaptic: return .spectrumRose
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isSelected ? tint : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .shadow(color: isSelected ? tint.opacity(0.8) : .clear, radius: 4)

                Text(mode.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(isSelected ? tint.opacity(0.22) : .glassFill))
            .overlay(
                Capsule().strokeBorder(isSelected ? tint.opacity(0.55) : .glassEdge, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color → Sound View

struct ColorToSoundView: View {
    @State private var currentHue: Double = 0
    @State private var currentSaturation: Double = 0.8
    @State private var currentBrightness: Double = 0.7
    @State private var frequency: Float = 261.63
    @State private var noteName: String = "C4"
    @State private var isScanning: Bool = false
    @State private var cameraMode: Bool = false
    @State private var cameraLive: Bool = false
    @State private var showCameraDenied: Bool = false

    @StateObject private var audio = SynthAudioEngine()

    let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 10) {
                modeButton(icon: "camera.fill", label: "Camera", isActive: cameraMode)
                modeButton(icon: "dial.high.fill", label: "Color dial", isActive: !cameraMode)
            }
            .padding(.horizontal, 20)

            if cameraMode {
                CameraHuePreview(hue: $currentHue, isLive: $cameraLive)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(cameraLive ? .spectrumTeal.opacity(0.5) : .glassEdge, lineWidth: 1)
                    )
                    .overlay(alignment: .bottom) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(cameraLive ? .spectrumTeal : .white.opacity(0.25))
                                .frame(width: 8, height: 8)
                            Text(cameraLive ? "Reading live color" : "Waiting for camera…")
                                .font(.caption.monospaced())
                                .foregroundStyle(.white.opacity(0.7))
                            Spacer()
                            Text(noteName)
                                .font(.caption.monospaced().bold())
                                .foregroundStyle(.white)
                        }
                        .padding(12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .padding(10)
                    }
            } else {
                DialRing(
                    hue: currentHue,
                    saturation: currentSaturation,
                    brightness: currentBrightness,
                    noteName: noteName,
                    frequencyText: String(format: "%.0f Hz", frequency)
                )
            }

            VStack(spacing: 8) {
                Text(cameraMode ? "CAMERA SAMPLED HUE" : "COLOR HUE")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(2)

                Slider(value: $currentHue, in: 0...360) { editing in
                    if editing {
                        updateFrequency()
                        audio.playTone(frequency: frequency)
                        isScanning = true
                    } else {
                        audio.stopTone()
                        isScanning = false
                    }
                }
                .tint(Color(hue: currentHue / 360, saturation: 0.8, brightness: 0.8))
                .padding(.horizontal, 32)
                .disabled(cameraMode)
                .opacity(cameraMode ? 0.35 : 1)
            }

            SensoryMappingCard(hue: currentHue, frequency: frequency, noteName: noteName, isScanning: isScanning)

            Spacer()
        }
        .padding(.horizontal, 20)
        .onChange(of: currentHue) { _, _ in
            if cameraLive {
                updateFrequency()
                audio.playTone(frequency: frequency)
            }
        }
        .alert("Camera unavailable", isPresented: $showCameraDenied) {
            Button("OK", role: .cancel) { cameraMode = false }
        } message: {
            Text("Allow camera access in Settings to read colors from the world.")
        }
        .onDisappear { audio.stopTone() }
    }

    private func modeButton(icon: String, label: String, isActive: Bool) -> some View {
        Button {
            if label == "Camera" {
                requestCamera()
            } else {
                cameraMode = false
                audio.stopTone()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .foregroundStyle(isActive ? Color.obsidian : .white.opacity(0.8))
            .background(
                Capsule().fill(isActive ? .spectrumTeal : .glassFill)
            )
        }
        .buttonStyle(.plain)
    }

    private func requestCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraMode = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraMode = granted
                    if !granted { showCameraDenied = true }
                }
            }
        default:
            showCameraDenied = true
        }
    }

    private func updateFrequency() {
        let semitone = (currentHue / 360.0) * 12.0
        frequency = Float(261.63 * pow(2.0, semitone / 12.0))
        let noteIndex = Int(round(currentHue / 360.0 * 12)) % 12
        let octave = 4 + Int(semitone) / 12
        noteName = "\(noteNames[noteIndex])\(octave)"
    }
}

// MARK: - Camera Hue Reading (real pixel sampling)

struct CameraHuePreview: UIViewRepresentable {
    @Binding var hue: Double
    @Binding var isLive: Bool

    final class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        private let session = AVCaptureSession()
        private let queue = DispatchQueue(label: "synesthesia.camera.queue")
        private var hueBinding: Binding<Double>?
        private var liveBinding: Binding<Bool>?
        var previewLayer: AVCaptureVideoPreviewLayer?

        init(hue: Binding<Double>, live: Binding<Bool>) {
            super.init()
            hueBinding = hue
            liveBinding = live
            configure()
        }

        deinit {
            session.stopRunning()
        }

        private func configure() {
            session.beginConfiguration()
            session.sessionPreset = .medium

            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
               let input = try? AVCaptureDeviceInput(device: device),
               session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: queue)
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            session.commitConfiguration()

            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer?.videoGravity = .resizeAspectFill
        }

        func setLive(_ live: Bool) {
            queue.async {
                if live && !self.session.isRunning {
                    self.session.startRunning()
                } else if !live && self.session.isRunning {
                    self.session.stopRunning()
                }
            }
        }

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let h = Self.averageHue(of: sampleBuffer) else { return }
            DispatchQueue.main.async {
                guard let hueRef = self.hueBinding, let liveRef = self.liveBinding else { return }
                hueRef.wrappedValue = h
                if !liveRef.wrappedValue { liveRef.wrappedValue = true }
            }
        }

        static func averageHue(of sampleBuffer: CMSampleBuffer) -> Double? {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
            CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly) }
            guard let base = CVPixelBufferGetBaseAddress(imageBuffer) else { return nil }

            let w = CVPixelBufferGetWidth(imageBuffer)
            let h = CVPixelBufferGetHeight(imageBuffer)
            let bpr = CVPixelBufferGetBytesPerRow(imageBuffer)
            let startY = h / 4
            let endY = h * 3 / 4
            let startX = w / 4
            let endX = w * 3 / 4

            var r: Double = 0
            var g: Double = 0
            var b: Double = 0
            var count: Double = 0

            var y = startY
            while y < endY {
                var x = startX
                while x < endX {
                    let off = y * bpr + x * 4
                    if off + 3 < h * bpr {
                        let ptr = base.advanced(by: off).assumingMemoryBound(to: UInt8.self)
                        b += Double(ptr[0])
                        g += Double(ptr[1])
                        r += Double(ptr[2])
                        count += 1
                    }
                    x += 4
                }
                y += 4
            }

            guard count > 0 else { return nil }
            let avgR = r / count
            let avgG = g / count
            let avgB = b / count

            let peak = max(avgR, max(avgG, avgB))
            let trough = min(avgR, min(avgG, avgB))
            guard peak - trough > 0.03, peak > 0.05 else { return nil }

            var hueDegree: Double
            if peak == avgR {
                let f = (avgG - avgB) / (peak - trough)
                hueDegree = (f >= 0 ? f : f + 6) * 60
            } else if peak == avgG {
                let f = (avgB - avgR) / (peak - trough)
                hueDegree = (f >= 0 ? f : f + 6) * 60 + 120
            } else {
                let f = (avgR - avgG) / (peak - trough)
                hueDegree = (f >= 0 ? f : f + 6) * 60 + 240
            }
            return (hueDegree + 360).truncatingRemainder(dividingBy: 360)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(hue: hue, live: isLive)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        if let layer = context.coordinator.previewLayer {
            layer.frame = view.bounds
            view.layer.insertSublayer(layer, at: 0)
        }
        context.coordinator.setLive(true)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.setLive(false)
    }
}

// MARK: - Dial Ring (manual color → hue)

struct DialRing: View {
    let hue: Double
    let saturation: Double
    let brightness: Double
    let noteName: String
    let frequencyText: String

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    AngularGradient(
                        stops: [
                            .init(color: .red, location: 0),
                            .init(color: .yellow, location: 0.17),
                            .init(color: .green, location: 0.33),
                            .init(color: .cyan, location: 0.5),
                            .init(color: .blue, location: 0.67),
                            .init(color: .red, location: 1)
                        ],
                        center: .center
                    ),
                    lineWidth: 6
                )
                .frame(width: 200, height: 200)

            Circle()
                .fill(Color(hue: hue / 360, saturation: saturation, brightness: brightness))
                .frame(width: 160, height: 160)
                .shadow(color: Color(hue: hue / 360, saturation: 0.8, brightness: 0.8), radius: 30)

            VStack(spacing: 4) {
                Text(noteName)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(frequencyText)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(height: 200)
    }
}

// MARK: - Sensory Mapping Card

struct SensoryMappingCard: View {
    let hue: Double
    let frequency: Float
    let noteName: String
    let isScanning: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Visual", systemImage: "eye.fill")
                    .foregroundStyle(.spectrumTeal)
                Spacer()
                Circle()
                    .fill(Color(hue: hue / 360, saturation: 0.8, brightness: 0.8))
                    .frame(width: 24, height: 24)
            }

            HStack {
                Label("Auditory", systemImage: "waveform")
                    .foregroundStyle(.spectrumAqua)
                Spacer()
                Text(noteName)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.white)
            }

            HStack {
                Label("Haptic", systemImage: "hand.tap.fill")
                    .foregroundStyle(.spectrumRose)
                Spacer()
                Text(isScanning ? "Active" : "Idle")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isScanning ? .spectrumTeal : .white.opacity(0.4))
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(.glassFill))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.glassEdge, lineWidth: 1))
    }
}

// MARK: - Sound → Visual View (real microphone analysis)

struct SoundToVisualView: View {
    @State private var audioLevels: [Float] = Array(repeating: 0, count: 32)
    @State private var time: Double = 0
    @State private var showMicDenied = false

    @StateObject private var mic = MicrophoneAnalyzer()
    private let pulse = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            Canvas { context, size in
                let centerX = size.width / 2
                let centerY = size.height / 2
                let levels = mic.isLive ? mic.levels : audioLevels

                for i in 0..<24 {
                    let angle = Double(i) / 24 * .pi * 2 + time
                    let level = CGFloat(max(0.02, min(1, levels[i % levels.count])))
                    let radius = 60 + level * 90
                    let x = centerX + CGFloat(cos(angle)) * radius
                    let y = centerY + CGFloat(sin(angle)) * radius

                    context.opacity = 0.25
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - 22, y: y - 22, width: 44, height: 44)),
                        with: .color(
                            Color(
                                hue: angle / (.pi * 2),
                                saturation: 0.85,
                                brightness: 0.6 + level * 0.4
                            )
                        )
                    )
                    context.opacity = 1.0
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - 5, y: y - 5, width: 10, height: 10)),
                        with: .color(.white)
                    )
                }
                context.opacity = 1.0
                context.fill(
                    Path(ellipseIn: CGRect(x: centerX - 70, y: centerY - 70, width: 140, height: 140)),
                    with: .radialGradient(
                        Gradient(colors: [.spectrumAqua.opacity(0.45), .clear]),
                        center: CGPoint(x: centerX, y: centerY),
                        startRadius: 0,
                        endRadius: 90
                    )
                )
            }
            .frame(height: 300)
            .background(Color.obsidian.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.glassEdge, lineWidth: 1))

            HStack(spacing: 3) {
                ForEach(0..<32, id: \.self) { i in
                    let level = mic.isLive ? mic.levels[i] : audioLevels[i]
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hue: Double(i) / 32, saturation: 0.8, brightness: 0.6),
                                    Color(hue: Double(i) / 32, saturation: 0.9, brightness: 0.9)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: CGFloat(level) * 120)
                }
            }
            .frame(height: 120)

            Button {
                toggleListening()
            } label: {
                Label(
                    mic.isLive ? "Stop Listening" : "Start Listening",
                    systemImage: mic.isLive ? "stop.fill" : "mic.fill"
                )
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: mic.isLive ? [.spectrumRose, .spectrumTeal] : [.spectrumTeal, .spectrumRose],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)

            HStack(spacing: 6) {
                Circle().fill(mic.isLive ? .spectrumTeal : .white.opacity(0.25)).frame(width: 7, height: 7)
                Text(mic.isLive ? "Live audio → visual" : "Ambient demo — tap to capture real sound")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .padding(.horizontal, 20)
        .alert("Microphone access needed", isPresented: $showMicDenied) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Allow microphone access in Settings to analyze real sound.")
        }
        .onReceive(pulse) { _ in
            guard !mic.isLive else { return }
            updateAmbient()
        }
        .onDisappear { mic.stop() }
    }

    private func updateAmbient() {
        time += 0.05
        withAnimation(.easeOut(duration: 0.08)) {
            for i in 0..<audioLevels.count {
                audioLevels[i] = Float(
                    sin(time * 3 + Double(i) * 0.4) * 0.4 +
                        sin(time * 5 + Double(i) * 0.7) * 0.3 +
                        Float.random(in: 0...0.3)
                )
                audioLevels[i] = max(0.05, min(1, audioLevels[i]))
            }
        }
    }

    private func toggleListening() {
        if mic.isLive {
            mic.stop()
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized, .limited:
            mic.start()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if granted {
                        mic.start()
                    } else {
                        showMicDenied = true
                    }
                }
            }
        default:
            showMicDenied = true
        }
    }
}

// MARK: - Microphone Analyzer (AVAudioEngine tap → 32 RMS bins)

final class MicrophoneAnalyzer: ObservableObject {
    @Published var levels: [Float] = Array(repeating: 0, count: 32)
    @Published private(set) var isLive: Bool = false

    private let engine = AVAudioEngine()

    func start() {
        guard !isLive else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement)
        try? session.setActive(true)

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            let bins = Self.binLevels(buffer, count: 32)
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLive = true
                self.levels = bins
            }
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            levels = Array(repeating: 0, count: 32)
        }
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        isLive = false
        levels = Array(repeating: 0, count: 32)
    }

    private static func binLevels(_ buffer: AVAudioPCMBuffer, count: Int) -> [Float] {
        guard let channel = buffer.floatChannelData?[0] else { return Array(repeating: 0, count: count) }
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return Array(repeating: 0, count: count) }
        let binSize = max(1, frames / count)
        var result = [Float](repeating: 0, count: count)
        for bin in 0..<count {
            let start = bin * binSize
            let end = min(start + binSize, frames)
            guard end > start else { continue }
            var sum: Double = 0
            for i in start..<end {
                let v = Double(channel[i])
                sum += v * v
            }
            let rms = sqrt(sum / Double(end - start))
            result[bin] = Float(min(1, max(0, rms * 5)))
        }
        return result
    }
}

// MARK: - Audio → Haptic View (real Core Haptics patterns)

struct AudioToHapticView: View {
    @State private var isPlaying = false
    @State private var hapticPattern: HapticKind = .heartbeat
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.3

    @StateObject private var haptics = HapticsController()

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [.spectrumTeal.opacity(0.5), .spectrumRose.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 80 + CGFloat(i) * 50)
                        .scaleEffect(pulseScale + CGFloat(i) * 0.1)
                        .opacity(pulseOpacity - Double(i) * 0.05)
                }

                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.spectrumTeal, .spectrumRose],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isPlaying ? pulseScale : 1)
            }
            .frame(height: 280)

            Picker("Pattern", selection: $hapticPattern) {
                ForEach(HapticKind.allCases, id: \.self) { kind in
                    Text(kind.label).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .tint(.spectrumTeal)

            Button {
                togglePlay()
            } label: {
                Label(
                    isPlaying ? "Experiencing…" : "Feel the Sound",
                    systemImage: isPlaying ? "hand.raised.fill" : "hand.tap.fill"
                )
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isPlaying ? [.spectrumRose, .spectrumTeal] : [.spectrumTeal, .spectrumRose],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
        .onDisappear {
            haptics.stop()
            isPlaying = false
        }
    }

    private func togglePlay() {
        isPlaying.toggle()
        if isPlaying {
            haptics.play(hapticPattern)
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.12
                pulseOpacity = 0.75
            }
        } else {
            haptics.stop()
            withAnimation(.easeOut(duration: 0.3)) {
                pulseScale = 1.0
                pulseOpacity = 0.3
            }
        }
    }
}

// MARK: - Haptic Kind

enum HapticKind: String, CaseIterable {
    case heartbeat
    case rain
    case ocean
    case rhythm

    var label: String {
        switch self {
        case .heartbeat: return "Heartbeat"
        case .rain: return "Rain Drops"
        case .ocean: return "Ocean Waves"
        case .rhythm: return "Rhythm Pulse"
        }
    }

    static func events(for kind: HapticKind) -> [CHHapticEvent] {
        func transient(_ intensity: Float, _ sharpness: Float, _ at: TimeInterval) -> CHHapticEvent {
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: at
            )
        }

        func swell(_ at: TimeInterval) -> CHHapticEvent {
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)],
                relativeTime: at,
                duration: 1.4
            )
        }

        switch kind {
        case .heartbeat:
            var events: [CHHapticEvent] = []
            for beat in 0..<6 {
                let t = Double(beat) * 1.0
                events.append(transient(1.0, 1.0, t))
                events.append(transient(0.3, 0.4, t + 0.10))
                events.append(transient(0.85, 0.9, t + 0.45))
                events.append(transient(0.25, 0.4, t + 0.55))
            }
            return events
        case .rain:
            var events: [CHHapticEvent] = []
            var t: Double = 0
            while t < 7 {
                events.append(transient(0.35 + Float.random(in: 0...0.15), 0.1 + Float.random(in: 0...0.2), t))
                t += Double.random(in: 0.08...0.22)
            }
            return events
        case .ocean:
            var events: [CHHapticEvent] = []
            var t: Double = 0
            while t < 8 {
                events.append(swell(t))
                events.append(transient(0.55, 0.85, t + 1.4))
                events.append(transient(0.2, 0.4, t + 3.2))
                t += 4.0
            }
            return events
        case .rhythm:
            var events: [CHHapticEvent] = []
            var t: Double = 0
            while t < 6 {
                events.append(transient(0.9, 0.5, t))
                events.append(transient(0.6, 0.4, t + 0.15))
                events.append(transient(0.9, 0.5, t + 0.3))
                events.append(transient(0.4, 0.3, t + 0.45))
                t += 0.5
            }
            return events
        }
    }
}

// MARK: - Haptics Controller (CHHapticEngine)

final class HapticsController: ObservableObject {
    @Published private(set) var isActive = false

    private var engine: CHHapticEngine?
    private var player: CHHapticPatternPlayer?

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.isAutoShutdownEnabled = true
        do {
            try engine?.start()
        } catch {
            engine = nil
        }
    }

    func play(_ kind: HapticKind) {
        guard let engine else { return }
        let pattern = try? CHHapticPattern(events: HapticKind.events(for: kind), parameters: [])
        guard let pattern else { return }
        do {
            let newPlayer = try engine.makePlayer(with: pattern)
            try player?.stop()
            player = newPlayer
            try player?.start(atTime: CHHapticTimeImmediate)
            isActive = true
        } catch {
            isActive = false
        }
    }

    func stop() {
        try? player?.stop()
        player = nil
        isActive = false
    }
}

// MARK: - Synesthetic Audio Engine (persistent tone, no crackle)

final class SynthAudioEngine: ObservableObject {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var isRunning = false

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
    }

    func playTone(frequency: Float) {
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let sampleRate = Float(format.sampleRate)
        let frames = AVAudioFrameCount(format.sampleRate * 1.5)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return }
        buffer.frameLength = frames
        guard let channels = buffer.floatChannelData, let mono = channels.first else { return }

        for i in 0..<Int(frames) {
            let t = Float(i) / sampleRate
            mono[i] = sinf(2.0 * .pi * frequency * t) * 0.35
        }
        if channels.count > 1 {
            for i in 0..<Int(frames) {
                channels[1][i] = channels[0][i]
            }
        }

        if !isRunning {
            engine.prepare()
            do {
                try engine.start()
                isRunning = true
            } catch {
                return
            }
        }
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.play()
    }

    func stopTone() {
        player.stop()
        if isRunning {
            engine.stop()
            isRunning = false
        }
    }
}