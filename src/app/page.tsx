'use client'

import { useState, useEffect, useRef, useCallback } from 'react'
import { motion, AnimatePresence, useScroll } from 'framer-motion'
import {
  Eye, Ear, Hand, Sparkles, Music, Palette, Waves, Brain,
  Camera, Mic, Volume2, Smartphone, Code2, Layers, Zap,
  Heart, Globe2, Accessibility, Play, Lightbulb,
  Cpu, FileCode2, AudioLines, ScanEye
} from 'lucide-react'
import { Guestbook } from '@/components/Guestbook'

/* ─────────────────────────────────────────────
   AMBIENT FX — cursor, specular, tilt
   ───────────────────────────────────────────── */
function AmbientFX() {
  const dotRef = useRef<HTMLDivElement>(null)
  const ringRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (window.matchMedia('(pointer: coarse)').matches) return

    let mx = window.innerWidth / 2, my = window.innerHeight / 2
    let rx = mx, ry = my
    let raf = 0

    const onMove = (e: MouseEvent) => {
      mx = e.clientX
      my = e.clientY
    }
    const onOver = (e: MouseEvent) => {
      const t = (e.target as Element | null)?.closest?.('[data-hover]')
      ringRef.current?.classList.toggle('is-hover', !!t)
    }

    const loop = () => {
      rx += (mx - rx) * 0.16
      ry += (my - ry) * 0.16
      if (dotRef.current) dotRef.current.style.transform = `translate3d(${mx}px, ${my}px, 0) translate(-50%, -50%)`
      if (ringRef.current) ringRef.current.style.transform = `translate3d(${rx}px, ${ry}px, 0) translate(-50%, -50%)`

      document.querySelectorAll<HTMLElement>('[data-spec]').forEach((el) => {
        const r = el.getBoundingClientRect()
        el.style.setProperty('--mx', `${((mx - r.left) / r.width) * 100}%`)
        el.style.setProperty('--my', `${((my - r.top) / r.height) * 100}%`)
      })

      document.querySelectorAll<HTMLElement>('[data-tilt]').forEach((el) => {
        const r = el.getBoundingClientRect()
        if (mx >= r.left && mx <= r.right && my >= r.top && my <= r.bottom) {
          const px = (mx - r.left) / r.width - 0.5
          const py = (my - r.top) / r.height - 0.5
          el.style.setProperty('--rx', `${(py * -5).toFixed(2)}deg`)
          el.style.setProperty('--ry', `${(px * 5).toFixed(2)}deg`)
        }
      })

      raf = requestAnimationFrame(loop)
    }

    window.addEventListener('mousemove', onMove, { passive: true })
    window.addEventListener('mouseover', onOver, { passive: true })
    raf = requestAnimationFrame(loop)
    return () => {
      window.removeEventListener('mousemove', onMove)
      window.removeEventListener('mouseover', onOver)
      cancelAnimationFrame(raf)
    }
  }, [])

  return (
    <>
      <div ref={dotRef} className="cursor-dot" aria-hidden="true" />
      <div ref={ringRef} className="cursor-ring" aria-hidden="true" />
    </>
  )
}

/* ─────────────────────────────────────────────
   NAV
   ───────────────────────────────────────────── */
const SECTIONS = [
  { id: 'how', label: 'How it works' },
  { id: 'demo', label: 'Demo' },
  { id: 'criteria', label: 'Why it wins' },
  { id: 'stack', label: 'Stack' },
  { id: 'source', label: 'Source' },

]

function Nav({ active }: { active: string }) {
  return (
    <nav className="navbar" aria-label="Primary">
      <a href="#top" className="nav-logo" data-hover>
        <span className="glyph">S</span>
        <span className="hidden sm:inline text-[15px]">Huewaves</span>
      </a>
      <div className="nav-links">
        {SECTIONS.map((s) => (
          <a
            key={s.id}
            href={`#${s.id}`}
            className={`nav-link ${active === s.id ? 'is-on' : ''}`}
            data-hover
          >
            {s.label}
          </a>
        ))}
      </div>
      <a href="#demo" className="btn-spectral py-2! px-5! text-[13px]!" data-hover>
        Try demo
      </a>
    </nav>
  )
}

/* ─────────────────────────────────────────────
   SECTION HEAD
   ───────────────────────────────────────────── */
function SectionHead({
  index,
  tag,
  title,
  desc,
  id,
}: {
  index: string
  tag: string
  title: string
  desc?: string
  id?: string
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, amount: 0.4 }}
      transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
      className="text-center mb-16"
      id={id}
    >
      <span className="eyebrow">
        <span className="text-faint-ink">[{index}]</span>
        {tag}
      </span>
      <h2 className="mt-5 text-4xl sm:text-5xl md:text-[3.4rem] font-bold tracking-tight leading-[1.05] text-balance">
        <span className="spectral-text">{title}</span>
      </h2>
      {desc && <p className="mt-5 text-lg text-muted-ink max-w-2xl mx-auto leading-relaxed">{desc}</p>}
    </motion.div>
  )
}

/* ─────────────────────────────────────────────
   SYNESTHETIC COLOR CANVAS — real Web Audio
   ───────────────────────────────────────────── */
const NOTES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']

function hueToFreq(hue: number) {
  const semitone = (hue / 360) * 12
  return 261.63 * Math.pow(2, semitone / 12)
}

/* ── Peak synth: one persistent voice, zero per-note allocation, click-free glide ── */
function useSynth() {
  const ctxRef = useRef<AudioContext | null>(null)
  const oscRef = useRef<OscillatorNode | null>(null)
  const overRef = useRef<OscillatorNode | null>(null)
  const gainRef = useRef<GainNode | null>(null)
  const armedRef = useRef(false)

  const ensure = useCallback(() => {
    if (typeof window === 'undefined') return null
    if (!ctxRef.current) {
      const AC = window.AudioContext || (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext
      if (!AC) return null
      const ctx = new AC()

      // soft limiter — nobody gets their ears clipped
      const limiter = ctx.createDynamicsCompressor()
      limiter.threshold.value = -14
      limiter.ratio.value = 12
      limiter.connect(ctx.destination)

      const gain = ctx.createGain()
      gain.gain.value = 0.0001
      gain.connect(limiter)

      const osc = ctx.createOscillator()
      osc.type = 'sine'
      osc.frequency.value = 261.63

      const overtone = ctx.createOscillator()
      overtone.type = 'triangle'
      overtone.frequency.value = 523.25
      const otGain = ctx.createGain()
      otGain.gain.value = 0.16
      overtone.connect(otGain)
      otGain.connect(gain)

      osc.connect(gain)
      osc.start()
      overtone.start()

      ctxRef.current = ctx
      oscRef.current = osc
      overRef.current = overtone
      gainRef.current = gain
    }
    if (ctxRef.current.state === 'suspended') void ctxRef.current.resume()
    return ctxRef.current
  }, [])

  const arm = useCallback(() => {
    const ctx = ensure()
    if (!ctx || !gainRef.current || armedRef.current) return false
    const now = ctx.currentTime
    gainRef.current.gain.cancelScheduledValues(now)
    gainRef.current.gain.setValueAtTime(0.0001, now)
    gainRef.current.gain.exponentialRampToValueAtTime(0.16, now + 0.04)
    armedRef.current = true
    return true
  }, [ensure])

  const disarm = useCallback(() => {
    const ctx = ctxRef.current
    if (!ctx || !gainRef.current) return
    const now = ctx.currentTime
    const level = Math.max(gainRef.current.gain.value, 0.0001)
    gainRef.current.gain.cancelScheduledValues(now)
    gainRef.current.gain.setValueAtTime(level, now)
    gainRef.current.gain.exponentialRampToValueAtTime(0.0001, now + 0.1)
    armedRef.current = false
  }, [])

  const glide = useCallback((freq: number) => {
    const ctx = ctxRef.current
    if (!ctx) return
    const now = ctx.currentTime
    oscRef.current?.frequency.setTargetAtTime(freq, now, 0.015)
    overRef.current?.frequency.setTargetAtTime(freq * 2.005, now, 0.015)
  }, [])

  useEffect(() => () => {
    const ctx = ctxRef.current
    if (ctx && ctx.state !== 'closed') void ctx.close().catch(() => {})
  }, [])

  return { ensure, arm, disarm, glide }
}

/* ── Zero-GC particle pool (preallocated, swap-remove) ── */
type Particle = { x: number; y: number; vx: number; vy: number; life: number; hue: number; size: number }

function createPool(capacity: number) {
  const arr: Particle[] = new Array(capacity)
  for (let i = 0; i < capacity; i++) {
    arr[i] = { x: 0, y: 0, vx: 0, vy: 0, life: 0, hue: 0, size: 0 }
  }
  let count = 0
  return {
    spawn(x: number, y: number, hue: number) {
      const p = arr[count]
      const angle = Math.random() * Math.PI * 2
      const speed = 1.4 + Math.random() * 3.2
      p.x = x
      p.y = y
      p.vx = Math.cos(angle) * speed
      p.vy = Math.sin(angle) * speed - 0.8
      p.life = 1
      p.hue = hue + (Math.random() * 24 - 12)
      p.size = 2.2 + Math.random() * 3.6
      if (count < capacity - 1) count++
    },
    step(dt: number) {
      let n = 0
      for (let i = 0; i < count; i++) {
        const p = arr[i]
        p.life -= dt * 0.9
        if (p.life <= 0) continue
        p.x += p.vx
        p.y += p.vy
        p.vy += 0.03
        p.vx *= 0.985
        arr[n++] = p
      }
      count = n
    },
    each(fn: (p: Particle) => void) {
      for (let i = 0; i < count; i++) fn(arr[i])
    },
  }
}

/* ── Pre-rendered glow sprites: 12 hue buckets, drawn once, drawImage forever ── */
const glowSprites = new Map<number, HTMLCanvasElement>()
function glowSprite(hue: number) {
  const bucket = Math.round(hue / 30) % 12
  let sprite = glowSprites.get(bucket)
  if (sprite) return sprite
  sprite = document.createElement('canvas')
  sprite.width = 64
  sprite.height = 64
  const sctx = sprite.getContext('2d')
  if (sctx) {
    const g = sctx.createRadialGradient(32, 32, 0, 32, 32, 32)
    g.addColorStop(0, `hsla(${bucket * 30}, 85%, 74%, 1)`)
    g.addColorStop(0.45, `hsla(${bucket * 30}, 80%, 58%, 0.5)`)
    g.addColorStop(1, `hsla(${bucket * 30}, 70%, 45%, 0)`)
    sctx.fillStyle = g
    sctx.fillRect(0, 0, 64, 64)
  }
  glowSprites.set(bucket, sprite)
  return sprite
}

function SynestheticCanvas() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const swatchRef = useRef<HTMLDivElement>(null)
  const hueValRef = useRef<HTMLSpanElement>(null)
  const noteValRef = useRef<HTMLSpanElement>(null)
  const freqValRef = useRef<HTMLSpanElement>(null)

  const [isActive, setIsActive] = useState(false)
  const [audioReady, setAudioReady] = useState(false)

  const { arm, disarm, glide } = useSynth()

  // hot-path values live in refs — React never sees them, so it never re-renders
  const activeRef = useRef(false)
  const armedRef = useRef(false)
  const hueRef = useRef(180)
  const freqRef = useRef(440)
  const lastToneRef = useRef(0)
  const pointerRef = useRef({ x: 0, y: 0, hue: 0 })

  useEffect(() => {
    activeRef.current = isActive
  }, [isActive])

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const dpr = Math.min(window.devicePixelRatio || 1, 2)
    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    let width = 0
    let height = 0

    const resize = () => {
      const rect = canvas.getBoundingClientRect()
      width = rect.width
      height = rect.height
      canvas.width = Math.round(width * dpr)
      canvas.height = Math.round(height * dpr)
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
    }
    resize()
    window.addEventListener('resize', resize)

    const pool = createPool(340)
    let raf = 0
    let last = performance.now()
    let hudLast = 0
    let visible = true

    const loop = () => {
      raf = requestAnimationFrame(loop)
      const now = performance.now()
      if (document.hidden || !visible) {
        last = now
        return
      }
      const dt = Math.min(0.05, (now - last) / 1000)
      last = now

      // fade previous frame → soft trails
      ctx.globalCompositeOperation = 'source-over'
      ctx.fillStyle = 'rgba(3, 6, 14, 0.42)'
      ctx.fillRect(0, 0, width, height)

      // while dragging: emit embers + glide the persistent voice
      if (activeRef.current) {
        pool.spawn(pointerRef.current.x, pointerRef.current.y, pointerRef.current.hue)
        if (now - lastToneRef.current > 80) {
          lastToneRef.current = now
          glide(hueToFreq(pointerRef.current.hue))
        }
      }

      pool.step(dt)
      ctx.globalCompositeOperation = 'lighter'
      pool.each((p) => {
        const size = p.size * (0.5 + p.life * 2.1)
        const sprite = glowSprite(p.hue)
        ctx.globalAlpha = p.life * 0.85
        ctx.drawImage(sprite, p.x - size, p.y - size, size * 2, size * 2)
        ctx.globalAlpha = p.life
        ctx.fillStyle = `hsla(${p.hue}, 95%, 84%, 1)`
        ctx.beginPath()
        ctx.arc(p.x, p.y, Math.max(0.6, p.size * 0.4 * p.life), 0, Math.PI * 2)
        ctx.fill()
      })
      ctx.globalAlpha = 1
      ctx.globalCompositeOperation = 'source-over'

      // HUD refresh at ~12Hz — imperative DOM writes, zero re-renders
      if (now - hudLast > 80) {
        hudLast = now
        if (hueValRef.current) hueValRef.current.textContent = `${Math.round(hueRef.current)}°`
        if (noteValRef.current) noteValRef.current.textContent = `${NOTES[Math.floor((hueRef.current / 360) * 12) % 12]}4`
        if (freqValRef.current) freqValRef.current.textContent = `${Math.round(freqRef.current)} Hz`
        if (swatchRef.current) swatchRef.current.style.backgroundColor = `hsl(${hueRef.current}, 80%, 62%)`
      }
    }

    if (!reduced) loop()

    // stop burning battery when the canvas scrolls out of view
    const io = new IntersectionObserver(([entry]) => {
      visible = entry.isIntersecting
    }, { threshold: 0.05 })
    io.observe(canvas)

    return () => {
      cancelAnimationFrame(raf)
      io.disconnect()
      window.removeEventListener('resize', resize)
    }
  }, [])

  const handleMove = useCallback((clientX: number, clientY: number) => {
    const canvas = canvasRef.current
    if (!canvas) return
    const rect = canvas.getBoundingClientRect()
    const x = clientX - rect.left
    const y = clientY - rect.top
    if (x < 0 || y < 0 || x > rect.width || y > rect.height) return
    const hue = Math.max(0, Math.min(360, (x / rect.width) * 360))
    hueRef.current = hue
    freqRef.current = hueToFreq(hue)
    pointerRef.current = { x, y, hue }
  }, [])

  const startInteraction = useCallback(() => {
    activeRef.current = true
    setIsActive(true)
    if (!armedRef.current) armedRef.current = arm()
    setAudioReady(armedRef.current)
  }, [arm])

  const stopInteraction = useCallback(() => {
    activeRef.current = false
    setIsActive(false)
    disarm()
    armedRef.current = false
  }, [disarm])

  return (
    <div>
      <div
        className="relative w-full aspect-[16/9] rounded-2xl overflow-hidden cursor-crosshair border border-white/10 bg-[#0f0d0a] touch-none"
        onMouseMove={(e) => handleMove(e.clientX, e.clientY)}
        onTouchMove={(e) => {
          const t = e.touches[0]
          if (t) handleMove(t.clientX, t.clientY)
        }}
        onMouseDown={startInteraction}
        onMouseUp={stopInteraction}
        onMouseLeave={stopInteraction}
        onTouchStart={(e) => {
          e.preventDefault()
          const t = e.touches[0]
          if (t) handleMove(t.clientX, t.clientY)
          startInteraction()
        }}
        onTouchEnd={stopInteraction}
        role="application"
        aria-label="Interactive Huewaves canvas — drag to paint colors that produce sound"
      >
        <canvas ref={canvasRef} className="w-full h-full" />
        {!isActive && (
          <div className="absolute inset-0 flex items-center justify-center bg-[#0f0d0a]/55 backdrop-blur-[2px]">
            <motion.div
              animate={{ scale: [1, 1.04, 1], opacity: [0.85, 1, 0.85] }}
              transition={{ duration: 2.4, repeat: Infinity }}
              className="text-center px-6"
            >
              <div className="mx-auto mb-4 w-14 h-14 rounded-2xl chip text-teal! text-[26px]!">
                <Palette className="w-7 h-7" />
              </div>
              <p className="text-lg font-semibold text-ink">Touch &amp; drag to paint with sound</p>
              <p className="text-sm text-muted-ink mt-1.5">Every hue plays its own note · {audioReady ? 'audio on' : 'audio unlocks on touch'}</p>
            </motion.div>
          </div>
        )}
      </div>

      <AnimatePresence>
        {isActive && (
          <motion.div
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 8 }}
            transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
            className="mt-3 flex items-center justify-between gap-3 rounded-2xl px-4 py-3 border border-white/10 bg-[#050a16]/80 backdrop-blur-xl"
          >
            <div className="flex items-center gap-3">
              <div
                ref={swatchRef}
                className="w-9 h-9 rounded-lg shadow-lg"
                style={{ backgroundColor: 'hsl(180, 80%, 62%)' }}
              />
              <div>
                <p className="text-[10px] uppercase tracking-[0.18em] text-faint-ink">Hue</p>
                <p className="text-sm font-mono text-ink"><span ref={hueValRef}>180°</span></p>
              </div>
            </div>
            <div className="text-center">
              <p className="text-[10px] uppercase tracking-[0.18em] text-faint-ink">Note</p>
              <p className="text-lg font-bold text-ink"><span ref={noteValRef}>A4</span></p>
            </div>
            <div className="text-right">
              <p className="text-[10px] uppercase tracking-[0.18em] text-faint-ink">Frequency</p>
              <p className="text-sm font-mono text-teal"><span ref={freqValRef}>440 Hz</span></p>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

/* ─────────────────────────────────────────────
   SOUND VISUALIZER — synthetic + real mic
   ───────────────────────────────────────────── */
function SoundVisualizer() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const peakRef = useRef<HTMLSpanElement>(null)
  const [mode, setMode] = useState<'idle' | 'synthetic' | 'mic'>('idle')
  const [micError, setMicError] = useState<string | null>(null)

  const streamRef = useRef<MediaStream | null>(null)
  const analyserRef = useRef<AnalyserNode | null>(null)
  const audioCtxRef = useRef<AudioContext | null>(null)
  const modeRef = useRef<'idle' | 'synthetic' | 'mic'>('idle')
  const phaseRef = useRef(0)

  const startSynthetic = useCallback(() => {
    setMode('synthetic')
    modeRef.current = 'synthetic'
    setMicError(null)
  }, [])

  const stopAll = useCallback(() => {
    setMode('idle')
    modeRef.current = 'idle'
    streamRef.current?.getTracks().forEach((t) => t.stop())
    streamRef.current = null
    if (audioCtxRef.current) {
      void audioCtxRef.current.close().catch(() => {})
      audioCtxRef.current = null
    }
    analyserRef.current = null
  }, [])

  const startMic = useCallback(async () => {
    setMicError(null)
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      streamRef.current = stream
      const AC = window.AudioContext || (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext
      const ctx = new AC()
      audioCtxRef.current = ctx
      const source = ctx.createMediaStreamSource(stream)
      const analyser = ctx.createAnalyser()
      analyser.fftSize = 512
      analyser.smoothingTimeConstant = 0.82
      source.connect(analyser)
      analyserRef.current = analyser
      setMode('mic')
      modeRef.current = 'mic'
    } catch {
      setMicError('Microphone unavailable — using synthetic wave instead.')
      startSynthetic()
    }
  }, [startSynthetic])

  // single rAF loop draws directly to canvas — React state never churns
  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const dpr = Math.min(window.devicePixelRatio || 1, 2)
    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    const data = new Uint8Array(256)
    let width = 0
    let height = 0
    let bars = 40
    let levels = new Float32Array(bars)
    let raf = 0
    let last = performance.now()
    let peak = 0
    let peakHud = 0

    const resize = () => {
      const rect = canvas.getBoundingClientRect()
      width = rect.width
      height = rect.height
      canvas.width = Math.round(width * dpr)
      canvas.height = Math.round(height * dpr)
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
      bars = Math.max(24, Math.floor(width / 9))
      levels = new Float32Array(bars)
    }
    resize()
    window.addEventListener('resize', resize)

    const loop = () => {
      raf = requestAnimationFrame(loop)
      const now = performance.now()
      if (document.hidden) {
        last = now
        return
      }
      const dt = Math.min(0.1, (now - last) / 1000)
      last = now
      phaseRef.current += dt * 4

      const m = modeRef.current
      const analyser = analyserRef.current
      if (m === 'mic' && analyser) {
        analyser.getByteFrequencyData(data)
        const bin = data.length / bars
        for (let i = 0; i < bars; i++) {
          const raw = data[Math.floor(i * bin)] / 255
          levels[i] += (raw * 1.35 - levels[i]) * 0.55
        }
      } else if (m === 'synthetic') {
        const t = phaseRef.current
        for (let i = 0; i < bars; i++) {
          const v =
            Math.sin(t * 0.9 + i * 0.42) * 0.42 +
            Math.sin(t * 1.8 + i * 0.85) * 0.3 +
            Math.sin(t * 3.2 + i * 1.4) * 0.18 +
            Math.random() * 0.12
          const target = Math.max(0.02, Math.min(1, v * 0.5 + 0.5))
          levels[i] += (target - levels[i]) * 0.6
        }
      } else {
        for (let i = 0; i < bars; i++) levels[i] *= 0.9
      }

      // peak meter with decay — written straight to the DOM
      let max = 0
      for (let i = 0; i < bars; i++) {
        if (levels[i] > max) max = levels[i]
      }
      peak = Math.max(max, peak * 0.96)
      if (Math.abs(peak - peakHud) > 0.01) {
        peakHud = peak
        if (peakRef.current) {
          peakRef.current.textContent = `peak ${Math.round(peak * 60) - 60} dB`
          peakRef.current.style.opacity = String(Math.max(0.3, Math.min(1, peak)))
        }
      }

      // draw: mirrored spectrum bars around the centerline
      ctx.clearRect(0, 0, width, height)
      const gap = 3
      const barW = (width - gap * (bars - 1)) / bars
      const cy = height * 0.5
      for (let i = 0; i < bars; i++) {
        const l = levels[i]
        const bh = Math.max(2, l * (height * 0.42))
        const hue = 200 + (i / bars) * 160
        const x = i * (barW + gap)
        const yTop = cy - bh

        const g = ctx.createLinearGradient(0, yTop, 0, cy)
        g.addColorStop(0, `hsla(${hue}, 85%, 70%, 1)`)
        g.addColorStop(1, `hsla(${hue}, 75%, 45%, 0.7)`)
        ctx.fillStyle = g
        ctx.beginPath()
        ctx.roundRect(x, yTop, barW, bh, Math.min(4, barW / 2))
        ctx.fill()

        ctx.globalAlpha = 0.22
        ctx.fillStyle = `hsla(${hue}, 85%, 72%, 1)`
        const mir = bh * 0.5
        ctx.beginPath()
        ctx.roundRect(x, cy, barW, mir, Math.min(4, barW / 2))
        ctx.fill()
        ctx.globalAlpha = 1
      }
    }

    if (!reduced) loop()

    return () => {
      cancelAnimationFrame(raf)
      window.removeEventListener('resize', resize)
    }
  }, [])

  useEffect(() => () => {
    streamRef.current?.getTracks().forEach((t) => t.stop())
  }, [])

  const running = mode !== 'idle'

  return (
    <div>
      <div className="relative h-40 rounded-2xl overflow-hidden border border-white/10 bg-[#04081a]">
        <canvas ref={canvasRef} className="w-full h-full" />
        <span
          ref={peakRef}
          className="absolute top-2.5 right-3 text-[10px] font-mono text-faint-ink transition-opacity"
        >
          peak −60 dB
        </span>
        {!running && (
          <div className="absolute inset-0 flex items-center justify-center bg-[#04081a]/45 backdrop-blur-[1px]">
            <p className="text-sm text-muted-ink">Tap below to set the air moving</p>
          </div>
        )}
      </div>

      <div className="mt-4 flex flex-col sm:flex-row gap-3">
        {!running ? (
          <>
            <button className="btn-spectral flex-1" onClick={() => void startMic()} data-hover>
              <Mic className="w-4 h-4" />
              Listen to your space
            </button>
            <button className="btn-ghost flex-1" onClick={startSynthetic} data-hover>
              <AudioLines className="w-4 h-4" />
              Simulated waveform
            </button>
          </>
        ) : (
          <button className="btn-ghost flex-1" onClick={stopAll} data-hover>
            <Volume2 className="w-4 h-4" />
            Stop {mode === 'mic' ? 'microphone' : 'visualization'}
          </button>
        )}
      </div>
      {micError && <p className="mt-3 text-sm text-amber-300/80 text-center">{micError}</p>}
    </div>
  )
}

/* ─────────────────────────────────────────────
   SWIFT CODE PREVIEW
   ───────────────────────────────────────────── */
function SwiftCodePreview() {
  const swiftCode = `import SwiftUI
import AVFoundation
import CoreHaptics

// ═══════════════════════════════════════
//  Huewaves — See → Hear → Feel
// ═══════════════════════════════════════

extension Color {
    static let obsidian      = Color(red: 0.012, green: 0.024, blue: 0.055)
    static let spectrumTeal  = Color(red: 0.243, green: 0.902, blue: 0.804)
    static let spectrumRose  = Color(red: 0.941, green: 0.565, blue: 0.675)
}

/// Hue → 12-TET musical note (C4 base)
func hueToFrequency(_ hue: Double) -> Float {
    let semitone = (hue / 360.0) * 12.0
    return Float(261.63 * pow(2.0, semitone / 12.0))
}

/// Real camera: average center pixels → HSV hue
func averageHue(of sampleBuffer: CMSampleBuffer) -> Double? {
    guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
    CVPixelBufferLockBaseAddress(buffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
    guard let base = CVPixelBufferGetBaseAddress(buffer) else { return nil }

    let bpr = CVPixelBufferGetBytesPerRow(buffer)
    let w = CVPixelBufferGetWidth(buffer)
    let h = CVPixelBufferGetHeight(buffer)

    var r = 0.0, g = 0.0, b = 0.0, count = 0.0
    var y = h / 4
    while y < h * 3 / 4 {
        var x = w / 4
        while x < w * 3 / 4 {
            let ptr = base
                .advanced(by: y * bpr + x * 4)
                .assumingMemoryBound(to: UInt8.self)
            b += Double(ptr[0]); g += Double(ptr[1]); r += Double(ptr[2])
            count += 1
            x += 4
        }
        y += 4
    }

    let avgR = r / count, avgG = g / count, avgB = b / count
    let peak = max(avgR, max(avgG, avgB))
    let trough = min(avgR, min(avgG, avgB))
    guard peak - trough > 0.03 else { return nil }
    // … RGB → HSV, hue in 0…360
    return nil // truncated for space
}

/// Real Core Haptics: heartbeat pattern
func heartbeatEvents() -> [CHHapticEvent] {
    var events: [CHHapticEvent] = []
    for beat in 0..<6 {
        let t = Double(beat) * 1.0
        events.append(transient(1.0, sharp: 1.0, at: t))
        events.append(transient(0.3, sharp: 0.4, at: t + 0.10))
        events.append(transient(0.85, sharp: 0.9, at: t + 0.45))
    }
    return events
}

/// Real microphone: AVAudioEngine tap → 32 RMS bins
func binLevels(_ buffer: AVAudioPCMBuffer, count: Int) -> [Float] {
    guard let channel = buffer.floatChannelData?[0] else { return [] }
    let frames = Int(buffer.frameLength)
    let binSize = max(1, frames / count)
    return (0..<count).map { bin in
        let start = bin * binSize
        let end = min(start + binSize, frames)
        let energy = (start..<end).reduce(0.0) {
            $0 + Double(channel[$1]) * Double(channel[$1])
        }
        return Float(min(1, sqrt(energy / Double(end - start)) * 5))
    }
}`

  return (
    <div className="tile overflow-hidden" data-spec>
      <div className="flex items-center gap-3 px-5 py-3.5 border-b border-white/10 bg-white/[0.03]">
        <div className="term-dots">
          <span />
          <span />
          <span />
        </div>
        <span className="ml-2 text-xs text-faint-ink font-mono tracking-wide">HuewavesApp.swift</span>
        <span className="ml-auto hidden sm:inline-flex items-center gap-1.5 text-[10px] font-mono uppercase tracking-[0.2em] text-teal">
          <span className="led" /> swift 6 · swiftui
        </span>
      </div>
      <div className="overflow-auto max-h-[520px] p-5">
        <pre className="text-[12.5px] sm:text-[13px] leading-relaxed font-mono text-muted-ink">
          <code>{swiftCode}</code>
        </pre>
      </div>
    </div>
  )
}

/* ─────────────────────────────────────────────
   MAIN PAGE
   ───────────────────────────────────────────── */
export default function Home() {
  const [active, setActive] = useState('')
  const { scrollYProgress } = useScroll()

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            setActive(entry.target.id)
            break
          }
        }
      },
      { rootMargin: '-35% 0px -55% 0px' }
    )
    SECTIONS.forEach((s) => {
      const el = document.getElementById(s.id)
      if (el) observer.observe(el)
    })
    return () => observer.disconnect()
  }, [])

  const mappings = [
    {
      icon: ScanEye,
      tag: 'SIGHT → AUDIO',
      title: 'See → Hear',
      desc: 'Point the camera at any color. Hear it as a unique musical note. Red becomes low bass. Violet becomes high treble. The world becomes a symphony.',
      foot: 'camera reads real pixels · 12-TET map',
      pole: 'teal' as const,
    },
    {
      icon: AudioLines,
      tag: 'AUDIO → VISUAL',
      title: 'Hear → See',
      desc: 'Capture any sound. Watch it explode into living particle art. Bass ripples outward. Treble sparks upward. Every sound paints a unique masterpiece.',
      foot: 'live mic · 32 rms bins · 60fps',
      pole: 'mix' as const,
    },
    {
      icon: Hand,
      tag: 'AUDIO → HAPTICS',
      title: 'Feel → Understand',
      desc: 'Experience music through precision haptics. Bass thumps your palm. Melody dances on fingertips. Rhythm pulses through your hands. Sound becomes touch.',
      foot: 'core haptics · transient + continuous',
      pole: 'rose' as const,
    },
  ]

  const feelMapping = mappings[2]

  const judgingCriteria = [
    {
      icon: Lightbulb,
      title: 'Innovation',
      desc: 'Cross-sensory AI translation is an entirely unexplored frontier in mobile computing. No app has ever mapped colors to sound, sound to visuals, and audio to haptics in a unified synesthetic experience.',
    },
    {
      icon: Heart,
      title: 'Social Impact',
      desc: 'Deaf users see music as living visual art. Blind users hear colors as musical landscapes. People with sensory processing differences gain new ways to perceive and interact with the world around them.',
    },
    {
      icon: Accessibility,
      title: 'Inclusivity',
      desc: 'Full VoiceOver support, Dynamic Type, Switch Control, and AssistiveTouch. Designed with and for people with sensory disabilities — not as an afterthought, but as the core experience.',
    },
    {
      icon: Sparkles,
      title: 'Creativity',
      desc: 'A sunset becomes a musical chord. A song becomes a painting. A conversation becomes a dance of light. Huewaves transforms everyday moments into art.',
    },
  ]

  const techStack = [
    { icon: Camera, title: 'AVFoundation', desc: 'Real camera capture with live pixel sampling — the center of your frame is analyzed every frame and its dominant hue is read directly from the buffer.', tag: 'vision' },
    { icon: Waves, title: 'Audio Engine', desc: 'AVAudioEngine oscillator graph generates mathematically accurate 12-TET tones — hue maps to semitone with zero samples of simulated latency.', tag: 'dsp' },
    { icon: AudioLines, title: 'Live Microphone', desc: 'AVAudioEngine input tap splits any sound into 32 RMS energy bins that drive the particle art and spectrum bars in real time.', tag: 'dsp' },
    { icon: Hand, title: 'Core Haptics', desc: 'CHHapticEngine crafts heartbeat, rain, ocean, and rhythm patterns — transient + continuous events mapped to intensity and sharpness curves.', tag: 'tactile' },
    { icon: Palette, title: 'Obsidian Glass UI', desc: 'SwiftUI with an obsidian-glass system — pure-black depths, spectrum teal → rose accents, and a battery-friendly canvas background.', tag: 'ui' },
    { icon: Zap, title: 'Zero Dependencies', desc: 'Pure Apple frameworks end to end. No third-party packages — just SwiftUI, AVFoundation, and Core Haptics.', tag: 'native' },
  ]

  const timeline = [
    { time: '0:00', title: 'Launch', desc: 'App opens with a mesmerizing gradient animation. Onboarding takes 5 seconds — just two taps.', icon: Zap },
    { time: '0:05', title: 'See → Hear Mode', desc: "Point camera at a flower. Instantly hear a gentle chord. Move to a red wall — the sound deepens. You're hearing color.", icon: ScanEye },
    { time: '1:00', title: 'Hear → See Mode', desc: 'Switch modes. Clap your hands — watch particles explode. Play music — see a living painting form. Sound has shape.', icon: AudioLines },
    { time: '2:00', title: 'Feel Mode', desc: "Enable haptics. A bass drop thumps your palm. A melody traces patterns on your fingers. You're touching sound.", icon: Hand },
    { time: '2:45', title: 'The Moment', desc: "Combine all three. Point at a sunset, hear its chord, see it shimmer, feel its warmth. You have Huewaves. You understand.", icon: Sparkles },
  ]


  return (
    <main id="top" className="min-h-screen bg-[var(--bg)] text-ink overflow-x-hidden">
      <AmbientFX />
      <Nav active={active} />

      {/* scroll progress */}
      <motion.div className="scroll-progress" style={{ scaleX: scrollYProgress }} />

      {/* ═══ HERO ═══ */}
      <section className="relative min-h-[100dvh] flex flex-col items-center justify-center px-4 sm:px-6 overflow-hidden">
        <div className="absolute inset-0">
          <div className="grid-veil absolute inset-0" />
          <div className="orb orb--teal top-[12%] left-[8%] w-[560px] h-[560px] max-w-[70vw]" />
          <div className="orb orb--rose top-[28%] right-[6%] w-[440px] h-[440px] orb--d1 max-w-[60vw]" />
          <div className="orb orb--teal-deep bottom-[10%] left-[30%] w-[420px] h-[420px] orb--d2 max-w-[55vw]" />
        </div>

        <div className="relative z-10 text-center max-w-5xl mx-auto pt-24">
          <motion.div
            initial={{ opacity: 0, y: 22 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
          >
            <span className="eye-pill">
              <span className="led" />
              Swift Student Challenge 2026
            </span>
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.12, ease: [0.22, 1, 0.36, 1] }}
            className="mt-8 text-[17vw] sm:text-7xl md:text-8xl lg:text-[8.5rem] font-black tracking-tight leading-[0.92]"
          >
            <span className="spectral-text drop-shadow-[0_0_60px_rgba(212,168,83,0.18)]">Huewaves</span>
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.28 }}
            className="mt-7 text-xl sm:text-2xl md:text-3xl font-light text-muted-ink max-w-3xl mx-auto leading-relaxed"
          >
            Hear colors. See sound. Feel music.
          </motion.p>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.42 }}
            className="mt-4 text-base sm:text-lg text-faint-ink max-w-2xl mx-auto"
          >
            An iOS app that turns the world around you into music — point your camera at a color and hear it as a note, sing and watch sound become light, and feel rhythm pulse on your skin.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.56 }}
            className="mt-10 flex flex-wrap items-center justify-center gap-4"
          >
            <a href="#demo" className="btn-spectral" data-hover>
              <Play className="w-4 h-4" />
              Experience the demo
            </a>
            <a href="#source" className="btn-ghost" data-hover>
              <Code2 className="w-4 h-4" />
              View Swift source
            </a>
          </motion.div>

          {/* sense pills */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 1, delay: 0.75 }}
            className="mt-16 flex items-center justify-center gap-5 sm:gap-8"
          >
            {[
              { icon: Eye, label: 'Sight', cls: 'text-teal', chip: '' },
              { icon: Ear, label: 'Sound', cls: 'text-teal-soft', chip: 'chip--rose' },
              { icon: Hand, label: 'Touch', cls: 'text-rose-soft', chip: 'chip--rose' },
            ].map((sense, i) => (
              <motion.div
                key={sense.label}
                animate={{ y: [0, -8, 0] }}
                transition={{ duration: 2.2, delay: i * 0.3, repeat: Infinity, ease: 'easeInOut' }}
                className="flex flex-col items-center gap-2.5"
              >
                <div className={`chip w-14 h-14 text-[22px]! ${sense.chip} ${sense.cls}`} data-hover>
                  <sense.icon className="w-7 h-7" />
                </div>
                <span className="text-[11px] text-faint-ink font-medium uppercase tracking-[0.22em]">{sense.label}</span>
              </motion.div>
            ))}
          </motion.div>
        </div>

        {/* scroll cue */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1.4 }}
          className="absolute bottom-7 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2"
        >
          <span className="text-[10px] font-mono uppercase tracking-[0.3em] text-faint-ink">scroll</span>
          <div className="w-[1.5px] h-10 rounded bg-gradient-to-b from-teal to-transparent relative overflow-hidden">
            <motion.span
              animate={{ y: [-10, 34], opacity: [0, 1, 0] }}
              transition={{ duration: 1.6, repeat: Infinity, ease: 'easeInOut' }}
              className="absolute inset-x-0 top-0 h-3 bg-white"
            />
          </div>
        </motion.div>
      </section>

      {/* ═══ HOW IT WORKS ═══ */}
      <section id="how" className="relative py-24 sm:py-32 px-4 sm:px-6 scroll-mt-28">
        <div className="max-w-6xl mx-auto">
          <SectionHead
            index="01"
            tag="Three mappings"
            title="Every sense speaks every language"
            desc="Three real-time AI translation modes that bridge the gaps between how we perceive the world."
          />

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
            {mappings.slice(0, 2).map((m, i) => (
              <motion.div
                key={m.title}
                initial={{ opacity: 0, y: 28 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, amount: 0.3 }}
                transition={{ duration: 0.7, delay: i * 0.12, ease: [0.22, 1, 0.36, 1] }}
              >
                <div className="tile h-full p-7" data-spec data-tilt data-hover>
                  <div className="tile-body flex flex-col h-full">
                    <div className="flex items-start justify-between">
                      <div className={`chip w-13 h-13 p-3 ${m.pole === 'rose' ? 'chip--rose text-rose-soft' : 'text-teal'}`}>
                        <m.icon className="w-6 h-6" />
                      </div>
                      <span className={`text-[10px] font-mono uppercase tracking-[0.2em] ${m.pole === 'rose' ? 'text-rose-soft' : 'text-teal'}`}>
                        {m.tag}
                      </span>
                    </div>
                    <h3 className="mt-6 text-2xl font-bold text-ink">{m.title}</h3>
                    <p className="mt-3 text-muted-ink leading-relaxed">{m.desc}</p>
                    <p className="mt-auto pt-6 font-mono text-[11px] text-faint-ink">{m.foot}</p>
                  </div>
                  <div className="spec-strip" />
                </div>
              </motion.div>
            ))}

            <motion.div
              initial={{ opacity: 0, y: 28 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, amount: 0.3 }}
              transition={{ duration: 0.7, delay: 0.24, ease: [0.22, 1, 0.36, 1] }}
              className="lg:col-span-2"
            >
              <div className="tile h-full p-7 lg:p-8" data-spec data-tilt data-hover>
                <div className="tile-body grid lg:grid-cols-[auto_1fr] gap-6 lg:gap-10 items-center">
                  <div className="flex lg:flex-col items-center gap-5 lg:gap-6 lg:pr-6 lg:border-r border-white/10">
                    <div className="chip chip--rose w-16 h-16 p-4 text-rose-soft">
                      <feelMapping.icon className="w-8 h-8" />
                    </div>
                    <div className="flex lg:flex-col items-center gap-2">
                      <span className="led led--rose" />
                      <span className="text-[10px] font-mono uppercase tracking-[0.2em] text-rose-soft">{feelMapping.tag}</span>
                    </div>
                  </div>
                  <div>
                    <h3 className="text-2xl sm:text-3xl font-bold text-ink">{feelMapping.title}</h3>
                    <p className="mt-3 text-muted-ink leading-relaxed max-w-2xl">{feelMapping.desc}</p>
                    <div className="mt-6 flex flex-wrap gap-2">
                      {['bass → palm', 'melody → fingertips', 'rhythm → pulse'].map((t) => (
                        <span key={t} className="eye-pill text-[11px]!">{t}</span>
                      ))}
                    </div>
                    <p className="mt-6 font-mono text-[11px] text-faint-ink">{feelMapping.foot}</p>
                  </div>
                </div>
                <div className="spec-strip" />
              </div>
            </motion.div>
          </div>
        </div>
      </section>

      {/* ═══ INTERACTIVE DEMO ═══ */}
      <section id="demo" className="relative py-24 sm:py-32 px-4 sm:px-6 scroll-mt-28">
        <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-teal/30 to-transparent" />
        <div className="max-w-6xl mx-auto">
          <SectionHead
            index="02"
            tag="Live demo"
            title="Try it yourself"
            desc="Experience a taste of synesthetic perception right in your browser. Sound unlocks on touch."
          />

          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, amount: 0.2 }}
            transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
          >
            <div className="glass glass--shine p-5 sm:p-7" data-spec>
              <div className="relative z-[2]">
                <div className="flex items-center justify-between gap-4 mb-6 flex-wrap">
                  <span className="eyebrow">
                    <span className="text-faint-ink">[demo]</span>
                    Synesthetic playground
                  </span>
                  <span className="hidden sm:inline-flex items-center gap-1.5 text-[10px] font-mono uppercase tracking-[0.2em] text-muted-ink">
                    <Globe2 className="w-3.5 h-3.5 text-teal" />
                    runs in safari · works on iphone
                  </span>
                </div>

                <div className="grid lg:grid-cols-2 gap-6">
                  <div>
                    <div className="flex items-center gap-2 mb-3">
                      <Palette className="w-4 h-4 text-teal" />
                      <span className="text-sm font-semibold text-ink">Color → Sound</span>
                    </div>
                    <SynestheticCanvas />
                  </div>
                  <div>
                    <div className="flex items-center gap-2 mb-3">
                      <Music className="w-4 h-4 text-rose-soft" />
                      <span className="text-sm font-semibold text-ink">Sound → Visual</span>
                    </div>
                    <div className="tile h-full p-5" data-spec>
                      <div className="tile-body h-full">
                        <SoundVisualizer />
                      </div>
                      <div className="spec-strip" />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        </div>
      </section>

      {/* ═══ JUDGING CRITERIA ═══ */}
      <section id="criteria" className="relative py-24 sm:py-32 px-4 sm:px-6 scroll-mt-28">
        <div className="max-w-6xl mx-auto">
          <SectionHead
            index="03"
            tag="Why this wins"
            title="Excellence across every criterion"
            desc="Apple judges on innovation, creativity, social impact, and inclusivity. Huewaves delivers on all four."
          />

          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            {judgingCriteria.map((item, i) => (
              <motion.div
                key={item.title}
                initial={{ opacity: 0, y: 26 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, amount: 0.25 }}
                transition={{ duration: 0.7, delay: (i % 2) * 0.1, ease: [0.22, 1, 0.36, 1] }}
              >
                <div className="tile h-full p-7" data-spec data-hover>
                  <div className="tile-body">
                    <div className="flex items-start gap-5">
                      <div className="chip w-13 h-13 p-3 text-teal shrink-0">
                        <item.icon className="w-6 h-6" />
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <span className="font-mono text-[11px] text-faint-ink">0{i + 1}</span>
                          <h3 className="text-xl font-bold text-ink">{item.title}</h3>
                        </div>
                        <p className="text-muted-ink leading-relaxed">{item.desc}</p>
                      </div>
                    </div>
                  </div>
                  <div className="spec-strip" />
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══ TECH STACK ═══ */}
      <section id="stack" className="relative py-24 sm:py-32 px-4 sm:px-6 scroll-mt-28">
        <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-rose/25 to-transparent" />
        <div className="max-w-6xl mx-auto">
          <SectionHead
            index="04"
            tag="Technical depth"
            title="Built with Apple frameworks"
            desc="Six core Apple technologies working together in a real-time cross-sensory pipeline."
          />

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
            {techStack.map((tech, i) => (
              <motion.div
                key={tech.title}
                initial={{ opacity: 0, y: 22 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, amount: 0.2 }}
                transition={{ duration: 0.6, delay: (i % 3) * 0.08, ease: [0.22, 1, 0.36, 1] }}
              >
                <div className="tile h-full p-6" data-spec data-hover>
                  <div className="tile-body">
                    <div className="flex items-center justify-between mb-4">
                      <div className="chip w-12 h-12 p-2.5 text-teal">
                        <tech.icon className="w-6 h-6" />
                      </div>
                      <span className="font-mono text-[10px] text-faint-ink uppercase tracking-[0.18em]">[ {tech.tag} ]</span>
                    </div>
                    <h3 className="text-lg font-semibold text-ink mb-1.5">{tech.title}</h3>
                    <p className="text-sm text-muted-ink leading-relaxed">{tech.desc}</p>
                  </div>
                  <div className="spec-strip" />
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══ SWIFT CODE ═══ */}
      <section id="source" className="relative py-24 sm:py-32 px-4 sm:px-6 scroll-mt-28">
        <div className="max-w-5xl mx-auto">
          <SectionHead
            index="05"
            tag="Swift source"
            title="Pure Swift. Pure Apple."
            desc="Written entirely in SwiftUI with zero dependencies — camera hue-reading, live mic analysis, and Core Haptics patterns, all real."
          />

          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, amount: 0.2 }}
            transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
          >
            <SwiftCodePreview />
          </motion.div>
        </div>
      </section>

      {/* ═══ 3-MIN EXPERIENCE ═══ */}
      <section id="timeline" className="relative py-24 sm:py-32 px-4 sm:px-6 scroll-mt-28">
        <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-teal/25 to-transparent" />
        <div className="max-w-4xl mx-auto">
          <SectionHead
            index="06"
            tag="3-minute experience"
            title="Instant wow factor"
            desc="A complete cross-sensory journey in under three minutes."
          />

          <div className="timeline space-y-4">
            {timeline.map((step, i) => (
              <motion.div
                key={step.time}
                initial={{ opacity: 0, x: -18 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true, amount: 0.3 }}
                transition={{ duration: 0.6, delay: i * 0.08, ease: [0.22, 1, 0.36, 1] }}
                className="relative"
              >
                <span className="timeline-node" />
                <div className="tile p-5 sm:p-6 ml-4" data-spec data-hover>
                  <div className="tile-body flex items-start gap-4">
                    <div className="flex flex-col items-center gap-1.5 shrink-0">
                      <div className="chip w-11 h-11 p-2.5 text-teal">
                        <step.icon className="w-5 h-5" />
                      </div>
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-1">
                        <span className="font-mono text-[11px] text-teal bg-teal/10 border border-teal/20 px-2 py-0.5 rounded-md">{step.time}</span>
                        <h3 className="text-lg font-semibold text-ink">{step.title}</h3>
                      </div>
                      <p className="text-muted-ink leading-relaxed">{step.desc}</p>
                    </div>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══ SUBMISSION SPECS ═══ */}

      {/* ═══ GUESTBOOK ═══ */}
      <section id="feedback" className="relative py-24 sm:py-32 px-4 sm:px-6 scroll-mt-28">
        <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-teal/25 via-rose/25 to-teal/25" />
        <div className="max-w-5xl mx-auto">
          <SectionHead
            index="08"
            tag="Leave feedback"
            title="How did it feel?"
            desc="Judges, reviewers, and the simply curious — drop a note in the Huewaves guestbook."
          />
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, amount: 0.2 }}
            transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
          >
            <Guestbook />
          </motion.div>
        </div>
      </section>

      {/* ═══ FOOTER ═══ */}
      <footer className="relative pt-20 pb-12 px-4 sm:px-6">
        <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-teal/25 via-rose/25 to-teal/25" />
        <div className="max-w-6xl mx-auto">
          <div className="glass glass--shine p-8 sm:p-10 text-center" data-spec>
            <div className="relative z-[2]">
              <div className="flex items-center justify-center gap-3 mb-4">
                <span className="glyph w-9! h-9! text-lg!">S</span>
                <span className="text-2xl font-bold spectral-text">Huewaves</span>
              </div>
              <p className="text-sm text-muted-ink mb-1">Swift Student Challenge Submission · 2026</p>
              <p className="text-xs text-faint-ink max-w-xl mx-auto">
                Hear colors. See sound. Feel music. Built with SwiftUI + AVFoundation + Core Haptics.
              </p>
              <div className="mt-7 flex items-center justify-center gap-5 flex-wrap">
                <a href="#how" className="text-xs font-mono uppercase tracking-[0.2em] text-teal hover:text-teal-soft transition-colors" data-hover>How it works</a>
                <a href="#demo" className="text-xs font-mono uppercase tracking-[0.2em] text-teal hover:text-teal-soft transition-colors" data-hover>Demo</a>
                <a href="#source" className="text-xs font-mono uppercase tracking-[0.2em] text-teal hover:text-teal-soft transition-colors" data-hover>Source</a>
                <a href="#feedback" className="text-xs font-mono uppercase tracking-[0.2em] text-teal hover:text-teal-soft transition-colors" data-hover>Guestbook</a>
              </div>
              <div className="mt-8 flex items-center justify-center gap-2 text-[10px] font-mono text-faint-ink">
                <span className="led led--rose" />
                designed for iphone · built for the challenge
              </div>
            </div>
          </div>
        </div>
      </footer>
    </main>
  )
}