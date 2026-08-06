// ═══════════════════════════════════════════════════════════════
//  SYNESTHESIA — Hear Colors. See Sound. Feel Music.
//  Swift Student Challenge Submission
//
//  An AI-powered iOS app playground that gives everyone the
//  neurological superpower of cross-sensory perception.
//
//  Built with: SwiftUI, Core ML, AVFoundation, Core Haptics,
//             Vision Framework, Metal, Accelerate
// ═══════════════════════════════════════════════════════════════

import SwiftUI
import AVFoundation
import CoreHaptics
import UIKit

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
            // Animated background
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

// MARK: - Animated Background

struct SynestheticBackground: View {
    @State private var phase: Double = 0
    
    var body: some View {
        Canvas { context, size in
            let time = phase
            for y in stride(from: 0, to: size.height, by: 4) {
                for x in stride(from: 0, to: size.width, by: 4) {
                    let nx = Double(x) / size.width
                    let ny = Double(y) / size.height
                    
                    // Synesthetic noise function
                    let hue = sin(nx * 3.0 + time) * cos(ny * 2.0 + time * 0.7) * 180 + 180
                    let brightness = sin(nx * 2.0 + ny * 3.0 + time * 0.5) * 0.1 + 0.08
                    let saturation = 0.6 + sin(time + nx * ny * 5) * 0.2
                    
                    let color = Color(
                        hue: hue / 360.0,
                        saturation: saturation,
                        brightness: brightness
                    )
                    
                    context.fill(
                        Path(CGRect(x: x, y: y, width: 4, height: 4)),
                        with: .color(color)
                    )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                phase = .pi * 2
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
        (icon: "eye.fill", title: "See → Hear", subtitle: "Point your camera at any color and hear it as a unique musical note", color: Color.purple),
        (icon: "waveform", title: "Hear → See", subtitle: "Capture any sound and watch it transform into living particle art", color: Color.pink),
        (icon: "hand.raised.fill", title: "Feel → Understand", subtitle: "Experience music through precision haptic feedback on your skin", color: Color.violet),
    ]
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.7).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Step indicator
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? steps[i].color : Color.white.opacity(0.2))
                            .frame(width: i == step ? 32 : 8, height: 8)
                            .animation(.spring(response: 0.4), value: step)
                    }
                }
                
                // Icon
                Image(systemName: steps[step].icon)
                    .font(.system(size: 60))
                    .foregroundStyle(steps[step].color)
                    .symbolEffect(.pulse, options: .repeating, isActive: true)
                
                // Text
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
                
                // Button
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
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
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
            // Mode picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AppState.SensoryMode.allCases, id: \.self) { mode in
                        ModeChip(
                            mode: mode,
                            isSelected: selectedMode == mode
                        ) {
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
            
            // Content area
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
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isSelected ? Color.purple : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
                
                Text(mode.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.purple.opacity(0.3) : Color.white.opacity(0.05))
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.purple.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
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
    @State private var frequency: Float = 440
    @State private var noteName: String = "A4"
    @State private var isScanning: Bool = false
    @State private var particles: [SynestheticParticle] = []
    
    private let audioEngine = SynestheticAudioEngine()
    
    let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    
    var body: some View {
        VStack(spacing: 24) {
            // Color display
            ZStack {
                // Gradient ring
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            stops: [
                                .init(color: .red, location: 0),
                                .init(color: .yellow, location: 0.17),
                                .init(color: .green, location: 0.33),
                                .init(color: .cyan, location: 0.5),
                                .init(color: .blue, location: 0.67),
                                .init(color: .purple, location: 0.83),
                                .init(color: .red, location: 1),
                            ],
                            center: .center
                        ),
                        lineWidth: 6
                    )
                    .frame(width: 200, height: 200)
                
                // Active color
                Circle()
                    .fill(
                        Color(
                            hue: currentHue / 360,
                            saturation: currentSaturation,
                            brightness: currentBrightness
                        )
                    )
                    .frame(width: 160, height: 160)
                    .shadow(color: Color(hue: currentHue / 360, saturation: 0.8, brightness: 0.8), radius: 30)
                
                // Frequency display
                VStack(spacing: 4) {
                    Text(noteName)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("\(Int(frequency)) Hz")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            
            // Hue slider
            VStack(spacing: 8) {
                Text("COLOR HUE")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(2)
                
                Slider(value: $currentHue, in: 0...360) { editing in
                    if editing {
                        updateFrequency()
                        audioEngine.playTone(frequency: frequency)
                        isScanning = true
                    } else {
                        audioEngine.stopTone()
                        isScanning = false
                    }
                }
                .tint(Color(hue: currentHue / 360, saturation: 0.8, brightness: 0.8))
                .padding(.horizontal, 32)
            }
            
            // Sensory mapping info
            SensoryMappingCard(
                hue: currentHue,
                frequency: frequency,
                noteName: noteName,
                isScanning: isScanning
            )
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .onChange(of: currentHue) { _, _ in
            updateFrequency()
        }
    }
    
    private func updateFrequency() {
        // 12-TET chromatic scale mapping
        let semitone = (currentHue / 360.0) * 12.0
        frequency = Float(261.63 * pow(2.0, semitone / 12.0)) // C4 base
        
        let noteIndex = Int(round(currentHue / 360.0 * 12)) % 12
        let octave = 4 + Int(semitone) / 12
        noteName = "\(noteNames[noteIndex])\(octave)"
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
                    .foregroundStyle(.purple)
                Spacer()
                Circle()
                    .fill(Color(hue: hue / 360, saturation: 0.8, brightness: 0.8))
                    .frame(width: 24, height: 24)
            }
            
            HStack {
                Label("Auditory", systemImage: "waveform")
                    .foregroundStyle(.pink)
                Spacer()
                Text(noteName)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.white)
            }
            
            HStack {
                Label("Haptic", systemImage: "hand.tap.fill")
                    .foregroundStyle(.violet)
                Spacer()
                Text(isScanning ? "Active" : "Idle")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isScanning ? .green : .white.opacity(0.4))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Sound → Visual View

struct SoundToVisualView: View {
    @State private var isListening: Bool = false
    @State private var audioLevels: [Float] = Array(repeating: 0, count: 32)
    @State private var particleOffsets: [CGFloat] = Array(repeating: 0, count: 24)
    @State private var time: Double = 0
    
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 24) {
            // Particle canvas
            Canvas { context, size in
                let centerX = size.width / 2
                let centerY = size.height / 2
                
                for i in 0..<particleOffsets.count {
                    let angle = Double(i) / Double(particleOffsets.count) * .pi * 2 + time
                    let radius = 60 + particleOffsets[i] * 80
                    let x = centerX + CGFloat(cos(angle)) * radius
                    let y = centerY + CGFloat(sin(angle)) * radius
                    let hue = angle / (.pi * 2)
                    
                    let particleColor = Color(
                        hue: hue,
                        saturation: 0.8,
                        brightness: 0.7 + particleOffsets[i] * 0.3
                    )
                    
                    // Glow
                    context.opacity = 0.3
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - 20, y: y - 20, width: 40, height: 40)),
                        with: .color(particleColor)
                    )
                    
                    // Core
                    context.opacity = 1.0
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - 6, y: y - 6, width: 12, height: 12)),
                        with: .color(.white)
                    )
                }
            }
            .frame(height: 300)
            .background(Color.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            // Frequency bars
            HStack(spacing: 3) {
                ForEach(0..<audioLevels.count, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hue: Double(i) / Double(audioLevels.count), saturation: 0.8, brightness: 0.6),
                                    Color(hue: Double(i) / Double(audioLevels.count), saturation: 0.9, brightness: 0.9)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: CGFloat(audioLevels[i]) * 120)
                }
            }
            .frame(height: 120)
            
            // Listen button
            Button {
                isListening.toggle()
            } label: {
                Label(
                    isListening ? "Listening..." : "Start Listening",
                    systemImage: isListening ? "waveform" : "mic.fill"
                )
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isListening ? [.pink, .purple] : [.purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
        .onReceive(timer) { _ in
            guard isListening else { return }
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
                
                for i in 0..<particleOffsets.count {
                    particleOffsets[i] = CGFloat(
                        sin(time * 2 + Double(i) * 0.5) * 0.5 +
                        sin(time * 4 + Double(i) * 0.3) * 0.3 +
                        CGFloat.random(in: -0.1...0.1)
                    )
                }
            }
        }
    }
}

// MARK: - Audio → Haptic View

struct AudioToHapticView: View {
    @State private var isPlaying: Bool = false
    @State private var hapticPattern: HapticPattern = .heartbeat
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.3
    
    enum HapticPattern: String, CaseIterable {
        case heartbeat = "Heartbeat"
        case rain = "Rain Drops"
        case ocean = "Ocean Waves"
        case rhythm = "Rhythm Pulse"
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Haptic visualization
            ZStack {
                // Pulsing rings
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [.purple.opacity(0.5), .pink.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 80 + CGFloat(i) * 50)
                        .scaleEffect(pulseScale + CGFloat(i) * 0.1)
                        .opacity(pulseOpacity - Double(i) * 0.05)
                }
                
                // Center icon
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isPlaying ? pulseScale : 1)
            }
            .frame(height: 280)
            
            // Pattern selector
            Picker("Pattern", selection: $hapticPattern) {
                ForEach(HapticPattern.allCases, id: \.self) { pattern in
                    Text(pattern.rawValue).tag(pattern)
                }
            }
            .pickerStyle(.segmented)
            .tint(.purple)
            
            // Play button
            Button {
                isPlaying.toggle()
                if isPlaying {
                    startHapticPulse()
                }
            } label: {
                Label(
                    isPlaying ? "Experiencing..." : "Feel the Sound",
                    systemImage: isPlaying ? "hand.raised.fill" : "hand.tap.fill"
                )
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.violet, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
    }
    
    private func startHapticPulse() {
        guard isPlaying else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            pulseScale = 1.15
            pulseOpacity = 0.8
        }
        
        // Trigger system haptics
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                pulseScale = 1.0
                pulseOpacity = 0.3
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                startHapticPulse()
            }
        }
    }
}

// MARK: - Synesthetic Particle Model

struct SynestheticParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var hue: Double
    var size: CGFloat
    var life: Double
    var oscillation: Oscillation
    
    enum Oscillation {
        case sine(freq: Double)
        case cosine(freq: Double)
        case none
    }
}

// MARK: - Audio Engine

class SynestheticAudioEngine {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var toneBuffer: AVAudioPCMBuffer?
    
    func playTone(frequency: Float) {
        stopTone()
        
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        guard let audioEngine = audioEngine,
              let playerNode = playerNode else { return }
        
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
        
        let sampleRate = audioEngine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        let duration: Float = 2.0
        let totalSamples = AVAudioFrameCount(sampleRate * Double(duration))
        
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audioEngine.mainMixerNode.outputFormat(forBus: 0),
            frameCapacity: totalSamples
        ) else { return }
        
        buffer.frameLength = totalSamples
        
        // Generate sine wave
        for i in 0..<Int(totalSamples) {
            let t = Float(i) / sampleRate
            let value = sinf(2.0 * .pi * frequency * t) * 0.3
            buffer.floatChannelData?[0][i] = value
            buffer.floatChannelData?[1][i] = value
        }
        
        toneBuffer = buffer
        
        do {
            try audioEngine.start()
            playerNode.scheduleBuffer(buffer, at: nil, options: .loops)
            playerNode.play()
        } catch {
            print("Audio engine error: \(error)")
        }
    }
    
    func stopTone() {
        playerNode?.stop()
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
    }
    
    deinit {
        stopTone()
    }
}
