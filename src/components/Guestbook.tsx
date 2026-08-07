"use client"

import { useCallback, useEffect, useState } from "react"
import { Star, Send, RefreshCw, PenLine } from "lucide-react"
import { useToast } from "@/hooks/use-toast"

type FeedbackItem = {
  id: string
  name: string
  role: string | null
  message: string
  rating: number | null
  createdAt: string
}

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

function formatDate(iso: string) {
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return ""
  const day = d.getDate().toString().padStart(2, "0")
  return `${MONTHS[d.getMonth()]} ${day}, ${d.getFullYear()}`
}

function Stars({ value, onPick, size = "md" }: { value: number; onPick?: (v: number) => void; size?: "md" | "sm" }) {
  const dim = size === "sm" ? "w-3.5 h-3.5" : "w-6 h-6"
  return (
    <div className="flex items-center gap-1">
      {[1, 2, 3, 4, 5].map((n) => (
        <button
          key={n}
          type="button"
          disabled={!onPick}
          onClick={() => onPick?.(n)}
          aria-label={`${n} out of 5 stars`}
          className={onPick ? "cursor-pointer transition-transform hover:scale-125" : "cursor-default"}
        >
          <Star
            className={`${dim} ${value >= n ? "text-teal fill-teal" : "text-white/15"}`}
            style={value >= n ? { filter: "drop-shadow(0 0 6px rgba(212,168,83,0.5))" } : undefined}
          />
        </button>
      ))}
    </div>
  )
}

export function Guestbook() {
  const { toast } = useToast()
  const [items, setItems] = useState<FeedbackItem[]>([])
  const [loading, setLoading] = useState(true)
  const [sending, setSending] = useState(false)
  const [name, setName] = useState("")
  const [role, setRole] = useState("")
  const [message, setMessage] = useState("")
  const [rating, setRating] = useState(0)

  const load = useCallback(async () => {
    try {
      const res = await fetch("/api/feedback", { cache: "no-store" })
      const data = (await res.json()) as { items?: FeedbackItem[] }
      setItems(data.items ?? [])
    } catch {
      setItems([])
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- state updates only after async fetch resolves
    void load()
  }, [load])

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    const cleanName = name.trim()
    const cleanMsg = message.trim()
    if (!cleanMsg || cleanMsg.length < 3) {
      toast({ title: "Add a few more words", description: "Share at least three words of feedback.", variant: "destructive" })
      return
    }
    if (!cleanName) {
      toast({ title: "Who's leaving this?", description: "Add your name so we know who to thank.", variant: "destructive" })
      return
    }
    setSending(true)
    try {
      const res = await fetch("/api/feedback", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: cleanName, role: role.trim() || null, message: cleanMsg, rating: rating || null }),
      })
      const data = (await res.json()) as { item?: FeedbackItem; error?: string }
      if (!res.ok || !data.item) {
        toast({ title: "Couldn't save your note", description: data.error ?? "Something went wrong.", variant: "destructive" })
        return
      }
      setItems((prev) => [data.item as FeedbackItem, ...prev])
      setName("")
      setRole("")
      setMessage("")
      setRating(0)
      toast({ title: "Note received", description: "Thanks — every voice shapes the experience." })
    } catch {
      toast({ title: "Network error", description: "The request failed. Give it another shot.", variant: "destructive" })
    } finally {
      setSending(false)
    }
  }

  return (
    <div className="glass glass--shine p-6 sm:p-8" data-spec>
      <div className="relative z-[2] grid lg:grid-cols-2 gap-8">
        {/* ── Form ── */}
        <form onSubmit={(e) => void submit(e)} className="flex flex-col gap-5">
          <div className="flex items-center gap-4">
            <div className="chip w-12 h-12 p-3 text-teal">
              <PenLine className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-ink">Leave a note</h3>
              <p className="text-sm text-muted-ink">Tell the makers what Huewaves felt like.</p>
            </div>
          </div>

          <div className="grid sm:grid-cols-2 gap-3">
            <label className="block">
              <span className="mb-1.5 block text-xs font-mono uppercase tracking-[0.18em] text-faint-ink">Name</span>
              <input
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Ada Lovelace"
                maxLength={40}
                className="w-full rounded-xl border border-white/12 bg-white/[0.04] px-4 py-3 text-sm text-ink placeholder:text-white/25 outline-none focus:border-teal/50 focus:bg-white/[0.06] transition-colors"
              />
            </label>
            <label className="block">
              <span className="mb-1.5 block text-xs font-mono uppercase tracking-[0.18em] text-faint-ink">Role / title</span>
              <input
                value={role}
                onChange={(e) => setRole(e.target.value)}
                placeholder="Judge · developer · curious"
                maxLength={40}
                className="w-full rounded-xl border border-white/12 bg-white/[0.04] px-4 py-3 text-sm text-ink placeholder:text-white/25 outline-none focus:border-teal/50 focus:bg-white/[0.06] transition-colors"
              />
            </label>
          </div>

          <label className="block">
            <span className="mb-1.5 block text-xs font-mono uppercase tracking-[0.18em] text-faint-ink">Note</span>
            <textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="I pointed the camera at something orange and…"
              rows={4}
              maxLength={600}
              className="w-full resize-none rounded-xl border border-white/12 bg-white/[0.04] px-4 py-3 text-sm text-ink placeholder:text-white/25 outline-none focus:border-teal/50 focus:bg-white/[0.06] transition-colors"
            />
          </label>

          <div className="flex items-center justify-between gap-4 flex-wrap">
            <div className="flex items-center gap-3">
              <span className="text-xs font-mono uppercase tracking-[0.18em] text-faint-ink">Rating</span>
              <Stars value={rating} onPick={setRating} />
            </div>
            <button type="submit" className="btn-spectral py-2.5! px-6! text-sm!" disabled={sending} data-hover>
              {sending ? <RefreshCw className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
              {sending ? "Sending…" : "Send note"}
            </button>
          </div>
        </form>

        {/* ── Recent notes ── */}
        <div className="flex flex-col gap-3 lg:pl-8 lg:border-l border-white/10">
          <div className="flex items-center justify-between">
            <span className="eyebrow">
              <span className="text-faint-ink">[notes]</span> Recent notes
            </span>
            {loading && <span className="text-[11px] font-mono text-faint-ink animate-pulse">loading…</span>}
          </div>

          {items.length === 0 && !loading ? (
            <div className="rounded-2xl border border-dashed border-white/10 px-5 py-10 text-center">
              <p className="text-sm text-muted-ink">No notes yet — the canvas is yours.</p>
              <p className="mt-1 text-xs text-faint-ink">Leave the first one above.</p>
            </div>
          ) : (
            <div className="space-y-3 overflow-y-auto max-h-[380px] pr-1">
              {items.map((item) => (
                <div key={item.id} className="tile !rounded-2xl p-4" data-hover>
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex items-center gap-2">
                      <div className="chip w-8 h-8 p-1.5 text-teal-soft">
                        <span className="text-xs font-bold font-mono">{item.name.slice(0, 1).toUpperCase()}</span>
                      </div>
                      <div>
                        <p className="text-sm font-semibold text-ink">{item.name}</p>
                        {item.role && <p className="text-[11px] text-faint-ink">{item.role}</p>}
                      </div>
                    </div>
                    <span className="text-[10px] font-mono text-faint-ink">{formatDate(item.createdAt)}</span>
                  </div>
                  <p className="mt-2 text-sm text-muted-ink leading-relaxed">{item.message}</p>
                  {item.rating != null && (
                    <div className="mt-2">
                      <Stars value={item.rating} size="sm" />
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}