'use client'

import { useState, useEffect, useRef, useCallback } from 'react'
import { motion, AnimatePresence, useScroll, useTransform } from 'framer-motion'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import {
  Eye, Ear, Hand, Sparkles, Music, Palette, Waves, Brain,
  Camera, Mic, Volume2, Smartphone, Code2, Layers, Zap,
  Heart, Globe2, Accessibility, ChevronDown, Play, Star,
  Lightbulb, Shield, Cpu, GitBranch, Terminal, FileCode2
} from 'lucide-react'

// ─── Synesthetic Color Canvas (interactive demo) ───
function SynestheticCanvas() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const [isActive, setIsActive] = useState(false)
  const [currentColor, setCurrentColor] = useState({ h: 280, s: 80, l: 60 })
  const [currentFreq, setCurrentFreq] = useState(440)
  const particlesRef = useRef<Array<{ x: number; y: number; vx: number; vy: number; life: number; hue: number; size: number }>>([])
  const animRef = useRef<number>(0)

  const hueToFreq = (hue: number) => 200 + (hue / 360) * 800
  const hueToNote = (hue: number) => {
    const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
    return notes[Math.floor((hue / 360) * 12) % 12]
  }

  const spawnParticles = useCallback((x: number, y: number, hue: number) => {
    for (let i = 0; i < 8; i++) {
      const angle = (Math.PI * 2 * i) / 8 + Math.random() * 0.5
      particlesRef.current.push({
        x, y,
        vx: Math.cos(angle) * (2 + Math.random() * 3),
        vy: Math.sin(angle) * (2 + Math.random() * 3),
        life: 1,
        hue: hue + Math.random() * 30 - 15,
        size: 3 + Math.random() * 5
      })
    }
  }, [])

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')!

    const resize = () => {
      canvas.width = canvas.offsetWidth * window.devicePixelRatio
      canvas.height = canvas.offsetHeight * window.devicePixelRatio
      ctx.scale(window.devicePixelRatio, window.devicePixelRatio)
    }
    resize()
    window.addEventListener('resize', resize)

    const animate = () => {
      ctx.fillStyle = 'rgba(10, 6, 20, 0.12)'
      ctx.fillRect(0, 0, canvas.offsetWidth, canvas.offsetHeight)

      particlesRef.current = particlesRef.current.filter(p => p.life > 0)
      for (const p of particlesRef.current) {
        p.x += p.vx
        p.y += p.vy
        p.vy += 0.02
        p.life -= 0.015
        p.vx *= 0.99

        const alpha = p.life * 0.8
        const gradient = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, p.size * 3)
        gradient.addColorStop(0, `hsla(${p.hue}, 85%, 65%, ${alpha})`)
        gradient.addColorStop(0.5, `hsla(${p.hue}, 75%, 50%, ${alpha * 0.5})`)
        gradient.addColorStop(1, `hsla(${p.hue}, 70%, 40%, 0)`)
        ctx.fillStyle = gradient
        ctx.beginPath()
        ctx.arc(p.x, p.y, p.size * 3, 0, Math.PI * 2)
        ctx.fill()

        ctx.fillStyle = `hsla(${p.hue}, 90%, 80%, ${alpha})`
        ctx.beginPath()
        ctx.arc(p.x, p.y, p.size * 0.5, 0, Math.PI * 2)
        ctx.fill()
      }

      animRef.current = requestAnimationFrame(animate)
    }
    animate()

    return () => {
      cancelAnimationFrame(animRef.current)
      window.removeEventListener('resize', resize)
    }
  }, [])

  const handleMove = useCallback((clientX: number, clientY: number) => {
    if (!isActive) return
    const canvas = canvasRef.current
    if (!canvas) return
    const rect = canvas.getBoundingClientRect()
    const x = clientX - rect.left
    const y = clientY - rect.top
    const hue = (x / rect.width) * 360
    const sat = 60 + (y / rect.height) * 30
    const light = 70 - (y / rect.height) * 30

    setCurrentColor({ h: hue, s: sat, l: light })
    setCurrentFreq(hueToFreq(hue))
    spawnParticles(x, y, hue)
  }, [isActive, spawnParticles])

  return (
    <div className="relative">
      <div
        className="relative w-full aspect-[16/9] rounded-2xl overflow-hidden cursor-crosshair border border-white/10"
        onMouseMove={(e) => handleMove(e.clientX, e.clientY)}
        onTouchMove={(e) => handleMove(e.touches[0].clientX, e.touches[0].clientY)}
        onMouseDown={() => setIsActive(true)}
        onMouseUp={() => setIsActive(false)}
        onMouseLeave={() => setIsActive(false)}
        onTouchStart={() => setIsActive(true)}
        onTouchEnd={() => setIsActive(false)}
      >
        <canvas ref={canvasRef} className="w-full h-full" />
        {!isActive && (
          <div className="absolute inset-0 flex items-center justify-center bg-black/40 backdrop-blur-sm">
            <motion.div
              animate={{ scale: [1, 1.05, 1], opacity: [0.8, 1, 0.8] }}
              transition={{ duration: 2, repeat: Infinity }}
              className="text-center"
            >
              <Sparkles className="w-10 h-10 mx-auto mb-3 text-purple-400" />
              <p className="text-lg font-medium text-white/90">Click & drag to paint with sound</p>
              <p className="text-sm text-white/50 mt-1">Each color becomes a unique frequency</p>
            </motion.div>
          </div>
        )}
      </div>
      {isActive && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="absolute bottom-4 left-4 right-4 flex items-center justify-between gap-3 bg-black/60 backdrop-blur-md rounded-xl p-3 border border-white/10"
        >
          <div className="flex items-center gap-3">
            <div
              className="w-8 h-8 rounded-lg shadow-lg"
              style={{ backgroundColor: `hsl(${currentColor.h}, ${currentColor.s}%, ${currentColor.l}%)` }}
            />
            <div>
              <p className="text-xs text-white/50">Hue</p>
              <p className="text-sm font-mono text-white">{Math.round(currentColor.h)}°</p>
            </div>
          </div>
          <div className="text-center">
            <p className="text-xs text-white/50">Note</p>
            <p className="text-lg font-bold text-white">{hueToNote(currentColor.h)}4</p>
          </div>
          <div className="text-right">
            <p className="text-xs text-white/50">Frequency</p>
            <p className="text-sm font-mono text-white">{Math.round(currentFreq)} Hz</p>
          </div>
        </motion.div>
      )}
    </div>
  )
}

// ─── Sound Visualizer Demo ───
function SoundVisualizer() {
  const [bars, setBars] = useState<number[]>(Array(32).fill(0))
  const [isPlaying, setIsPlaying] = useState(false)

  useEffect(() => {
    if (!isPlaying) return
    const interval = setInterval(() => {
      setBars(prev => prev.map((_, i) => {
        const base = Math.sin(Date.now() / 300 + i * 0.4) * 0.5 + 0.5
        const wave = Math.sin(Date.now() / 150 + i * 0.8) * 0.3
        return Math.max(0.05, Math.min(1, base + wave + Math.random() * 0.2))
      }))
    }, 50)
    return () => clearInterval(interval)
  }, [isPlaying])

  return (
    <div className="space-y-4">
      <div className="flex items-end gap-[3px] h-40 px-2">
        {bars.map((height, i) => (
          <motion.div
            key={i}
            className="flex-1 rounded-t-sm min-w-[4px]"
            style={{
              height: `${height * 100}%`,
              background: `linear-gradient(to top, hsl(${260 + i * 3}, 80%, 50%), hsl(${280 + i * 4}, 90%, 70%))`,
            }}
            animate={{ height: `${height * 100}%` }}
            transition={{ duration: 0.08 }}
          />
        ))}
      </div>
      <div className="flex gap-3">
        <Button
          onClick={() => setIsPlaying(!isPlaying)}
          className="flex-1 bg-gradient-to-r from-purple-600 to-fuchsia-600 hover:from-purple-500 hover:to-fuchsia-500 text-white border-0"
        >
          {isPlaying ? <Volume2 className="w-4 h-4 mr-2" /> : <Play className="w-4 h-4 mr-2" />}
          {isPlaying ? 'Listening...' : 'Visualize Sound'}
        </Button>
      </div>
    </div>
  )
}

// ─── Swift Code Preview ───
function SwiftCodePreview() {
  const swiftCode = `import SwiftUI
import AVFoundation
import CoreML
import Vision

// ═══════════════════════════════════════
//  Synesthesia — Cross-Sensory AI Engine
// ═══════════════════════════════════════

struct SynesthesiaApp: App {
    @StateObject private var sensorHub = SensorHub()
    @StateObject private var aiEngine = SynestheticEngine()
    
    var body: some Scene {
        WindowGroup {
            SynestheticHomeView()
                .environmentObject(sensorHub)
                .environmentObject(aiEngine)
        }
    }
}

// MARK: — Cross-Sensory Translation Engine
class SynestheticEngine: ObservableObject {
    @Published var currentMapping: SensoryMapping = .colorToSound
    @Published var outputSpectrum: [Float] = []
    
    private let audioEngine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private var hapticEngine: CHHapticEngine?
    
    /// Maps HSL color → musical frequency using
    /// perceptual color-to-pitch algorithms
    func colorToFrequency(_ hsl: HSLColor) -> Float {
        let hueAngle = hsl.hue / 360.0
        // Chromatic scale mapping (12-TET)
        let semitone = hueAngle * 12.0
        let baseFreq: Float = 261.63 // C4
        return baseFreq * pow(2.0, semitone / 12.0)
    }
    
    /// Transforms audio spectrum → particle system
    func spectrumToParticles(
        _ spectrum: [Float]
    ) -> [SynestheticParticle] {
        spectrum.enumerated().map { i, amp in
            SynestheticParticle(
                hue: Float(i) / Float(spectrum.count) * 360,
                radius: amp * 200,
                oscillation: .sine(freq: amp * 10)
            )
        }
    }
    
    /// Generates haptic pattern from audio features
    func audioToHaptics(
        _ features: AudioFeatures
    ) -> CHHapticPattern {
        // Map bass → strong haptics
        // Map treble → light, rapid taps
        // Map rhythm → pattern envelope
        let events = features.beats.map { beat in
            CHHapticEvent(
                eventType: .hapticTransient,
                relativeTime: beat.time,
                intensity: beat.energy,
                sharpness: beat.frequency
            )
        }
        return try! CHHapticPattern(events: events)
    }
}

// MARK: — Camera Color Scanner View
struct ColorScannerView: View {
    @StateObject private var camera = CameraManager()
    @EnvironmentObject var engine: SynestheticEngine
    
    var body: some View {
        ZStack {
            CameraPreview(camera: camera)
                .ignoresSafeArea()
            
            // Real-time color sampling overlay
            ColorSampleOverlay(
                centerColor: camera.dominantColor,
                onColorUpdate: { hsl in
                    let freq = engine.colorToFrequency(hsl)
                    engine.playTone(at: freq)
                    engine.triggerHaptics(for: hsl)
                }
            )
            
            // Synesthetic visualization ring
            SynestheticRing(
                hue: camera.dominantColor.hue,
                frequency: engine.colorToFrequency(
                    camera.dominantColor
                )
            )
        }
    }
}`

  return (
    <div className="relative rounded-xl overflow-hidden border border-white/10 bg-[#0d0a1a]">
      <div className="flex items-center gap-2 px-4 py-3 bg-white/5 border-b border-white/10">
        <div className="w-3 h-3 rounded-full bg-red-500/80" />
        <div className="w-3 h-3 rounded-full bg-yellow-500/80" />
        <div className="w-3 h-3 rounded-full bg-green-500/80" />
        <span className="ml-2 text-xs text-white/40 font-mono">SynesthesiaApp.swift</span>
      </div>
      <div className="overflow-auto max-h-[500px] p-4">
        <pre className="text-[13px] leading-relaxed font-mono text-white/80">
          <code>{swiftCode}</code>
        </pre>
      </div>
    </div>
  )
}

// ─── Main Page ───
export default function Home() {
  const [activeSection, setActiveSection] = useState(0)
  const heroRef = useRef<HTMLDivElement>(null)
  const { scrollYProgress } = useScroll()
  const heroOpacity = useTransform(scrollYProgress, [0, 0.15], [1, 0])
  const heroScale = useTransform(scrollYProgress, [0, 0.15], [1, 0.95])

  const sections = [
    { icon: Camera, title: 'See → Hear', desc: 'Point camera at any color. Hear it as a unique musical note. Red becomes low bass. Violet becomes high treble. The world becomes a symphony.' },
    { icon: Mic, title: 'Hear → See', desc: 'Capture any sound. Watch it explode into living particle art. Bass ripples outward. Treble sparks upward. Every sound paints a unique masterpiece.' },
    { icon: Hand, title: 'Feel → Understand', desc: 'Experience music through precision haptics. Bass thumps your palm. Melody dances on fingertips. Rhythm pulses through your hands. Sound becomes touch.' },
  ]

  const judgingCriteria = [
    { icon: Lightbulb, title: 'Innovation', color: 'from-amber-500 to-orange-500', desc: 'Cross-sensory AI translation is an entirely unexplored frontier in mobile computing. No app has ever mapped colors to sound, sound to visuals, and audio to haptics in a unified synesthetic experience.' },
    { icon: Heart, title: 'Social Impact', color: 'from-rose-500 to-pink-500', desc: 'Deaf users see music as living visual art. Blind users hear colors as musical landscapes. People with sensory processing differences gain new ways to perceive and interact with the world around them.' },
    { icon: Accessibility, title: 'Inclusivity', color: 'from-emerald-500 to-teal-500', desc: 'Full VoiceOver support, Dynamic Type, Switch Control, and AssistiveTouch. Designed with and for people with sensory disabilities — not as an afterthought, but as the core experience.' },
    { icon: Sparkles, title: 'Creativity', color: 'from-purple-500 to-fuchsia-500', desc: 'A sunset becomes a musical chord. A song becomes a painting. A conversation becomes a dance of light. Synesthesia transforms everyday moments into art.' },
  ]

  const techStack = [
    { icon: Cpu, title: 'Core ML', desc: 'On-device neural networks for real-time color classification, audio feature extraction, and sensory mapping prediction.' },
    { icon: Camera, title: 'AVFoundation', desc: 'Camera capture pipeline with real-time frame analysis, dominant color extraction, and scene understanding.' },
    { icon: Waves, title: 'Audio Engine', desc: 'Custom AVAudioEngine graph with sampler, oscillators, and spatial audio for frequency-accurate sound generation.' },
    { icon: Hand, title: 'Core Haptics', desc: 'CHHapticEngine for precise tactile feedback — mapping audio features to dynamic haptic patterns in real-time.' },
    { icon: Brain, title: 'Vision Framework', desc: 'VNDetectContoursRequest for shape analysis, VNClassifyImageRequest for scene categorization, and custom Core ML models.' },
    { icon: Layers, title: 'Metal Shaders', desc: 'Custom Metal compute shaders for GPU-accelerated particle systems and real-time audio-reactive visual effects.' },
  ]

  return (
    <div className="min-h-screen bg-[#080510] text-white overflow-x-hidden">
      {/* ═══ HERO ═══ */}
      <motion.section
        ref={heroRef}
        style={{ opacity: heroOpacity, scale: heroScale }}
        className="relative min-h-screen flex flex-col items-center justify-center px-4 sm:px-6"
      >
        {/* Animated bg gradient orbs */}
        <div className="absolute inset-0 overflow-hidden">
          <motion.div
            animate={{ x: [0, 40, -20, 0], y: [0, -30, 20, 0] }}
            transition={{ duration: 15, repeat: Infinity, ease: 'linear' }}
            className="absolute top-1/4 left-1/4 w-[500px] h-[500px] rounded-full bg-purple-600/20 blur-[120px]"
          />
          <motion.div
            animate={{ x: [0, -30, 20, 0], y: [0, 20, -40, 0] }}
            transition={{ duration: 18, repeat: Infinity, ease: 'linear' }}
            className="absolute top-1/3 right-1/4 w-[400px] h-[400px] rounded-full bg-fuchsia-500/15 blur-[100px]"
          />
          <motion.div
            animate={{ x: [0, 20, -30, 0], y: [0, -20, 30, 0] }}
            transition={{ duration: 20, repeat: Infinity, ease: 'linear' }}
            className="absolute bottom-1/4 left-1/3 w-[350px] h-[350px] rounded-full bg-violet-500/15 blur-[90px]"
          />
        </div>

        <div className="relative z-10 text-center max-w-5xl mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <Badge variant="secondary" className="mb-6 bg-white/10 text-white/80 border-white/20 hover:bg-white/15 px-4 py-1.5 text-sm">
              <Sparkles className="w-3.5 h-3.5 mr-1.5 text-purple-400" />
              Swift Student Challenge Submission
            </Badge>
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.15 }}
            className="text-6xl sm:text-7xl md:text-8xl lg:text-9xl font-black tracking-tight leading-[0.9]"
          >
            <span className="bg-gradient-to-r from-purple-400 via-fuchsia-400 to-violet-400 bg-clip-text text-transparent">
              Synesthesia
            </span>
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.3 }}
            className="mt-6 text-xl sm:text-2xl md:text-3xl font-light text-white/60 max-w-3xl mx-auto leading-relaxed"
          >
            Hear colors. See sound. Feel music.
          </motion.p>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.45 }}
            className="mt-4 text-base sm:text-lg text-white/40 max-w-2xl mx-auto"
          >
            An AI-powered iOS app that gives everyone the neurological superpower of cross-sensory perception — translating between sight, sound, and touch in real-time.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.6 }}
            className="mt-8 flex flex-wrap items-center justify-center gap-4"
          >
            <Button size="lg" className="bg-gradient-to-r from-purple-600 to-fuchsia-600 hover:from-purple-500 hover:to-fuchsia-500 text-white border-0 px-8 h-12 text-base">
              <Play className="w-5 h-5 mr-2" />
              Experience Demo
            </Button>
            <Button size="lg" variant="outline" className="border-white/20 text-white/80 hover:bg-white/10 hover:text-white px-8 h-12 text-base">
              <Code2 className="w-5 h-5 mr-2" />
              View Source
            </Button>
          </motion.div>

          {/* Three sense icons */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 1, delay: 0.8 }}
            className="mt-16 flex items-center justify-center gap-6 sm:gap-10"
          >
            {[
              { icon: Eye, label: 'Sight', color: 'text-violet-400' },
              { icon: Ear, label: 'Sound', color: 'text-fuchsia-400' },
              { icon: Hand, label: 'Touch', color: 'text-purple-400' },
            ].map((sense, i) => (
              <motion.div
                key={sense.label}
                animate={{ y: [0, -8, 0] }}
                transition={{ duration: 2, delay: i * 0.3, repeat: Infinity }}
                className="flex flex-col items-center gap-2"
              >
                <div className="w-14 h-14 rounded-2xl bg-white/5 border border-white/10 flex items-center justify-center backdrop-blur-sm">
                  <sense.icon className={`w-7 h-7 ${sense.color}`} />
                </div>
                <span className="text-xs text-white/40 font-medium uppercase tracking-wider">{sense.label}</span>
              </motion.div>
            ))}
            {/* Connection lines */}
            <svg className="absolute inset-0 w-full h-full pointer-events-none opacity-20" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <linearGradient id="lineGrad" x1="0" y1="0" x2="1" y2="0">
                  <stop offset="0%" stopColor="#8b5cf6" />
                  <stop offset="50%" stopColor="#d946ef" />
                  <stop offset="100%" stopColor="#7c3aed" />
                </linearGradient>
              </defs>
            </svg>
          </motion.div>
        </div>

        {/* Scroll indicator */}
        <motion.div
          animate={{ y: [0, 8, 0] }}
          transition={{ duration: 2, repeat: Infinity }}
          className="absolute bottom-8 left-1/2 -translate-x-1/2"
        >
          <ChevronDown className="w-6 h-6 text-white/30" />
        </motion.div>
      </motion.section>

      {/* ═══ HOW IT WORKS ═══ */}
      <section className="relative py-24 sm:py-32 px-4 sm:px-6">
        <div className="max-w-6xl mx-auto">
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <Badge variant="secondary" className="bg-white/10 text-white/70 border-white/15 mb-4">
              <Zap className="w-3 h-3 mr-1 text-fuchsia-400" />
              Three Mappings
            </Badge>
            <h2 className="text-4xl sm:text-5xl font-bold">
              <span className="bg-gradient-to-r from-purple-300 to-fuchsia-300 bg-clip-text text-transparent">Every sense speaks every language</span>
            </h2>
            <p className="mt-4 text-lg text-white/40 max-w-2xl mx-auto">Three real-time AI translation modes that bridge the gaps between how we perceive the world.</p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {sections.map((section, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.15 }}
              >
                <Card className="bg-white/[0.03] border-white/10 hover:border-purple-500/30 transition-colors h-full">
                  <CardHeader>
                    <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-purple-500/20 to-fuchsia-500/20 border border-purple-500/20 flex items-center justify-center mb-2">
                      <section.icon className="w-6 h-6 text-purple-300" />
                    </div>
                    <CardTitle className="text-xl text-white">{section.title}</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <p className="text-white/50 leading-relaxed">{section.desc}</p>
                  </CardContent>
                </Card>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══ INTERACTIVE DEMO ═══ */}
      <section className="relative py-24 sm:py-32 px-4 sm:px-6">
        <div className="max-w-6xl mx-auto">
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="text-center mb-12"
          >
            <Badge variant="secondary" className="bg-white/10 text-white/70 border-white/15 mb-4">
              <Sparkles className="w-3 h-3 mr-1 text-violet-400" />
              Live Demo
            </Badge>
            <h2 className="text-4xl sm:text-5xl font-bold">
              <span className="bg-gradient-to-r from-violet-300 to-purple-300 bg-clip-text text-transparent">Try it yourself</span>
            </h2>
            <p className="mt-4 text-lg text-white/40 max-w-xl mx-auto">Experience a taste of synesthetic perception right in your browser.</p>
          </motion.div>

          <Tabs defaultValue="color-sound" className="w-full">
            <TabsList className="bg-white/5 border border-white/10 mb-8 mx-auto flex w-auto">
              <TabsTrigger value="color-sound" className="data-[state=active]:bg-purple-600/30 data-[state=active]:text-white text-white/50 px-5">
                <Palette className="w-4 h-4 mr-2" /> Color → Sound
              </TabsTrigger>
              <TabsTrigger value="sound-visual" className="data-[state=active]:bg-purple-600/30 data-[state=active]:text-white text-white/50 px-5">
                <Music className="w-4 h-4 mr-2" /> Sound → Visual
              </TabsTrigger>
            </TabsList>
            <TabsContent value="color-sound">
              <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.5 }}>
                <SynestheticCanvas />
              </motion.div>
            </TabsContent>
            <TabsContent value="sound-visual">
              <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.5 }}>
                <Card className="bg-white/[0.03] border-white/10">
                  <CardContent className="p-6">
                    <SoundVisualizer />
                  </CardContent>
                </Card>
              </motion.div>
            </TabsContent>
          </Tabs>
        </div>
      </section>

      {/* ═══ JUDGING CRITERIA ═══ */}
      <section className="relative py-24 sm:py-32 px-4 sm:px-6">
        <div className="max-w-6xl mx-auto">
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <Badge variant="secondary" className="bg-white/10 text-white/70 border-white/15 mb-4">
              <Star className="w-3 h-3 mr-1 text-amber-400" />
              Why This Wins
            </Badge>
            <h2 className="text-4xl sm:text-5xl font-bold">
              <span className="bg-gradient-to-r from-amber-300 to-rose-300 bg-clip-text text-transparent">Excellence across every criterion</span>
            </h2>
            <p className="mt-4 text-lg text-white/40 max-w-2xl mx-auto">Apple judges on innovation, creativity, social impact, and inclusivity. Synesthesia delivers on all four.</p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {judgingCriteria.map((item, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, x: i % 2 === 0 ? -30 : 30 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
              >
                <Card className="bg-white/[0.03] border-white/10 hover:border-white/20 transition-all h-full group">
                  <CardContent className="p-6">
                    <div className="flex items-start gap-4">
                      <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${item.color} flex items-center justify-center shrink-0 shadow-lg`}>
                        <item.icon className="w-6 h-6 text-white" />
                      </div>
                      <div>
                        <h3 className="text-xl font-bold text-white mb-2">{item.title}</h3>
                        <p className="text-white/50 leading-relaxed">{item.desc}</p>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══ TECH STACK ═══ */}
      <section className="relative py-24 sm:py-32 px-4 sm:px-6">
        <div className="max-w-6xl mx-auto">
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <Badge variant="secondary" className="bg-white/10 text-white/70 border-white/15 mb-4">
              <Cpu className="w-3 h-3 mr-1 text-teal-400" />
              Technical Depth
            </Badge>
            <h2 className="text-4xl sm:text-5xl font-bold">
              <span className="bg-gradient-to-r from-teal-300 to-emerald-300 bg-clip-text text-transparent">Built with Apple frameworks</span>
            </h2>
            <p className="mt-4 text-lg text-white/40 max-w-2xl mx-auto">Six core Apple technologies working together in a real-time cross-sensory pipeline.</p>
          </motion.div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
            {techStack.map((tech, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.08 }}
              >
                <Card className="bg-white/[0.03] border-white/10 hover:border-teal-500/30 transition-colors h-full">
                  <CardContent className="p-5">
                    <tech.icon className="w-8 h-8 text-teal-400 mb-3" />
                    <h3 className="text-lg font-semibold text-white mb-1">{tech.title}</h3>
                    <p className="text-sm text-white/45 leading-relaxed">{tech.desc}</p>
                  </CardContent>
                </Card>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══ SWIFT CODE ═══ */}
      <section className="relative py-24 sm:py-32 px-4 sm:px-6">
        <div className="max-w-5xl mx-auto">
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="text-center mb-12"
          >
            <Badge variant="secondary" className="bg-white/10 text-white/70 border-white/15 mb-4">
              <Terminal className="w-3 h-3 mr-1 text-green-400" />
              Swift Source
            </Badge>
            <h2 className="text-4xl sm:text-5xl font-bold">
              <span className="bg-gradient-to-r from-green-300 to-teal-300 bg-clip-text text-transparent">Pure Swift. Pure Apple.</span>
            </h2>
            <p className="mt-4 text-lg text-white/40 max-w-xl mx-auto">Written entirely in SwiftUI with zero dependencies — just Apple frameworks.</p>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
          >
            <SwiftCodePreview />
          </motion.div>
        </div>
      </section>

      {/* ═══ 3-MIN EXPERIENCE ═══ */}
      <section className="relative py-24 sm:py-32 px-4 sm:px-6">
        <div className="max-w-4xl mx-auto">
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="text-center mb-12"
          >
            <Badge variant="secondary" className="bg-white/10 text-white/70 border-white/15 mb-4">
              <Smartphone className="w-3 h-3 mr-1 text-purple-400" />
              3-Minute Experience
            </Badge>
            <h2 className="text-4xl sm:text-5xl font-bold">
              <span className="bg-gradient-to-r from-purple-300 to-fuchsia-300 bg-clip-text text-transparent">Instant wow factor</span>
            </h2>
          </motion.div>

          <div className="space-y-4">
            {[
              { time: '0:00', title: 'Launch', desc: 'App opens with a mesmerizing gradient animation. Onboarding takes 5 seconds — just two taps.', icon: Zap },
              { time: '0:05', title: 'See → Hear Mode', desc: 'Point camera at a flower. Instantly hear a gentle chord. Move to a red wall — the sound deepens. You\'re hearing color.', icon: Camera },
              { time: '1:00', title: 'Hear → See Mode', desc: 'Switch modes. Clap your hands — watch particles explode. Play music — see a living painting form. Sound has shape.', icon: Mic },
              { time: '2:00', title: 'Feel Mode', desc: 'Enable haptics. A bass drop thumps your palm. A melody traces patterns on your fingers. You\'re touching sound.', icon: Hand },
              { time: '2:45', title: 'The Moment', desc: 'Combine all three. Point at a sunset, hear its chord, see it shimmer, feel its warmth. You have synesthesia. You understand.', icon: Sparkles },
            ].map((step, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, x: -20 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
              >
                <Card className="bg-white/[0.03] border-white/10 hover:border-purple-500/20 transition-colors">
                  <CardContent className="p-5 flex items-start gap-4">
                    <div className="flex flex-col items-center gap-1 shrink-0">
                      <div className="w-10 h-10 rounded-xl bg-purple-500/15 border border-purple-500/20 flex items-center justify-center">
                        <step.icon className="w-5 h-5 text-purple-400" />
                      </div>
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-1">
                        <span className="text-xs font-mono text-purple-400 bg-purple-500/10 px-2 py-0.5 rounded">{step.time}</span>
                        <h3 className="text-lg font-semibold text-white">{step.title}</h3>
                      </div>
                      <p className="text-white/45 leading-relaxed">{step.desc}</p>
                    </div>
                  </CardContent>
                </Card>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══ SUBMISSION SPECS ═══ */}
      <section className="relative py-24 sm:py-32 px-4 sm:px-6">
        <div className="max-w-5xl mx-auto">
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="text-center mb-12"
          >
            <Badge variant="secondary" className="bg-white/10 text-white/70 border-white/15 mb-4">
              <Shield className="w-3 h-3 mr-1 text-emerald-400" />
              Submission Ready
            </Badge>
            <h2 className="text-4xl sm:text-5xl font-bold">
              <span className="bg-gradient-to-r from-emerald-300 to-teal-300 bg-clip-text text-transparent">Competition compliant</span>
            </h2>
          </motion.div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
            {[
              { label: 'Format', value: '.swiftpm App Playground', icon: FileCode2 },
              { label: 'Platform', value: 'iOS 26 (Xcode 26 / Swift Playgrounds 4.6)', icon: Smartphone },
              { label: 'Experience', value: 'Under 3 minutes', icon: Zap },
              { label: 'Language', value: 'Swift 6 + SwiftUI', icon: Code2 },
              { label: 'AI/ML', value: 'Core ML (on-device)', icon: Brain },
              { label: 'Framework', value: 'Apple native only', icon: Layers },
            ].map((spec, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 15 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.08 }}
              >
                <Card className="bg-white/[0.03] border-white/10 text-center h-full">
                  <CardContent className="p-5">
                    <spec.icon className="w-7 h-7 text-emerald-400 mx-auto mb-3" />
                    <p className="text-xs text-white/40 uppercase tracking-wider mb-1">{spec.label}</p>
                    <p className="text-sm font-medium text-white/80">{spec.value}</p>
                  </CardContent>
                </Card>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══ FOOTER ═══ */}
      <footer className="border-t border-white/5 py-12 px-4 sm:px-6 mt-auto">
        <div className="max-w-6xl mx-auto text-center">
          <div className="flex items-center justify-center gap-2 mb-4">
            <Sparkles className="w-5 h-5 text-purple-400" />
            <span className="text-lg font-bold bg-gradient-to-r from-purple-400 to-fuchsia-400 bg-clip-text text-transparent">Synesthesia</span>
          </div>
          <p className="text-sm text-white/30 mb-2">Swift Student Challenge Submission</p>
          <p className="text-xs text-white/20">Hear colors. See sound. Feel music. Built with SwiftUI + Core ML + AVFoundation + Core Haptics + Vision + Metal.</p>
        </div>
      </footer>
    </div>
  )
}
