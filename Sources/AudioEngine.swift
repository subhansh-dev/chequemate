import Foundation
import AVFoundation
import CoreHaptics

// MARK: - Synth Audio Engine

@MainActor
final class SynthEngine: ObservableObject {
    @Published var isRunning = false
    @Published var currentWaveform: WaveformType = .sine

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var isEngineRunning = false

    enum WaveformType: Int, CaseIterable {
        case sine = 0
        case sawtooth = 1
        case square = 2
        case triangle = 3

        var label: String {
            switch self {
            case .sine: return "Sine"
            case .sawtooth: return "Saw"
            case .square: return "Square"
            case .triangle: return "Tri"
            }
        }

        var icon: String {
            switch self {
            case .sine: return "waveform"
            case .sawtooth: return "waveform.circle"
            case .square: return "square.grid.3x3"
            case .triangle: return "triangle"
            }
        }
    }

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

        if !isEngineRunning {
            engine.prepare()
            do {
                try engine.start()
                isEngineRunning = true
            } catch {
                return
            }
        }
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.play()
        isRunning = true
    }

    func stopTone() {
        player.stop()
        if isEngineRunning {
            engine.stop()
            isEngineRunning = false
        }
        isRunning = false
    }

    func setWaveform(_ type: WaveformType) {
        currentWaveform = type
    }

    func cycleWaveform() {
        let next = (currentWaveform.rawValue + 1) % WaveformType.allCases.count
        currentWaveform = WaveformType(rawValue: next) ?? .sine
    }
}

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

    func playPercussive(intensity: Float) {
        guard let engine else { return }
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            ],
            relativeTime: 0
        )
        guard let pattern = try? CHHapticPattern(events: [event], parameters: []),
              let newPlayer = try? engine.makePlayer(with: pattern) else { return }
        try? player?.stop(atTime: 0)
        player = newPlayer
        try? player?.start(atTime: CHHapticTimeImmediate)
        isActive = true
    }

    func stop() {
        try? player?.stop(atTime: 0)
        player = nil
        isActive = false
    }
}
