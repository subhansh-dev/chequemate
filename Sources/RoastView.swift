import SwiftUI

// MARK: - Roast Tab — Editorial Poster

struct RoastView: View {
    @EnvironmentObject var store: ChequeMateStore
    @State private var tone: RoastTone = .roast
    @State private var output: RoastOutput?
    @State private var isThinking = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    topStrip
                    tonePicker
                    if isThinking { thinkingPoster }
                    else if let output { roastPoster(output) }
                    else { placeholderPoster }
                    if output != nil && !isThinking {
                        GlassButton(title: "Another take", icon: "arrow.clockwise", variant: .secondary) { regenerate() }
                    }
                    BarcodeStrip().padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 36)
            }
            .navigationTitle("The Roast")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { if output == nil { think() } }
        .onChange(of: store.people) { regenerate() }
        .onChange(of: store.expenses) { regenerate() }
        .onChange(of: store.settlements) { regenerate() }
        .onChange(of: store.currency) { regenerate() }
    }

    private var topStrip: some View {
        HStack(spacing: 6) {
            Text("©2023").font(.system(size: 9, weight: .black, design: .monospaced)).foregroundStyle(ChequeWave.ink)
            Rectangle().fill(ChequeWave.ink.opacity(0.15)).frame(height: 0.7)
            Text("TYPOGRAPHY. — SOMETHING WEIRD").font(.system(size: 9, weight: .black, design: .monospaced)).tracking(0.8).foregroundStyle(ChequeWave.ink)
            Spacer()
            Text("03 — ROAST").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(ChequeWave.inkFaint)
        }.padding(.vertical, 6)
    }

    private var tonePicker: some View {
        HStack(spacing: 6) {
            ForEach(RoastTone.allCases) { t in
                let selected = tone == t
                let color: Color = { switch t { case .roast: return ChequeWave.magenta; case .wholesome: return ChequeWave.positive; case .stoic: return ChequeWave.blueprint } }()
                Button {
                    guard !isThinking else { return }
                    Haptics.tap()
                    withAnimation(.spring(response: 0.3)) { tone = t }
                    regenerate()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: t.icon).font(.system(size: 10, weight: .black))
                        Text(t.label.uppercased()).font(.system(size: 10, weight: .black, design: .monospaced))
                    }
                    .foregroundStyle(selected ? .white : ChequeWave.ink)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background {
                        if selected { Rectangle().fill(color) } else { Rectangle().fill(Color.white) }
                    }
                    .overlay { Rectangle().strokeBorder(selected ? ChequeWave.ink : Color.black.opacity(0.12), lineWidth: 1) }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var thinkingPoster: some View {
        PosterCard {
            VStack(spacing: 10) {
                ZStack {
                    Rectangle().fill(ChequeWave.paperDeep).frame(width: 56, height: 56)
                        .overlay { Rectangle().strokeBorder(ChequeWave.ink, lineWidth: 1) }
                    ProgressView().tint(ChequeWave.blueprint).scaleEffect(1.1)
                }
                Text("READING THE RECEIPTS…").font(.system(size: 11, weight: .black, design: .monospaced)).tracking(1).foregroundStyle(ChequeWave.ink)
                Text("Halftone printer is warming up.").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(ChequeWave.inkSoft)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
        }
    }

    private func roastPoster(_ roast: RoastOutput) -> some View {
        let toneColor: Color = { switch tone { case .roast: return ChequeWave.magenta; case .wholesome: return ChequeWave.positive; case .stoic: return ChequeWave.blueprint } }()
        let kanji: String = { switch tone { case .roast: return "炎上"; case .wholesome: return "優しさ"; case .stoic: return "沈着" } }()
        return ZStack(alignment: .topTrailing) {
            // halftone wash
            HalftoneDots(color: toneColor.opacity(0.07)).clipShape(Rectangle()).allowsHitTesting(false)
            VStack(alignment: .leading, spacing: 0) {
                // magenta/blue block like image 2
                HStack(spacing: 0) {
                    Rectangle().fill(toneColor).frame(height: 28)
                        .overlay {
                            HStack {
                                Text(tone.label.uppercased() + " — " + kanji).font(.system(size: 10, weight: .black, design: .monospaced)).tracking(1).foregroundStyle(.white)
                                Spacer()
                                Text("CHEQUEMATE SAYS").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(.white.opacity(0.9))
                            }.padding(.horizontal, 10)
                        }
                    Rectangle().fill(ChequeWave.ink).frame(width: 10, height: 28)
                }
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Rectangle().fill(toneColor).frame(width: 32, height: 32)
                            .overlay { Image(systemName: roast.icon).font(.system(size: 14, weight: .black)).foregroundStyle(.white) }
                            .overlay { Rectangle().strokeBorder(ChequeWave.ink, lineWidth: 1) }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("NO. 01 — EDITORIAL").font(.system(size: 9, weight: .black, design: .monospaced)).foregroundStyle(toneColor)
                            Text("初音ミク ID は ム式コードネーム").font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(ChequeWave.inkFaint).lineLimit(1)
                        }
                        Spacer()
                        Text(kanji).font(.system(size: 18, weight: .black, design: .rounded)).foregroundStyle(ChequeWave.ink.opacity(0.12))
                    }
                    Text(roast.headline).font(.system(size: 20, weight: .black, design: .rounded)).tracking(-0.3).foregroundStyle(ChequeWave.ink).fixedSize(horizontal: false, vertical: true)
                    Rectangle().fill(toneColor.opacity(0.9)).frame(height: 2.5)
                    Text(roast.detail).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(ChequeWave.inkSoft).fixedSize(horizontal: false, vertical: true)
                    Rule(color: ChequeWave.ink.opacity(0.12))
                    HStack(alignment: .top, spacing: 8) {
                        Text("“").font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(toneColor).offset(y: -2)
                        Text(roast.closing).font(.system(size: 13, weight: .bold, design: .rounded)).italic().foregroundStyle(ChequeWave.ink).fixedSize(horizontal: false, vertical: true)
                    }
                    HStack(spacing: 4) {
                        Rectangle().fill(toneColor).frame(width: 24, height: 3)
                        Rectangle().fill(ChequeWave.ink).frame(width: 8, height: 3)
                        Rectangle().fill(ChequeWave.paperDeep).frame(width: 24, height: 3).overlay { Rectangle().strokeBorder(ChequeWave.ink.opacity(0.12), lineWidth: 0.6) }
                        Spacer()
                        Text("08/05/ made with love").font(.system(size: 7, weight: .bold, design: .monospaced)).foregroundStyle(ChequeWave.inkFaint)
                    }
                }
                .padding(16)
            }
        }
        .background { Rectangle().fill(Color.white) }
        .clipShape(Rectangle())
        .overlay { Rectangle().strokeBorder(ChequeWave.ink, lineWidth: 1.4) }
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        .transition(.scale.combined(with: .opacity))
    }

    private var placeholderPoster: some View {
        PosterCard {
            VStack(spacing: 10) {
                ZStack {
                    Rectangle().fill(ChequeWave.magenta.opacity(0.08)).frame(width: 64, height: 64)
                        .overlay { Rectangle().strokeBorder(ChequeWave.magenta, lineWidth: 1.2) }
                    HalftoneDots(color: ChequeWave.magenta.opacity(0.10)).frame(width: 64, height: 64).clipShape(Rectangle())
                    Image(systemName: "flame.fill").font(.system(size: 20, weight: .black)).foregroundStyle(ChequeWave.magenta)
                }
                Text("POINT YOUR FRIENDS HERE.").font(.system(size: 13, weight: .black, design: .rounded)).tracking(0.6).foregroundStyle(ChequeWave.ink)
                Text("Add a squad and some expenses and the commentary writes itself — in blueprint ink.").font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(ChequeWave.inkSoft).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 8)
        }
    }

    private func regenerate() { think(seed: Int.random(in: 1...1_000_000)) }
    private func think(seed: Int = 1) {
        isThinking = true; output = nil
        Task {
            try? await Task.sleep(nanoseconds: 650_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.5)) {
                output = SassEngine.generate(people: store.people, expenses: store.expenses, settlements: store.settlements, currency: store.currency, tone: tone, seed: seed)
            }
            isThinking = false
        }
    }
}
