# Huewaves — Gesture Orchestra

## Project Rework Specification

---

## 1. Vision

**Huewaves** is a synesthetic instrument app for iOS 26 that transforms hand gestures into real-time music and visual waveforms. Your hands become the instrument — position controls pitch and volume, gestures change timbre, and movement leaves glowing wave trails in AR space.

**Tagline:** Your hands are the instrument.

**Core idea:** A theremin you can see.

---

## 2. Swift Student Challenge Alignment

| Criterion | How Huewaves Addresses It |
|-----------|--------------------------|
| **Innovation** | Real-time hand-to-audio synthesis using Vision + AVAudioSourceNode — a pipeline nobody has shipped as a polished iOS app |
| **Creativity** | Synesthetic experience: gesture → sound → visual feedback loop. Expressive, not literal |
| **Social Impact** | Accessible music creation — no instruments needed, no musical training required. Anyone with hands can make music |
| **Inclusivity** | Works with one hand or two. Adaptive gesture sensitivity. Visual-only mode for deaf users (waveforms without audio) |

**Submission format:** .swiftpm app playground, Xcode 26, iOS 26 SDK, must run within 3 minutes, all content local (offline evaluation).

---

## 3. Technical Architecture

### 3.1 System Overview

```
┌─────────────────────────────────────────────────────┐
│                    Camera Feed                       │
│              (AVCaptureSession)                      │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│              Hand Pose Detection                     │
│         (VNDetectHumanHandPoseRequest)               │
│         21 landmarks × 2 hands @ 60fps              │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│            Gesture Mapping Engine                    │
│   Position → Frequency/Amplitude                     │
│   Gestures → Timbre/Articulation                     │
│   Smoothing + Jitter Reduction                       │
└──────────┬──────────────────┬───────────────────────┘
           │                  │
           ▼                  ▼
┌──────────────────┐  ┌──────────────────────────────┐
│  Audio Synth     │  │  Visual Renderer              │
│  (AVAudioSource  │  │  (SwiftUI Canvas +            │
│   Node)          │  │   TimelineView)               │
│  C render callback│  │  Wave trails + particles      │
└──────────────────┘  └──────────────────────────────┘
           │                  │
           ▼                  ▼
┌─────────────────────────────────────────────────────┐
│                   Output                             │
│   Speaker (synthesized audio)                        │
│   Screen (waveform visualization)                    │
│   Haptics (Core Haptics — percussive feedback)       │
└─────────────────────────────────────────────────────┘
```

### 3.2 Frameworks & APIs

| Framework | Purpose | Key API |
|-----------|---------|---------|
| **Vision** | Hand landmark detection | `VNDetectHumanHandPoseRequest`, `VNHumanHandPoseObservation` |
| **AVFoundation** | Camera capture + audio engine | `AVCaptureSession`, `AVAudioEngine`, `AVAudioSourceNode` |
| **Core Haptics** | Percussive feedback on gestures | `CHHapticEngine`, `CHHapticPattern` |
| **SwiftUI** | UI + real-time rendering | `Canvas`, `TimelineView`, `.glassEffect` |
| **Accelerate** | Fast math for DSP | `vDSP`, `vForce` (sin, pow) |
| **Combine** | Data flow between components | `@Published`, `PassthroughSubject` |

### 3.3 Hand Pose Detection (Vision)

```
VNDetectHumanHandPoseRequest
  ├── maximumHandCount: 2
  ├──Revision: .VNHumanHandPoseRequestRevision1
  └── Results: [VNHumanHandPoseObservation]
       ├── recognizedPoint(.wrist)
       ├── recognizedPoint(.thumbTip)
       ├── recognizedPoint(.indexTip)
       ├── recognizedPoint(.middleTip)
       ├── recognizedPoint(.ringTip)
       ├── recognizedPoint(.littleTip)
       ├── recognizedPoint(.thumbIP)
       ├── recognizedPoint(.indexDIP)
       ├── recognizedPoint(.indexPIP)
       ├── recognizedPoint(.indexMCP)
       └── ... (21 landmarks total per hand)
```

**Coordinate system:** Vision uses lower-left origin, normalized 0.0–1.0. Convert to screen coordinates:

```swift
let screenPoint = CGPoint(
    x: visionPoint.x * imageWidth,
    y: (1 - visionPoint.y) * imageHeight  // Flip Y
)
```

**Confidence threshold:** Only use landmarks with `confidence > 0.5`. Below that, the landmark is unreliable.

**Performance:**
- Downscale camera frame to 1280×720 before Vision processing
- Run Vision on background queue (`DispatchQueue.global(qos: .userInteractive)`)
- Set `maximumHandCount = 2` to avoid unnecessary computation
- Skip frames if processing takes >16ms (maintain 60fps budget)

---

## 4. Gesture Mapping System

### 4.1 Single Hand Mode (Default)

When one hand is visible:

| Parameter | Source | Mapping |
|-----------|--------|---------|
| **Pitch** | Index fingertip Y position | Logarithmic: 80Hz (bottom) → 4000Hz (top) |
| **Volume** | Index fingertip X position | Linear: 0.0 (left) → 1.0 (right) |
| **Timbre** | Thumb-index distance (pinch) | Filter cutoff: 200Hz (pinched) → 8000Hz (open) |
| **Articulation** | Hand openness (all fingers extended vs fist) | Open = sustained, Fist = percussive, 2 fingers = plucked |

### 4.2 Dual Hand Mode

When two hands are visible:

| Parameter | Source | Mapping |
|-----------|--------|---------|
| **Pitch** | Left hand Y position | Logarithmic frequency mapping |
| **Volume** | Right hand Y position | Linear amplitude mapping |
| **Chord** | Both hands X distance | Wider = more intervals in chord |
| **Effects** | Right hand fist/open | Fist = distortion, Open = reverb |

### 4.3 Gesture Detection

```swift
enum HandGesture {
    case open        // All fingers extended
    case fist        // All fingers closed
    case peace       // Index + middle extended
    case pinch       // Thumb + index touching
    case point       // Only index extended
}

func classifyGesture(landmarks: [VNHumanHandPoseObservation.JointName: VNRecognizedPoint]) -> HandGesture {
    let indexExtended = landmarks[.indexTip]!.y > landmarks[.indexMCP]!.y
    let middleExtended = landmarks[.middleTip]!.y > landmarks[.middleMCP]!.y
    let ringExtended = landmarks[.ringTip]!.y > landmarks[.ringMCP]!.y
    let littleExtended = landmarks[.littleTip]!.y > landmarks[.littleMCP]!.y
    let thumbExtended = landmarks[.thumbTip]!.x > landmarks[.thumbIP]!.x  // For right hand

    let thumbIndexDist = hypot(
        landmarks[.thumbTip]!.x - landmarks[.indexTip]!.x,
        landmarks[.thumbTip]!.y - landmarks[.indexTip]!.y
    )

    if thumbIndexDist < 0.05 { return .pinch }
    if indexExtended && !middleExtended && !ringExtended && !littleExtended { return .point }
    if indexExtended && middleExtended && !ringExtended && !littleExtended { return .peace }
    if !indexExtended && !middleExtended && !ringExtended && !littleExtended { return .fist }
    return .open
}
```

### 4.4 Smoothing & Stability

Raw hand positions are noisy. Apply exponential moving average:

```swift
struct SmoothingFilter {
    var smoothedX: Float = 0.5
    var smoothedY: Float = 0.5
    let factor: Float = 0.85  // Higher = smoother but laggier

    mutating func update(rawX: Float, rawY: Float) -> (x: Float, y: Float) {
        smoothedX = smoothedX * factor + rawX * (1 - factor)
        smoothedY = smoothedY * factor + rawY * (1 - factor)
        return (smoothedX, smoothedY)
    }
}
```

**Gesture debouncing:** Require gesture to hold for 3 frames before triggering state change. Prevents accidental triggers from noisy landmarks.

---

## 5. Audio Synthesis Engine

### 5.1 Architecture

```
AVAudioEngine
  └── AVAudioSourceNode (render callback)
       └── Reads from lock-free ring buffer
            └── Ring buffer written by gesture mapping thread
                 └── Contains: frequency, amplitude, waveform type, filter cutoff
```

### 5.2 Real-Time Audio Constraints

**Critical:** The `AVAudioSourceNode` render callback runs on a real-time audio thread. You CANNOT:
- Allocate memory
- Use locks (`DispatchSemaphore`, `NSLock`)
- Call Swift/Objective-C methods (Apple WWDC2017: "not safe to use Swift runtime from real-time context")
- Do I/O (file, network)
- Use classes with reference counting

**Solution:** Use a C-compatible ring buffer (like `TPCircularBuffer`) to bridge between the Swift gesture thread and the C audio callback.

### 5.3 Ring Buffer Design

```c
// Ring buffer structure (C-compatible)
typedef struct {
    float frequency;
    float amplitude;
    float filterCutoff;
    int waveformType;  // 0=sine, 1=sawtooth, 2=square, 3=triangle
    int gestureType;   // 0=sustained, 1=percussive, 2=plucked
} AudioControlData;

// Lock-free single-producer single-consumer ring buffer
typedef struct {
    AudioControlData buffer[256];
    volatile uint32_t writeIndex;
    volatile uint32_t readIndex;
} ControlRingBuffer;
```

### 5.4 Waveform Generation

Inside the C render callback:

```c
// Sine wave
float sine(float frequency, float sampleRate, float time) {
    return sinf(2.0f * M_PI * frequency * time);
}

// Sawtooth (via additive synthesis — 8 harmonics)
float sawtooth(float frequency, float sampleRate, float time) {
    float value = 0;
    for (int h = 1; h <= 8; h++) {
        value += sinf(2.0f * M_PI * frequency * h * time) / (float)h;
    }
    return value * 0.5f;
}

// Square (odd harmonics only)
float square(float frequency, float sampleRate, float time) {
    float value = 0;
    for (int h = 1; h <= 8; h += 2) {
        value += sinf(2.0f * M_PI * frequency * h * time) / (float)h;
    }
    return value * 0.75f;
}

// Triangle (odd harmonics, alternating sign)
float triangle(float frequency, float sampleRate, float time) {
    float value = 0;
    for (int h = 0; h < 4; h++) {
        int n = 2 * h + 1;
        float sign = (h % 2 == 0) ? 1.0f : -1.0f;
        value += sign * sinf(2.0f * M_PI * frequency * n * time) / ((float)n * (float)n);
    }
    return value * 0.8f;
}
```

### 5.5 Envelope (Attack/Decay/Sustain/Release)

For percussive and plucked gestures, apply an amplitude envelope:

```c
typedef struct {
    float attack;   // 0.01 - 0.1 seconds
    float decay;    // 0.05 - 0.3 seconds
    float sustain;  // 0.0 - 1.0
    float release;  // 0.1 - 1.0 seconds
    float startTime;
    int isActive;
} ADSREnvelope;

float processEnvelope(ADSR *env, float currentTime) {
    float t = currentTime - env->startTime;
    if (t < env->attack) return t / env->attack;
    t -= env->attack;
    if (t < env->decay) return 1.0f - (1.0f - env->sustain) * (t / env->decay);
    return env->sustain;
}
```

### 5.6 Low-Pass Filter (Timbre Control)

Simple one-pole low-pass filter for timbre brightness:

```c
typedef struct {
    float previousOutput;
    float cutoff;  // 0.0 - 1.0 (normalized)
} LowPassFilter;

float processFilter(LowPassFilter *filter, float input) {
    float coeff = filter->cutoff * 0.3f;  // Tune range
    float output = filter->previousOutput + coeff * (input - filter->previousOutput);
    filter->previousOutput = output;
    return output;
}
```

### 5.7 Audio Format

```
Sample Rate:    44,100 Hz
Channels:       2 (stereo)
Bit Depth:      32-bit float
Buffer Size:    512 samples (~11.6ms latency)
Total Latency:  ~23ms (2 buffer periods) — acceptable for live performance
```

---

## 6. Visual Rendering

### 6.1 Wave Trail System

```swift
struct WaveTrail {
    let maxPoints = 60  // Last 60 positions
    var points: [CGPoint] = []
    var colors: [Color] = []
    var timestamps: [TimeInterval] = []

    mutating func add(point: CGPoint, frequency: Float) {
        points.append(point)
        colors.append(Color(hue: Double(frequency / 4000.0), saturation: 0.6, brightness: 0.9))
        timestamps.append(Date().timeIntervalSince1970)
        if points.count > maxPoints {
            points.removeFirst()
            colors.removeFirst()
            timestamps.removeFirst()
        }
    }
}
```

### 6.2 Canvas Rendering

```swift
Canvas { context, size in
    // Draw wave trail
    for i in 1..<trail.points.count {
        let age = Date().timeIntervalSince1970 - trail.timestamps[i]
        let opacity = max(0, 1.0 - age * 2.0)  // Fade over 0.5 seconds
        let width = CGFloat(2 + trail.colors[i].components.brightness * 6)

        var path = Path()
        path.move(to: trail.points[i - 1])
        path.addLine(to: trail.points[i])
        context.stroke(path, with: .color(trail.colors[i].opacity(opacity)), lineWidth: width)
    }

    // Draw hand skeleton
    for (joint, point) in landmarks {
        let circle = Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8))
        context.fill(circle, with: .color(.white.opacity(0.8)))
    }

    // Draw center frequency indicator
    let centerX = size.width / 2
    let centerY = size.height / 2
    let radius = CGFloat(amplitude) * 80
    let freqCircle = Path(ellipseIn: CGRect(
        x: centerX - radius, y: centerY - radius,
        width: radius * 2, height: radius * 2
    ))
    context.fill(freqCircle, with: .color(
        Color(hue: Double(frequency / 4000.0), saturation: 0.5, brightness: 0.9).opacity(0.3)
    ))
}
```

### 6.3 Performance

- Render at 60fps using `TimelineView(.animation)` 
- Max trail length: 60 points (older points fade and are pruned)
- Hand skeleton: 21 circles + 20 lines per hand = ~80 draw calls max
- Use `drawingGroup()` for Metal-backed rendering

---

## 7. Haptic Feedback

### 7.1 Triggered by Gestures

| Gesture | Haptic |
|---------|--------|
| Fist (percussive) | Short sharp transient |
| Open palm (sustain) | Gentle continuous pulse |
| Pinch | Double tap |
| Peace sign | Rising sweep |

### 7.2 Implementation

```swift
func playPercussiveHaptic(intensity: Float) {
    guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
    let event = CHHapticEvent(
        eventType: .hapticTransient,
        parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
        ],
        relativeTime: 0
    )
    let pattern = try? CHHapticPattern(events: [event], parameters: [])
    try? hapticPlayer?.start(atTime: CHHapticTimeImmediate)
}
```

---

## 8. App Structure

### 8.1 File Layout

```
Sources/
├── HuewavesApp.swift              # App entry + AppState
├── HandTracking/
│   ├── HandPoseDetector.swift     # Vision request + camera setup
│   ├── HandLandmarks.swift        # Landmark extraction + smoothing
│   └── GestureClassifier.swift    # Gesture classification logic
├── Audio/
│   ├── AudioEngine.swift          # AVAudioEngine + AVAudioSourceNode setup
│   ├── RingBuffer.swift           # Lock-free ring buffer (C bridge)
│   ├── WaveformSynth.c            # C render callback (real-time safe)
│   ├── WaveformSynth.h            # C header
│   └── InstrumentPresets.swift    # Sine, saw, square, FM presets
├── Visual/
│   ├── WaveTrailRenderer.swift    # Canvas-based wave trail drawing
│   ├── HandSkeletonView.swift     # Landmark visualization
│   ├── ParticleSystem.swift       # Burst particles on percussive hits
│   └── MeshBackground.swift       # Animated gradient background
├── Haptics/
│   └── HapticEngine.swift         # Core Haptics controller
├── UI/
│   ├── MainView.swift             # Root view with camera preview
│   ├── InstrumentPicker.swift     # Waveform/preset selector
│   ├── GestureOverlay.swift       # HUD showing current gesture
│   └── OnboardingView.swift       # Quick tutorial (3 screens)
└── DesignSystem/
    └── HueWave.swift              # Colors, fonts, glass effects
```

### 8.2 Data Flow

```
HandPoseDetector
  │ @Published var leftHand: HandData?
  │ @Published var rightHand: HandData?
  │
  ├──▶ GestureClassifier
  │      │ @Published var currentGesture: HandGesture
  │      │ @Published var pitch: Float  (80-4000 Hz)
  │      │ @Published var amplitude: Float (0-1)
  │      │ @Published var filterCutoff: Float (0-1)
  │      │
  │      ├──▶ AudioEngine (writes to ring buffer)
  │      │      └── AVAudioSourceNode render callback reads ring buffer
  │      │           └── Generates waveform → speaker
  │      │
  │      ├──▶ WaveTrailRenderer (receives position + frequency)
  │      │      └── Canvas draws trail → screen
  │      │
  │      └──▶ HapticEngine (on gesture change)
  │             └── CHHapticPattern → taptic engine
```

---

## 9. UI/UX Design

### 9.1 Design Language

- **Glass aesthetic:** `backdrop-filter: blur(20px) saturate(1.3)` panels
- **Pure black background:** #010103, never grey
- **Accent color:** Warm peach (#FF9F7F) — matches "hue" theme
- **Typography:** SF Pro Rounded (bold for titles, medium for labels)
- **SVG icons only** — no emojis

### 9.2 Screens

**Onboarding (3 screens, swipable):**
1. "Move your hands. Make music." — Hand silhouette with wave trail
2. "Left hand = pitch. Right hand = volume." — Split diagram
3. "Pinch for timbre. Fist for percussion." — Gesture icons

**Main Experience:**
- Full-screen camera preview (dimmed, with glass overlay)
- Hand landmarks rendered as glowing dots
- Wave trail following index fingertip
- Bottom HUD: current note name, frequency, gesture indicator
- Top bar: instrument picker (sine/saw/square/triangle), waveform toggle
- Side: volume slider (also controllable via right hand)

**Settings (gear icon):**
- Sensitivity slider (adjusts smoothing factor)
- Frequency range (80-2000Hz for beginners, 80-4000Hz for advanced)
- Haptic intensity (on/off/low/medium/high)
- Visual trail length (short/medium/long)

---

## 10. Performance Budget

| Component | Target | Strategy |
|-----------|--------|----------|
| Camera capture | 30fps | AVCaptureSession preset `.medium` |
| Hand pose detection | 30fps | Skip frames if processing >33ms |
| Audio synthesis | 44.1kHz, 512-sample buffers | ~11.6ms per buffer |
| Visual rendering | 60fps | Metal-backed Canvas, capped trail points |
| Total app latency | <50ms | Gesture → sound: ~35ms, Gesture → visual: ~16ms |

### 10.1 Power Management

- Drop to 15fps tracking when no hand movement detected for 2 seconds
- Burst to 30fps when hand movement resumes
- Audio engine stops when app is backgrounded
- Reduce particle count when battery < 20%

---

## 11. Accessibility

| Feature | Implementation |
|---------|---------------|
| **Visual-only mode** | Mute audio, keep waveform visualization — deaf users experience the visual synesthesia |
| **One-hand mode** | Left side of screen = pitch, right side = volume (no second hand needed) |
| **VoiceOver** | Announce current note, frequency, and gesture state |
| **Reduce Motion** | Disable particle effects, use simple fade transitions |
| **High Contrast** | Increase landmark dot size and trail width |

---

## 12. Submission Requirements

| Requirement | Status |
|-------------|--------|
| .swiftpm package format | ✅ Package.swift |
| Xcode 26 | ✅ |
| iOS 26 SDK | ✅ (uses .glassEffect, Vision, AVFoundation) |
| Runs in 3 minutes | ✅ Launches immediately into camera + hand tracking |
| All content local | ✅ No network calls, no external assets |
| English only | ✅ |
| No analytics/tracking | ✅ |
| No third-party dependencies | ✅ Apple frameworks only |

---

## 13. Build Phases

### Phase 1: Core Pipeline (Days 1-2)
- [ ] AVCaptureSession setup with front camera
- [ ] VNDetectHumanHandPoseRequest integration
- [ ] Extract 21 landmarks, display on screen
- [ ] Basic position → frequency mapping (sine wave only)

### Phase 2: Audio Engine (Days 3-4)
- [ ] AVAudioSourceNode setup with C render callback
- [ ] Lock-free ring buffer implementation
- [ ] Sine, sawtooth, square, triangle waveforms
- [ ] ADSR envelope for percussive/plucked sounds

### Phase 3: Gesture System (Days 5-6)
- [ ] Gesture classification (open, fist, peace, pinch, point)
- [ ] Smoothing filter
- [ ] Gesture → timbre/articulation mapping
- [ ] Dual hand support

### Phase 4: Visual Polish (Days 7-8)
- [ ] Wave trail renderer
- [ ] Hand skeleton visualization
- [ ] Particle burst on percussive hits
- [ ] Mesh background

### Phase 5: Haptics + UI (Days 9-10)
- [ ] Core Haptic integration
- [ ] Onboarding flow (3 screens)
- [ ] Settings panel
- [ ] Instrument picker

### Phase 6: Polish + Submission (Days 11-12)
- [ ] Accessibility features
- [ ] Performance optimization
- [ ] Edge case handling (no hands, low light, one hand)
- [ ] Test on physical device
- [ ] Package .swiftpm submission

---

## 14. Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Audio latency too high | Medium | Use 512-sample buffers, C render callback, ring buffer |
| Hand tracking jittery | High | Exponential smoothing, gesture debouncing, confidence thresholds |
| Battery drain | Medium | Adaptive frame rate, audio engine lifecycle management |
| Low light performance | Medium | Camera auto-exposure, fall back to one-hand mode |
| Vision API unreliable on some devices | Low | Test on iPhone 12+ (A14+ has best hand tracking) |

---

## 15. Success Metrics

- **Gesture → sound latency:** < 50ms (perceptual threshold for "instant")
- **Gesture classification accuracy:** > 95% with smoothing
- **Frame rate:** Stable 60fps visual, 30fps tracking
- **Battery drain:** < 15% per 10 minutes of active use
- **Time to first sound:** < 3 seconds from launch (auto-starts camera)

---

*Spec written: August 12, 2026*
*Author: Subhansh*
*Status: Ready for implementation*
