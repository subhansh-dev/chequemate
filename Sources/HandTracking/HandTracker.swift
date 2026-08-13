import Foundation
@preconcurrency import AVFoundation
@preconcurrency import Vision
import Combine

// MARK: - Hand Landmark Data

struct HandLandmark: Identifiable {
    let id = UUID()
    let joint: VNHumanHandPoseObservation.JointName
    let point: CGPoint
    let confidence: Float
}

struct HandData {
    let landmarks: [VNHumanHandPoseObservation.JointName: VNRecognizedPoint]
    let screenPoints: [VNHumanHandPoseObservation.JointName: CGPoint]
    let handedness: VNChirality

    var indexTip: CGPoint? { screenPoints[.indexTip] }
    var thumbTip: CGPoint? { screenPoints[.thumbTip] }
    var wrist: CGPoint? { screenPoints[.wrist] }
    var middleTip: CGPoint? { screenPoints[.middleTip] }
}

// MARK: - Gesture Classification

enum HandGesture: String, CaseIterable {
    case open
    case fist
    case peace
    case pinch
    case point

    var label: String {
        switch self {
        case .open: return "Open"
        case .fist: return "Fist"
        case .peace: return "Peace"
        case .pinch: return "Pinch"
        case .point: return "Point"
        }
    }

    var icon: String {
        switch self {
        case .open: return "hand.raised.fill"
        case .fist: return "hand.raised.fist.fill"
        case .peace: return "hand.thumbsup.fill"
        case .pinch: return "hand.draw.fill"
        case .point: return "hand.point.up.fill"
        }
    }
}

// MARK: - Smoothing Filter

struct SmoothingFilter {
    var smoothedX: Float = 0.5
    var smoothedY: Float = 0.5
    let factor: Float = 0.82

    mutating func update(rawX: Float, rawY: Float) -> (x: Float, y: Float) {
        smoothedX = smoothedX * factor + rawX * (1 - factor)
        smoothedY = smoothedY * factor + rawY * (1 - factor)
        return (smoothedX, smoothedY)
    }

    mutating func reset() {
        smoothedX = 0.5
        smoothedY = 0.5
    }
}

// MARK: - Gesture Classifier

struct GestureClassifier {
    private var gestureHoldCounter: Int = 0
    private var lastClassifiedGesture: HandGesture = .open
    private let holdThreshold = 3

    mutating func classify(landmarks: [VNHumanHandPoseObservation.JointName: VNRecognizedPoint]) -> HandGesture {
        guard let indexTip = landmarks[.indexTip],
              let indexMCP = landmarks[.indexMCP],
              let middleTip = landmarks[.middleTip],
              let middleMCP = landmarks[.middleMCP],
              let ringTip = landmarks[.ringTip],
              let ringMCP = landmarks[.ringMCP],
              let littleTip = landmarks[.littleTip],
              let littleMCP = landmarks[.littleMCP],
              let thumbTip = landmarks[.thumbTip],
              let thumbIP = landmarks[.thumbIP] else {
            return .open
        }

        let indexExtended = indexTip.y > indexMCP.y
        let middleExtended = middleTip.y > middleMCP.y
        let ringExtended = ringTip.y > ringMCP.y
        let littleExtended = littleTip.y > littleMCP.y

        let thumbIndexDist = hypot(
            thumbTip.x - indexTip.x,
            thumbTip.y - indexTip.y
        )

        var detected: HandGesture

        if thumbIndexDist < 0.05 {
            detected = .pinch
        } else if indexExtended && !middleExtended && !ringExtended && !littleExtended {
            detected = .point
        } else if indexExtended && middleExtended && !ringExtended && !littleExtended {
            detected = .peace
        } else if !indexExtended && !middleExtended && !ringExtended && !littleExtended {
            detected = .fist
        } else {
            detected = .open
        }

        // Debounce: require gesture to hold for N frames
        if detected == lastClassifiedGesture {
            gestureHoldCounter += 1
        } else {
            gestureHoldCounter = 1
            lastClassifiedGesture = detected
        }

        return gestureHoldCounter >= holdThreshold ? detected : lastClassifiedGesture
    }
}

// MARK: - Hand Tracker (ObservableObject)

@MainActor
final class HandTracker: ObservableObject {
    @Published var leftHand: HandData?
    @Published var rightHand: HandData?
    @Published var currentGesture: HandGesture = .open
    @Published var pitch: Float = 261.63     // Hz
    @Published var amplitude: Float = 0.0
    @Published var filterCutoff: Float = 0.5
    @Published var waveformType: Int = 0     // 0=sine, 1=saw, 2=square, 3=triangle
    @Published var isTracking = false
    @Published var handCount: Int = 0

    // Mapping params (adjustable)
    var minFrequency: Float = 80.0
    var maxFrequency: Float = 4000.0
    var sensitivity: Float = 0.82

    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "com.huewaves.handtracking", qos: .userInteractive)
    private var videoConnection: AVCaptureConnection?

    private var leftSmoothing = SmoothingFilter()
    private var rightSmoothing = SmoothingFilter()
    private var classifier = GestureClassifier()

    nonisolated(unsafe) private var lastFrameTime: CFTimeInterval = 0
    nonisolated(unsafe) private var frameSkipCount = 0

    func startTracking() {
        guard !isTracking else { return }

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .medium

        // Front camera
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("Failed to access front camera")
            captureSession.commitConfiguration()
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        videoOutput.setSampleBufferDelegate(nil, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        videoConnection = videoOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait

        captureSession.commitConfiguration()

        // Set delegate after configuration
        videoOutput.setSampleBufferDelegate(HandTrackingDelegate(tracker: self), queue: processingQueue)

        processingQueue.async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async {
                self?.isTracking = true
            }
        }
    }

    func stopTracking() {
        processingQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            DispatchQueue.main.async {
                self?.leftHand = nil
                self?.rightHand = nil
                self?.handCount = 0
                self?.isTracking = false
                self?.leftSmoothing.reset()
                self?.rightSmoothing.reset()
            }
        }
    }

    func cycleWaveform() {
        waveformType = (waveformType + 1) % 4
    }

    // Process a frame on background queue
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        let now = CACurrentMediaTime()
        let elapsed = now - lastFrameTime

        // Skip frames if processing too slow (>33ms = below 30fps)
        if elapsed < 0.033 {
            frameSkipCount += 1
            if frameSkipCount < 3 { return }
        }
        frameSkipCount = 0
        lastFrameTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Downscale to 1280x720 for Vision
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let scaleX = 1280.0 / ciImage.extent.width
        let scaleY = 720.0 / ciImage.extent.height
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let handler = VNImageRequestHandler(ciImage: scaled, options: [:])

        let request = VNDetectHumanHandPoseRequest { [weak self] request, error in
            guard let self = self, error == nil else { return }
            guard let results = request.results as? [VNHumanHandPoseObservation] else { return }

            self.processResults(results)
        }
        request.maximumHandCount = 2

        do {
            try handler.perform([request])
        } catch {
            print("Vision error: \(error)")
        }
    }

    private nonisolated func processResults(_ results: [VNHumanHandPoseObservation]) {
        var leftData: HandData?
        var rightData: HandData?

        for observation in results {
            let chirality = observation.chirality

            var screenPoints: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
            var allPoints: [VNHumanHandPoseObservation.JointName: VNRecognizedPoint] = [:]

            let joints: [VNHumanHandPoseObservation.JointName] = [
                .wrist, .thumbTip, .thumbIP, .thumbMP, .thumbCMC,
                .indexTip, .indexDIP, .indexPIP, .indexMCP,
                .middleTip, .middleDIP, .middlePIP, .middleMCP,
                .ringTip, .ringDIP, .ringPIP, .ringMCP,
                .littleTip, .littleDIP, .littlePIP, .littleMCP
            ]

            for joint in joints {
                if let point = try? observation.recognizedPoint(joint),
                   point.confidence > 0.5 {
                    allPoints[joint] = point
                    // Convert Vision coords (lower-left origin) to screen coords
                    screenPoints[joint] = CGPoint(
                        x: point.x,
                        y: 1.0 - point.y  // Flip Y
                    )
                }
            }

            let handData = HandData(
                landmarks: allPoints,
                screenPoints: screenPoints,
                handedness: chirality
            )

            switch chirality {
            case .left:
                leftData = handData
            case .right:
                rightData = handData
            @unknown default:
                break
            }
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.leftHand = leftData
            self.rightHand = rightData
            self.handCount = [leftData, rightData].compactMap { $0 }.count

            self.updateMapping()
        }
    }

    private func updateMapping() {
        let hasLeft = leftHand != nil
        let hasRight = rightHand != nil

        if hasLeft && hasRight {
            // DUAL HAND MODE
            mapDualHand()
        } else if let hand = leftHand ?? rightHand {
            // SINGLE HAND MODE
            mapSingleHand(hand)
        } else {
            // NO HANDS
            amplitude = max(0, amplitude - 0.05)
        }
    }

    private func mapSingleHand(_ hand: HandData) {
        guard let indexTip = hand.indexTip else { return }

        // Pitch = Y position (bottom = low, top = high), logarithmic
        let rawY = Float(indexTip.y)
        let smoothed = leftSmoothing.update(rawX: Float(indexTip.x), rawY: rawY)

        let semitone = smoothed.y * 12.0  // 0-12 semitones range
        pitch = minFrequency * pow(2.0, semitone / 12.0)
        pitch = min(max(pitch, minFrequency), maxFrequency)

        // Volume = X position (left = quiet, right = loud)
        amplitude = smoothed.x

        // Gesture classification
        if let landmarks = hand.landmarks.count >= 10 ? hand.landmarks : nil {
            currentGesture = classifier.classify(landmarks: landmarks)
        }

        // Filter cutoff based on gesture
        switch currentGesture {
        case .pinch:
            filterCutoff = 0.15  // Dark/muted
        case .fist:
            filterCutoff = 0.3
        case .point:
            filterCutoff = 0.5
        case .peace:
            filterCutoff = 0.7
        case .open:
            filterCutoff = 0.9  // Bright
        }
    }

    private func mapDualHand() {
        guard let left = leftHand, let right = rightHand else { return }

        // Left hand Y = pitch
        if let leftIndex = left.indexTip {
            let rawY = Float(leftIndex.y)
            let smoothed = leftSmoothing.update(rawX: Float(leftIndex.x), rawY: rawY)
            let semitone = smoothed.y * 12.0
            pitch = minFrequency * pow(2.0, semitone / 12.0)
            pitch = min(max(pitch, minFrequency), maxFrequency)
        }

        // Right hand Y = volume
        if let rightIndex = right.indexTip {
            let rawY = Float(rightIndex.y)
            let smoothed = rightSmoothing.update(rawX: Float(rightIndex.x), rawY: rawY)
            amplitude = smoothed.y
        }

        // Both hands X distance = chord width
        if let leftIndex = left.indexTip, let rightIndex = right.indexTip {
            let distance = abs(Float(rightIndex.x) - Float(leftIndex.x))
            // Wider distance = more filter open
            filterCutoff = min(1.0, distance * 2.0)
        }

        // Right hand gesture = effects
        if let landmarks = right.landmarks, landmarks.count >= 10 {
            currentGesture = classifier.classify(landmarks: landmarks)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate (NSObject)

final class HandTrackingDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    let tracker: HandTracker

    init(tracker: HandTracker) {
        self.tracker = tracker
    }

    nonisolated func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        tracker.processFrame(sampleBuffer)
    }
}
