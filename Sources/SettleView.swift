import SwiftUI

// MARK: - Settle Tab — Poster

struct SettleView: View {
    @EnvironmentObject var store: ChequeMateStore
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    topStrip
                    if store.hasSettlements {
                        scoreboard
                        pendingPoster
                        if !store.settledSettlements.isEmpty { settledPoster }
                        if store.allSettled { allSettledPoster }
                    } else {
                        settlePoster
                    }
                    BarcodeStrip().padding(.top, 6)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 36)
            }
            .navigationTitle("Settle")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var topStrip: some View {
        HStack(spacing: 6) {
            Text("©2026").font(.system(size: 9, weight: .black, design: .monospaced)).foregroundStyle(ChequeWave.ink)
            Rectangle().fill(ChequeWave.ink.opacity(0.15)).frame(height: 0.7)
            Text("RECONCILIATION — WHO OWES WHOM").font(.system(size: 9, weight: .black, design: .monospaced)).tracking(1).foregroundStyle(ChequeWave.magenta)
            Spacer()
            Text("02 — SETTLE").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(ChequeWave.inkFaint)
        }.padding(.vertical, 6)
    }

    private var settlePoster: some View {
        PosterCard(accent: ChequeWave.blueprint) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Rectangle().fill(ChequeWave.blueprint).frame(width: 44, height: 44)
                        .overlay { Image(systemName: "arrow.left.arrow.right").font(.system(size: 16, weight: .black)).foregroundStyle(.white) }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TIME TO SETTLE").font(.system(size: 16, weight: .black, design: .rounded)).foregroundStyle(ChequeWave.ink)
                        Text("精算 — the math ends the debate.").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(ChequeWave.blueprint)
                    }
                    Spacer()
                    BigNumber(n: "02")
                }
                Rule(color: ChequeWave.blueprint.opacity(0.2))
                Text(store.canSettle ? "\(store.money(store.totalSpent)) across \(store.people.count) people. One tap, minimal transfers." : "Add at least two people and one expense to enable settlement.").font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(ChequeWave.inkSoft).multilineTextAlignment(.center)
                GlassButton(title: "Settle Up", icon: "wand.and.stars") {
                    Haptics.heavy()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { store.settleUp() }
                    Haptics.success()
                }.disabled(!store.canSettle).opacity(store.canSettle ? 1 : 0.4)
            }
        }
    }

    private var scoreboard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Balances", desc: "Ink black on paper. Blue gets back. Magenta pays.", icon: "chart.bar.fill", tint: ChequeWave.blueprint, number: "01")
            VStack(spacing: 8) { ForEach(store.balances.sorted { $0.net > $1.net }) { balanceRow($0) } }
        }
    }

    private func balanceRow(_ balance: Balance) -> some View {
        let gradient = ChequeWave.gradient(for: balance.person.tintIndex)
        let isOwed = balance.net >= 0
        return HStack(spacing: 10) {
            PersonAvatar(name: balance.person.name, gradient: gradient, size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(balance.person.name.uppercased()).font(.system(size: 12, weight: .black, design: .rounded)).tracking(0.4).foregroundStyle(ChequeWave.ink)
                Text("paid \(store.money(balance.paid)) · share \(store.money(balance.share))").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(ChequeWave.inkSoft)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(isOwed ? "+\(store.money(balance.net))" : store.money(balance.net)).font(.system(size: 12, weight: .black, design: .monospaced)).foregroundStyle(isOwed ? ChequeWave.positive : ChequeWave.negative)
                Text(isOwed ? "GETS BACK" : "OWES").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(ChequeWave.inkFaint)
            }
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background { Rectangle().fill(Color.white) }
            .overlay { Rectangle().strokeBorder(isOwed ? ChequeWave.positive : ChequeWave.negative, lineWidth: 1) }
        }
        .padding(10)
        .background { Rectangle().fill(Color.white) }
        .overlay { Rectangle().strokeBorder(ChequeWave.ink, lineWidth: 1.1) }
    }

    private var pendingPoster: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(title: "Open transfers", desc: store.pendingSettlements.isEmpty ? "All clear. Paper clean." : "Mark PAID once cash lands. Ink dries.", icon: "clock.fill", tint: ChequeWave.magenta, number: "02")
                Spacer()
                if !store.pendingSettlements.isEmpty { PastelPill(text: "\(store.pendingSettlements.count) pending", tint: ChequeWave.magenta) }
            }
            if store.pendingSettlements.isEmpty {
                PosterCard(accent: ChequeWave.mint) {
                    HStack(spacing: 8) {
                        Rectangle().fill(ChequeWave.positive).frame(width: 28, height: 28)
                            .overlay { Image(systemName: "checkmark").font(.system(size: 11, weight: .black)).foregroundStyle(.white) }
                        Text("NO PENDING PAYMENTS. TABLE IS CLEAN.").font(.system(size: 11, weight: .black, design: .monospaced)).foregroundStyle(ChequeWave.ink)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 8) { ForEach(store.pendingSettlements) { pendingRow($0) } }
            }
        }
    }

    private func pendingRow(_ s: Settlement) -> some View {
        let from = store.people.first { $0.id == s.fromID }
        let to = store.people.first { $0.id == s.toID }
        let fromGrad = from.map { ChequeWave.gradient(for: $0.tintIndex) } ?? ChequeWave.blueprintGradient
        let toGrad = to.map { ChequeWave.gradient(for: $0.tintIndex) } ?? ChequeWave.magentaGradient
        return HStack(spacing: 8) {
            HStack(spacing: -6) {
                PersonAvatar(name: from?.name ?? "?", gradient: fromGrad, size: 26)
                PersonAvatar(name: to?.name ?? "?", gradient: toGrad, size: 26).overlay { Circle().strokeBorder(.white, lineWidth: 1.2) }
            }
            Rectangle().fill(ChequeWave.ink).frame(width: 12, height: 1.2)
            Image(systemName: "arrow.right").font(.system(size: 8, weight: .black)).foregroundStyle(ChequeWave.ink)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(store.personName(s.fromID)) → \(store.personName(s.toID))").font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(ChequeWave.ink)
                Text(store.money(s.amount)).font(.system(size: 11, weight: .black, design: .monospaced)).foregroundStyle(ChequeWave.blueprint)
            }
            Spacer()
            Button {
                Haptics.success()
                withAnimation(.spring(response: 0.4)) { store.markPaid(s.id) }
            } label: {
                Text("PAID").font(.system(size: 10, weight: .black, design: .monospaced)).foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background { Rectangle().fill(ChequeWave.positive) }
                    .overlay { Rectangle().strokeBorder(ChequeWave.ink, lineWidth: 1) }
            }
        }
        .padding(10)
        .background { Rectangle().fill(Color.white) }
        .overlay { Rectangle().strokeBorder(ChequeWave.ink, lineWidth: 1.1) }
    }

    private var settledPoster: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Settled", desc: "Already cleared — halftone faded.", icon: "checkmark.seal.fill", tint: ChequeWave.positive, number: "03")
            VStack(spacing: 8) {
                ForEach(store.settledSettlements) { s in
                    HStack(spacing: 8) {
                        Rectangle().fill(ChequeWave.positive.opacity(0.15)).frame(width: 24, height: 24)
                            .overlay { Image(systemName: "checkmark").font(.system(size: 10, weight: .black)).foregroundStyle(ChequeWave.positive) }
                        Text("\(store.personName(s.fromID)) → \(store.personName(s.toID))").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(ChequeWave.inkSoft)
                        Spacer()
                        Text(store.money(s.amount)).font(.system(size: 10, weight: .black, design: .monospaced)).foregroundStyle(ChequeWave.inkFaint)
                    }
                    .padding(10)
                    .background { Rectangle().fill(Color.white.opacity(0.6)) }
                    .overlay { Rectangle().strokeBorder(Color.black.opacity(0.08), lineWidth: 0.8) }
                    .opacity(0.75)
                }
            }
        }
    }

    private var allSettledPoster: some View {
        GradientCard(gradient: ChequeWave.blueprintGradient) {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Rectangle().fill(Color.white).frame(width: 36, height: 36)
                        .overlay { Image(systemName: "party.popper.fill").font(.system(size: 16, weight: .black)).foregroundStyle(ChequeWave.blueprint) }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("CHECKMATE.").font(.system(size: 16, weight: .black, design: .rounded)).foregroundStyle(.white)
                        Text("EVERYONE'S SETTLED — 富士山 2021").font(.system(size: 9, weight: .black, design: .monospaced)).foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                    Text("完").font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(.white.opacity(0.9))
                }
                Rule(color: .white.opacity(0.25))
                Text("The books are closed. Friendships survived the paper.").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.9)).multilineTextAlignment(.center)
                Button {
                    Haptics.tap(); store.selectedTab = 2
                } label: {
                    HStack(spacing: 6) { Image(systemName: "flame.fill").font(.system(size: 11, weight: .black)); Text("GET THE FINAL ROAST").font(.system(size: 11, weight: .black, design: .monospaced)) }
                    .foregroundStyle(ChequeWave.blueprintDeep).padding(.horizontal, 14).padding(.vertical, 8)
                    .background { Rectangle().fill(Color.white) }.overlay { Rectangle().strokeBorder(ChequeWave.ink, lineWidth: 1) }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
