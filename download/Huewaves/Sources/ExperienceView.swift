import SwiftUI
import AVFoundation
import CoreHaptics

// MARK: - Experience View

struct ExperienceView: View {
    @State private var selectedMode: SensoryMode = .colorToSound

    var body: some View {
        ZStack {
            MeshBackground()

            VStack(spacing: 0) {
                navBar

                GlassEffectContainer {
                    HStack(spacing: 8) {
                        ForEach(SensoryMode.allCases, id: \.self) { mode in
                            ModeChip(mode: mode, isSelected: selectedMode == mode) {
                                withAnimation(.spring(response: 0.3)) { selectedMode = mode }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                ScrollView {
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
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private var navBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Huewaves")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(HueWave.ink)
                Text("Hear colors. See sound. Feel music.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(HueWave.inkFaint)
            }
            Spacer()
            GlowDot(color: HueWave.peach)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

// MARK: - Mode Chip

struct ModeChip: View {
    let mode: SensoryMode
    let isSelected: Bool
    let action: () -> Void

    private var tint: Color {
        switch mode {
        case .colorToSound: return HueWave.peach
        case .soundToVisual: return HueWave.coral
        case .audioToHaptic: return HueWave.mint
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isSelected ? tint : HueWave.inkFaint.opacity(0.3))
                    .frame(width: 8, height: 8)

                Text(mode.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? HueWave.ink : HueWave.inkFaint)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassEffect(.regular.tint(isSelected ? tint.opacity(0.15) : .clear), in: .capsule)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sensory Mode

enum SensoryMode: String, CaseIterable {
    case colorToSound = "See → Hear"
    case soundToVisual = "Hear → See"
    case audioToHaptic = "Feel → Understand"
}

// MARK: - Color → Sound View

struct ColorToSoundView: View {
    @State private var currentHue: Double = 0
    @State private var frequency: Float = 261.63
    @State private var noteName: String = "C4"
    @State private var isScanning = false
    @State private var audio = SynthAudioEngine()

    let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            stops: [
                                .init(color: HueWave.peach, location: 0),
                                .init(color: HueWave.sand, location: 0.17),
                                .init(color: HueWave.coral, location: 0.33),
                                .init(color: HueWave.peachDeep, location: 0.5),
                                .init(color: HueWave.blush, location: 0.67),
                                .init(color: HueWave.peach, location: 1)
                            ],
                            center: .center
                        ),
                        lineWidth: 8
                    )
                    .frame(width: 240, height: 240)

                Circle()
                    .fill(Color(hue: currentHue / 360, saturation: 0.4, brightness: 0.92))
                    .frame(width: 180, height: 180)
                    .shadow(color: Color(hue: currentHue / 360, saturation: 0.35, brightness: 0.85).opacity(0.25), radius: 16)

                VStack(spacing: 4) {
                    Text(noteName)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(HueWave.ink)
                    Text(String(format: "%.0f Hz", frequency))
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundStyle(HueWave.inkSoft)
                }
            }
            .frame(height: 260)

            VStack(spacing: 8) {
                Text("COLOR HUE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(HueWave.inkFaint)
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
                .tint(Color(hue: currentHue / 360, saturation: 0.45, brightness: 0.85))
            }

            mappingCard

            Spacer()
        }
        .onDisappear { audio.stopTone() }
    }

    private var mappingCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    Label("Visual", systemImage: "eye.fill")
                        .foregroundStyle(HueWave.peach)
                    Spacer()
                    Circle()
                        .fill(Color(hue: currentHue / 360, saturation: 0.4, brightness: 0.92))
                        .frame(width: 24, height: 24)
                }

                HStack {
                    Label("Auditory", systemImage: "waveform")
                        .foregroundStyle(HueWave.coral)
                    Spacer()
                    Text(noteName)
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(HueWave.ink)
                }

                HStack {
                    Label("Haptic", systemImage: "hand.tap.fill")
                        .foregroundStyle(HueWave.mint)
                    Spacer()
                    Text(isScanning ? "Active" : "Idle")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isScanning ? HueWave.peach : HueWave.inkFaint)
                }
            }
            .padding(20)
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

// MARK: - Sound → Visual View

struct SoundToVisualView: View {
    @State private var audioLevels: [Float] = Array(repeating: 0, count: 32)
    @State private var time: Double = 0
    @State private var mic = MicrophoneAnalyzer()
    private let pulse = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                GlassCard(cornerRadius: 24) {
                    Canvas { context, size in
                        let centerX = size.width / 2
                        let centerY = size.height / 2
                        let levels = mic.isLive ? mic.levels : audioLevels

                        for i in 0..<24 {
                            let angle = Double(i) / 24 * .pi * 2 + time
                            let level = CGFloat(max(0.02, min(1, levels[i % levels.count])))
                            let radius = 60 + level * 80
                            let x = centerX + CGFloat(cos(angle)) * radius
                            let y = centerY + CGFloat(sin(angle)) * radius

                            context.opacity = 0.25
                            context.fill(
                                Path(ellipseIn: CGRect(x: x - 22, y: y - 22, width: 44, height: 44)),
                                with: .color(Color(hue: angle / (.pi * 2), saturation: 0.35, brightness: 0.9 + level * 0.1))
                            )
                            context.opacity = 1.0
                            context.fill(
                                Path(ellipseIn: CGRect(x: x - 5, y: y - 5, width: 10, height: 10)),
                                with: .color(HueWave.ink)
                            )
                        }
                    }
                    .frame(height: 280)
                }
            }
            .frame(height: 300)

            HStack(spacing: 3) {
                ForEach(0..<32, id: \.self) { i in
                    let level = mic.isLive ? mic.levels[i] : audioLevels[i]
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(
                            colors: [
                                Color(hue: Double(i) / 32, saturation: 0.3, brightness: 0.92),
                                Color(hue: Double(i) / 32, saturation: 0.4, brightness: 0.88)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        ))
                        .frame(height: CGFloat(level) * 100)
                }
            }
            .frame(height: 100)

            GlassButton(
                title: mic.isLive ? "Stop Listening" : "Start Listening",
                icon: mic.isLive ? "stop.fill" : "mic.fill",
                action: { toggleListening() }
            )

            Spacer()
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
                let s1 = sin(time * 3 + Double(i) * 0.4) * 0.4
                let s2 = sin(time * 5 + Double(i) * 0.7) * 0.3
                let r = Double(Float.random(in: 0...0.3))
                audioLevels[i] = Float(s1 + s2 + r)
                audioLevels[i] = max(0.05, min(1, audioLevels[i]))
            }
        }
    }

    private func toggleListening() {
        if mic.isLive {
            mic.stop()
        } else {
            mic.start()
        }
    }
}

// MARK: - Audio → Haptic View

struct AudioToHapticView: View {
    @State private var isPlaying = false
    @State private var hapticPattern: HapticKind = .heartbeat
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.3
    @State private var haptics = HapticsController()

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [HueWave.peach.opacity(0.5), HueWave.mint.opacity(0.3)],
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
                    .foregroundStyle(LinearGradient(
                        colors: [HueWave.peach, HueWave.mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .scaleEffect(isPlaying ? pulseScale : 1)
            }
            .frame(height: 280)

            VStack(spacing: 12) {
                Text("PATTERN")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(HueWave.inkFaint)
                    .tracking(2)

                Picker("Pattern", selection: $hapticPattern) {
                    ForEach(HapticKind.allCases, id: \.self) { kind in
                        Text(kind.label).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
            }

            GlassButton(
                title: isPlaying ? "Experiencing…" : "Feel the Sound",
                icon: isPlaying ? "hand.raised.fill" : "hand.tap.fill",
                action: { togglePlay() }
            )

            Spacer()
        }
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
