import Foundation
import AVFoundation
import CoreHaptics
import HuewavesAudio

// MARK: - Synth Audio Engine (wraps C render callback)

@MainActor
final class SynthEngine: ObservableObject {
    @Published var isRunning = false
    @Published var currentWaveform: WaveformType = .sine
    @Published var volume: Float = 0.0

    private let engine = AVAudioEngine()
    private var rendererState = AudioRendererState()
    private var sourceNode: AVAudioSourceNode?
    private var startTime: CFTimeInterval = 0

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
        rendererInit(&rendererState)
        setupEngine()
    }

    private func setupEngine() {
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                    sampleRate: 44100,
                                    channels: 2,
                                    interleaved: false)!

        sourceNode = AVAudioSourceNode(renderFormat: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }

            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let leftChannel = ablPointer[0].bindMemory(to: Float.self)
            let rightChannel = ablPointer[1].bindMemory(to: Float.self)

            let currentTime = Float(CACurrentMediaTime() - self.startTime)

            withUnsafeMutablePointer(to: &self.rendererState) { statePtr in
                rendererRender(statePtr,
                              leftChannel.baseAddress,
                              rightChannel.baseAddress,
                              Int(frameCount),
                              currentTime)
            }

            return noErr
        }

        guard let sourceNode else { return }
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: nil)

        // Set output volume
        engine.mainMixerNode.outputVolume = 1.0
    }

    func start() {
        guard !isRunning else { return }
        engine.prepare()
        do {
            try engine.start()
            startTime = CACurrentMediaTime()
            isRunning = true
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }

    func stop() {
        guard isRunning else { return }
        // Fade out
        writeParams(frequency: 0, amplitude: 0, filterCutoff: 0, waveform: 0, gesture: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.engine.stop()
            self?.isRunning = false
        }
    }

    func writeParams(frequency: Float, amplitude: Float, filterCutoff: Float,
                     waveform: Int, gesture: Int) {
        withUnsafeMutablePointer(to: &rendererState) { statePtr in
            rendererWriteParams(statePtr,
                               frequency,
                               amplitude,
                               filterCutoff,
                               Int32(waveform),
                               Int32(gesture))
        }
    }

    func setWaveform(_ type: WaveformType) {
        currentWaveform = type
    }

    func cycleWaveform() {
        let next = (currentWaveform.rawValue + 1) % WaveformType.allCases.count
        currentWaveform = WaveformType(rawValue: next) ?? .sine
    }
}

// MARK: - Microphone Analyzer (kept from original, for Sound→Visual fallback)

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

    func playContinuous(intensity: Float, duration: TimeInterval) {
        guard let engine else { return }
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ],
            relativeTime: 0,
            duration: duration
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
