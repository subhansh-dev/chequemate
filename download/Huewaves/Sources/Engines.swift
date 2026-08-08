import Foundation
import AVFoundation
import CoreHaptics

// MARK: - Microphone Analyzer

@MainActor
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

// MARK: - Haptics Controller

@MainActor
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
            try player?.stop(atTime: 0)
            player = newPlayer
            try player?.start(atTime: CHHapticTimeImmediate)
            isActive = true
        } catch {
            isActive = false
        }
    }

    func stop() {
        try? player?.stop(atTime: 0)
        player = nil
        isActive = false
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

// MARK: - Synth Audio Engine

@MainActor
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
        guard let channels = buffer.floatChannelData else { return }
        let mono = channels[0]
        let channelCount = Int(buffer.format.channelCount)

        for i in 0..<Int(frames) {
            let t = Float(i) / sampleRate
            mono[i] = sinf(2.0 * .pi * frequency * t) * 0.35
        }
        if channelCount > 1 {
            let stereo = channels[1]
            for i in 0..<Int(frames) {
                stereo[i] = mono[i]
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
