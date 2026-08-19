import SwiftUI

// MARK: - Roast Tab

struct RoastView: View {
    @EnvironmentObject var store: ChequeMateStore

    @State private var tone: RoastTone = .roast
    @State private var output: RoastOutput?
    @State private var isThinking = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    tonePicker

                    if isThinking {
                        thinkingCard
                    } else if let output {
                        roastCard(output)
                    } else {
                        placeholderCard
                    }

                    if output != nil && !isThinking {
                        GlassButton(title: "Another take", icon: "arrow.clockwise", variant: .secondary) {
                            regenerate()
                        }
                    }

                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .navigationTitle("The Roast")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if output == nil {
                think()
            }
        }
        .onChange(of: store.people) { _ in regenerate() }
        .onChange(of: store.expenses) { _ in regenerate() }
        .onChange(of: store.settlements) { _ in regenerate() }
        .onChange(of: store.currency) { _ in regenerate() }
    }

    // MARK: - Tone picker

    private var tonePicker: some View {
        HStack(spacing: 8) {
            ForEach(RoastTone.allCases) { toneOption in
                let selected = tone == toneOption
                Button {
                    guard !isThinking else { return }
                    Haptics.tap()
                    withAnimation(.spring(response: 0.3)) {
                        tone = toneOption
                    }
                    regenerate()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: toneOption.icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(toneOption.label)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(selected ? .black.opacity(0.8) : ChequeWave.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background {
                        if selected { Capsule().fill(ChequeWave.peach) }
                    }
                    .glassEffect(.regular.tint(ChequeWave.peach.opacity(selected ? 0.4 : 0.1)), in: .capsule)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Thinking state

    private var thinkingCard: some View {
        GlassCard {
            VStack(spacing: 14) {
                ProgressView()
                    .tint(ChequeWave.peach)
                    .scaleEffect(1.2)
                Text("Reading the receiptsâ€¦")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(ChequeWave.inkSoft)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Roast card

    private func roastCard(_ roast: RoastOutput) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: roast.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(ChequeWave.peach)
                    Spacer()
                    Text("CHEQUEMATE SAYS")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.6)
                        .foregroundStyle(ChequeWave.inkFaint)
                }
                Text(roast.headline)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(ChequeWave.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(roast.detail)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(ChequeWave.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Divider()
                    .overlay(ChequeWave.ink.opacity(0.1))
                Text(roast.closing)
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .italic()
                    .foregroundStyle(ChequeWave.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Placeholder

    private var placeholderCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(ChequeWave.peach)
                VStack(spacing: 6) {
                    Text("Point your friends here.")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(ChequeWave.ink)
                    Text("Add a squad and some expenses and the commentary will write itself.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(ChequeWave.inkSoft)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ChequeWave.inkFaint)
            Text("Generated on-device. No data leaves your phone.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(ChequeWave.inkFaint)
        }
        .padding(.top, 8)
    }

    // MARK: - Generation

    private func regenerate() {
        think(seed: Int.random(in: 1...1_000_000))
    }

    private func think(seed: Int = 1) {
        isThinking = true
        output = nil
        Task {
            try? await Task.sleep(nanoseconds: 650_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.5)) {
                output = SassEngine.generate(
                    people: store.people,
                    expenses: store.expenses,
                    settlements: store.settlements,
                    currency: store.currency,
                    tone: tone,
                    seed: seed
                )
            }
            isThinking = false
        }
    }
}