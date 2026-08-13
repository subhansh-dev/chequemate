#ifndef HuewavesAudio_h
#define HuewavesAudio_h

#include <stdint.h>
#include <math.h>

// MARK: - Audio Control Data (written by Swift, read by C render callback)

typedef struct {
    float frequency;
    float amplitude;
    float filterCutoff;
    int waveformType;   // 0=sine, 1=sawtooth, 2=square, 3=triangle
    int gestureType;    // 0=sustained, 1=percussive, 2=plucked
} AudioControlData;

// MARK: - Lock-Free Ring Buffer (single-producer, single-consumer)

#define RING_BUFFER_SIZE 256

typedef struct {
    AudioControlData buffer[RING_BUFFER_SIZE];
    volatile uint32_t writeIndex;
    volatile uint32_t readIndex;
} ControlRingBuffer;

// MARK: - ADSR Envelope

typedef struct {
    float attack;
    float decay;
    float sustain;
    float release;
    float startTime;
    float releaseTime;
    int isActive;
    int isReleasing;
} ADSREnvelope;

// MARK: - Low-Pass Filter

typedef struct {
    float previousOutput;
    float cutoff;
} LowPassFilter;

// MARK: - Phase Tracker

typedef struct {
    float phase;
    float sampleRate;
} PhaseTracker;

// MARK: - Ring Buffer Operations

static inline void ringBufferInit(ControlRingBuffer *rb) {
    rb->writeIndex = 0;
    rb->readIndex = 0;
}

static inline int ringBufferWrite(ControlRingBuffer *rb, AudioControlData data) {
    uint32_t nextWrite = (rb->writeIndex + 1) % RING_BUFFER_SIZE;
    if (nextWrite == rb->readIndex) return 0; // full
    rb->buffer[rb->writeIndex] = data;
    rb->writeIndex = nextWrite;
    return 1;
}

static inline int ringBufferRead(ControlRingBuffer *rb, AudioControlData *data) {
    if (rb->readIndex == rb->writeIndex) return 0; // empty
    *data = rb->buffer[rb->readIndex];
    rb->readIndex = (rb->readIndex + 1) % RING_BUFFER_SIZE;
    return 1;
}

// MARK: - Waveform Generators (real-time safe)

static inline float waveformSine(float frequency, float sampleRate, float phase) {
    return sinf(2.0f * M_PI * frequency * phase / sampleRate);
}

static inline float waveformSawtooth(float frequency, float sampleRate, float phase) {
    float value = 0.0f;
    float t = phase / sampleRate;
    for (int h = 1; h <= 8; h++) {
        value += sinf(2.0f * M_PI * frequency * (float)h * t) / (float)h;
    }
    return value * 0.5f;
}

static inline float waveformSquare(float frequency, float sampleRate, float phase) {
    float value = 0.0f;
    float t = phase / sampleRate;
    for (int h = 1; h <= 8; h += 2) {
        value += sinf(2.0f * M_PI * frequency * (float)h * t) / (float)h;
    }
    return value * 0.75f;
}

static inline float waveformTriangle(float frequency, float sampleRate, float phase) {
    float value = 0.0f;
    float t = phase / sampleRate;
    for (int h = 0; h < 4; h++) {
        int n = 2 * h + 1;
        float sign = (h % 2 == 0) ? 1.0f : -1.0f;
        value += sign * sinf(2.0f * M_PI * frequency * (float)n * t) / ((float)n * (float)n);
    }
    return value * 0.8f;
}

static inline float generateWaveform(int type, float frequency, float sampleRate, float phase) {
    switch (type) {
        case 0:  return waveformSine(frequency, sampleRate, phase);
        case 1:  return waveformSawtooth(frequency, sampleRate, phase);
        case 2:  return waveformSquare(frequency, sampleRate, phase);
        case 3:  return waveformTriangle(frequency, sampleRate, phase);
        default: return waveformSine(frequency, sampleRate, phase);
    }
}

// MARK: - Envelope Processing

static inline void envelopeInit(ADSR *env) {
    env->attack = 0.02f;
    env->decay = 0.1f;
    env->sustain = 0.7f;
    env->release = 0.3f;
    env->startTime = 0.0f;
    env->releaseTime = -1.0f;
    env->isActive = 1;
    env->isReleasing = 0;
}

static inline void envelopeNoteOn(ADSR *env, float currentTime) {
    env->startTime = currentTime;
    env->releaseTime = -1.0f;
    env->isActive = 1;
    env->isReleasing = 0;
}

static inline void envelopeNoteOff(ADSR *env, float currentTime) {
    env->releaseTime = currentTime;
    env->isReleasing = 1;
}

static inline float envelopeProcess(ADSR *env, float currentTime) {
    if (!env->isActive) return 0.0f;

    if (!env->isReleasing) {
        // Attack phase
        float t = currentTime - env->startTime;
        if (t < env->attack) {
            return t / env->attack;
        }
        // Decay phase
        t -= env->attack;
        if (t < env->decay) {
            return 1.0f - (1.0f - env->sustain) * (t / env->decay);
        }
        // Sustain phase
        return env->sustain;
    } else {
        // Release phase
        float t = currentTime - env->releaseTime;
        if (t >= env->release) {
            env->isActive = 0;
            return 0.0f;
        }
        float currentLevel = env->sustain * (1.0f - t / env->release);
        return currentLevel;
    }
}

// MARK: - Low-Pass Filter

static inline void filterInit(LowPassFilter *f) {
    f->previousOutput = 0.0f;
    f->cutoff = 0.5f;
}

static inline float filterProcess(LowPassFilter *f, float input) {
    float coeff = f->cutoff * 0.3f;
    float output = f->previousOutput + coeff * (input - f->previousOutput);
    f->previousOutput = output;
    return output;
}

// MARK: - Main Render Callback State

typedef struct {
    ControlRingBuffer ringBuffer;
    PhaseTracker phase;
    ADSREnvelope envelope;
    LowPassFilter filter;
    AudioControlData currentParams;
    float lastFrequency;
    int gestureHoldCounter;
} AudioRendererState;

static inline void rendererInit(AudioRendererState *state) {
    ringBufferInit(&state->ringBuffer);
    state->phase.phase = 0.0f;
    state->phase.sampleRate = 44100.0f;
    envelopeInit(&state->envelope);
    filterInit(&state->filter);
    state->currentParams.frequency = 261.63f;
    state->currentParams.amplitude = 0.0f;
    state->currentParams.filterCutoff = 0.5f;
    state->currentParams.waveformType = 0;
    state->currentParams.gestureType = 0;
    state->lastFrequency = 261.63f;
    state->gestureHoldCounter = 0;
}

// MARK: - Write Control Data (called from Swift gesture thread)

static inline void rendererWriteParams(AudioRendererState *state,
                                        float frequency, float amplitude,
                                        float filterCutoff, int waveform, int gesture) {
    AudioControlData data;
    data.frequency = frequency;
    data.amplitude = amplitude;
    data.filterCutoff = filterCutoff;
    data.waveformType = waveform;
    data.gestureType = gesture;
    ringBufferWrite(&state->ringBuffer, data);
}

// MARK: - Render Callback (called on real-time audio thread — NO Swift, NO locks, NO alloc)

static inline void rendererRender(AudioRendererState *state,
                                   float *leftChannel, float *rightChannel,
                                   int frameCount, float currentTime) {
    for (int i = 0; i < frameCount; i++) {
        // Read latest params from ring buffer
        AudioControlData params;
        while (ringBufferRead(&state->ringBuffer, &params)) {
            state->currentParams = params;
        }

        // Detect frequency change — trigger envelope re-attack
        float freqDelta = fabsf(state->currentParams.frequency - state->lastFrequency);
        if (freqDelta > 5.0f && state->currentParams.amplitude > 0.01f) {
            envelopeNoteOn(&state->envelope, currentTime);
        }
        state->lastFrequency = state->currentParams.frequency;

        // Update filter cutoff
        state->filter.cutoff = state->currentParams.filterCutoff;

        // Generate waveform
        float sample = generateWaveform(
            state->currentParams.waveformType,
            state->currentParams.frequency,
            state->phase.sampleRate,
            state->phase.phase
        );

        // Apply envelope
        float env = envelopeProcess(&state->envelope, currentTime);
        sample *= env * state->currentParams.amplitude;

        // Apply filter
        sample = filterProcess(&state->filter, sample);

        // Soft clip (analog warmth)
        sample = tanhf(sample * 1.5f);

        // Output (mono to stereo)
        leftChannel[i] = sample;
        rightChannel[i] = sample;

        // Advance phase
        state->phase.phase += 1.0f;
    }
}

#endif /* HuewavesAudio_h */
