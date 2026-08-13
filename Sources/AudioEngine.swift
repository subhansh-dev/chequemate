import Foundation
import AVFoundation

// MARK: - Audio Control Data

struct AudioControlData {
    var frequency: Float = 261.63
    var amplitude: Float = 0.0
    var filterCutoff: Float = 0.5
    var waveformType: Int = 0    // 0=sine, 1=sawtooth, 2=square, 3=triangle
    var gestureType: Int = 0     // 0=sustained, 1=percussive, 2=plucked
}

// MARK: - Lock-Free Ring Buffer

final class ControlRingBuffer: @unchecked Sendable {
    private let buffer = UnsafeMutablePointer<AudioControlData>.allocate(capacity: 256)
    private var writeIndex: UInt32 = 0
    private var readIndex: UInt32 = 0

    init() {
        buffer.initialize(repeating: AudioControlData(), count: 256)
    }

    deinit {
        buffer.deallocate()
    }

    func write(_ data: AudioControlData) -> Bool {
        let nextWrite = (writeIndex &+ 1) & 255
        guard nextWrite != readIndex else { return false }
        buffer[Int(writeIndex)] = data
        writeIndex = nextWrite
        return true
    }

    func read(_ data: UnsafeMutablePointer<AudioControlData>) -> Bool {
        guard readIndex != writeIndex else { return false }
        data.pointee = buffer[Int(readIndex)]
        readIndex = (readIndex &+ 1) & 255
        return true
    }
}

// MARK: - Waveform Generators

enum WaveformGenerator {
    static func sine(_ frequency: Float, _ sampleRate: Float, _ phase: Float) -> Float {
        return sinf(2.0 * .pi * frequency * phase / sampleRate)
    }

    static func sawtooth(_ frequency: Float, _ sampleRate: Float, _ phase: Float) -> Float {
        var value: Float = 0
        let t = phase / sampleRate
        for h in 1...8 {
            value += sinf(2.0 * .pi * frequency * Float(h) * t) / Float(h)
        }
        return value * 0.5
    }

    static func square(_ frequency: Float, _ sampleRate: Float, _ phase: Float) -> Float {
        var value: Float = 0
        let t = phase / sampleRate
        for h in stride(from: 1, through: 8, by: 2) {
            value += sinf(2.0 * .pi * frequency * Float(h) * t) / Float(h)
        }
        return value * 0.75
    }

    static func triangle(_ frequency: Float, _ sampleRate: Float, _ phase: Float) -> Float {
        var value: Float = 0
        let t = phase / sampleRate
        for h in 0..<4 {
            let n = 2 * h + 1
            let sign: Float = (h % 2 == 0) ? 1.0 : -1.0
            value += sign * sinf(2.0 * .pi * frequency * Float(n) * t) / (Float(n) * Float(n))
        }
        return value * 0.8
    }

    static func generate(_ type: Int, _ frequency: Float, _ sampleRate: Float, _ phase: Float) -> Float {
        switch type {
        case 0: return sine(frequency, sampleRate, phase)
        case 1: return sawtooth(frequency, sampleRate, phase)
        case 2: return square(frequency, sampleRate, phase)
        case 3: return triangle(frequency, sampleRate, phase)
        default: return sine(frequency, sampleRate, phase)
        }
    }
}

// MARK: - ADSR Envelope

struct ADSREnvelope {
    var attack: Float = 0.02
    var decay: Float = 0.1
    var sustain: Float = 0.7
    var release: Float = 0.3
    var startTime: Float = 0
    var releaseTime: Float = -1
    var isActive: Bool = true
    var isReleasing: Bool = false

    mutating func noteOn(_ time: Float) {
        startTime = time
        releaseTime = -1
        isActive = true
        isReleasing = false
    }

    mutating func noteOff(_ time: Float) {
        releaseTime = time
        isReleasing = true
    }

    mutating func process(_ time: Float) -> Float {
        guard isActive else { return 0 }

        if !isReleasing {
            let t = time - startTime
            if t < attack { return t / attack }
            let t2 = t - attack
            if t2 < decay { return 1.0 - (1.0 - sustain) * (t2 / decay) }
            return sustain
        } else {
            let t = time - releaseTime
            if t >= release {
                isActive = false
                return 0
            }
            return sustain * (1.0 - t / release)
        }
    }
}

// MARK: - Low-Pass Filter

struct LowPassFilter {
    var previousOutput: Float = 0
    var cutoff: Float = 0.5

    mutating func process(_ input: Float) -> Float {
        let coeff = cutoff * 0.3
        let output = previousOutput + coeff * (input - previousOutput)
        previousOutput = output
        return output
    }
}

// MARK: - Audio Renderer State

final class AudioRendererState: @unchecked Sendable {
    let ringBuffer = ControlRingBuffer()
    var phase: Float = 0
    let sampleRate: Float = 44100
    var envelope = ADSREnvelope()
    var filter = LowPassFilter()
    var currentParams = AudioControlData()
    var lastFrequency: Float = 261.63

    func writeParams(frequency: Float, amplitude: Float, filterCutoff: Float, waveform: Int, gesture: Int) {
        let data = AudioControlData(
            frequency: frequency,
            amplitude: amplitude,
            filterCutoff: filterCutoff,
            waveformType: waveform,
            gestureType: gesture
        )
        ringBuffer.write(data)
    }

    func render(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int, currentTime: Float) {
        for i in 0..<frameCount {
            // Read latest params
            var params = AudioControlData()
            while ringBuffer.read(&params) {
                currentParams = params
            }

            // Detect frequency change — trigger re-attack
            let freqDelta = abs(currentParams.frequency - lastFrequency)
            if freqDelta > 5.0 && currentParams.amplitude > 0.01 {
                envelope.noteOn(currentTime)
            }
            lastFrequency = currentParams.frequency

            // Update filter
            filter.cutoff = currentParams.filterCutoff

            // Generate waveform
            var sample = WaveformGenerator.generate(
                currentParams.waveformType,
                currentParams.frequency,
                sampleRate,
                phase
            )

            // Apply envelope
            let env = envelope.process(currentTime)
            sample *= env * currentParams.amplitude

            // Apply filter
            sample = filter.process(sample)

            // Soft clip (analog warmth)
            sample = tanhf(sample * 1.5)

            // Output
            leftChannel[i] = sample
            rightChannel[i] = sample

            phase += 1
        }
    }
}
