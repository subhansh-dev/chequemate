import SwiftUI

// MARK: - Settle Tab

struct SettleView: View {
    @EnvironmentObject var store: ChequeMateStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    summaryHeader

                    if store.hasSettlements {
                        scoreboard
                        pendingSection
                        if !store.settledSettlements.isEmpty {
                            settledSection
                        }
                        if store.allSettled {
                            allSettledCard
                        }
                    } else {
                        settleUpCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .navigationTitle("Settle")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Summary

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("The scoreboard")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(ChequeWave.ink)
            Text(store.hasSettlements
                 ? "Who owes whom, at a glance."
                 : "Run the math and end the debate.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(ChequeWave.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    // MARK: - Settle up

    private var settleUpCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                Image(systemName: "banknote.fill")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(store.canSettle ? ChequeWave.peach : ChequeWave.inkFaint)
                VStack(spacing: 6) {
                    Text("Time to settle")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(ChequeWave.ink)
                    Text(store.canSettle
                         ? "\(store.money(store.totalSpent)) split across \(store.people.count) people."
                         : "Add at least two people and an expense to enable the math.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(ChequeWave.inkSoft)
                        .multilineTextAlignment(.center)
                }
                GlassButton(title: "Settle Up", icon: "checkerboard.shield") {
                    Haptics.heavy()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        store.settleUp()
                    }
                    Haptics.success()
                }
                .disabled(!store.canSettle)
                .opacity(store.canSettle ? 1 : 0.4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Scoreboard

    private var scoreboard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(index: "01", tag: "Balances", title: "Who's in the green", desc: "Green gets paid back. Coral pays up.")

            VStack(spacing: 10) {
                ForEach(store.balances.sorted { $0.net > $1.net }) { balance in
                    balanceRow(balance)
                }
            }
        }
    }

    private func balanceRow(_ balance: Balance) -> some View {
        let tint = store.tint(for: balance.person)
        let isOwed = balance.net >= 0

        return HStack(spacing: 14) {
            Circle()
                .fill(tint)
                .frame(width: 34, height: 34)
                .overlay {
                    Text(String((balance.person.name.first).map(String.init) ?? "?"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.7))
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(balance.person.name)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(ChequeWave.ink)
                Text("paid \(store.money(balance.paid)) Â· share \(store.money(balance.share))")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(ChequeWave.inkSoft)
            }
            Spacer()
            Text(isOwed ? "+\(store.money(balance.net))" : store.money(balance.net))
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .foregroundStyle(isOwed ? ChequeWave.mint : ChequeWave.coral)
        }
        .padding(14)
        .glassEffect(.regular.tint(tint.opacity(0.08)), in: .rect(cornerRadius: 18))
    }

    // MARK: - Pending (mode 2: who still has to pay)

    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                index: "02",
                tag: "Still to pay",
                title: "Open transfers",
                desc: store.pendingSettlements.isEmpty
                    ? "Everyone's cleared their dues."
                    : "Mark a transfer as paid once the cash lands."
            )

            if store.pendingSettlements.isEmpty {
                GlassCard {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(ChequeWave.mint)
                        Text("No pending payments. The table is clean.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(ChequeWave.ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(store.pendingSettlements) { settlement in
                        pendingRow(settlement)
                    }
                }
            }
        }
    }

    private func pendingRow(_ settlement: Settlement) -> some View {
        let fromTint = store.tint(for: store.people.first { $0.id == settlement.fromID } ?? Person(name: "?", tintIndex: 0))
        let toTint = store.tint(for: store.people.first { $0.id == settlement.toID } ?? Person(name: "?", tintIndex: 1))

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(fromTint)
                    .frame(width: 22, height: 22)
                Circle()
                    .fill(toTint)
                    .frame(width: 22, height: 22)
                    .offset(x: 14)
            }
            .frame(width: 40, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(store.personName(settlement.fromID)) â†’ \(store.personName(settlement.toID))")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(ChequeWave.ink)
                Text(store.money(settlement.amount))
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(ChequeWave.peach)
            }
            Spacer()
            Button {
                Haptics.success()
                withAnimation(.spring(response: 0.4)) {
                    store.markPaid(settlement.id)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                    Text("Mark Paid")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.black.opacity(0.8))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background {
                    Capsule().fill(ChequeWave.mint)
                }
            }
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    // MARK: - Settled

    private var settledSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(index: "03", tag: "Done", title: "Settled", desc: "Transfers that have already been cleared.")

            VStack(spacing: 10) {
                ForEach(store.settledSettlements) { settlement in
                    HStack(spacing: 14) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(ChequeWave.mint)
                        Text("\(store.personName(settlement.fromID)) paid \(store.personName(settlement.toID))")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(ChequeWave.inkSoft)
                        Spacer()
                        Text(store.money(settlement.amount))
                            .font(.system(.caption, design: .monospaced, weight: .bold))
                            .foregroundStyle(ChequeWave.inkFaint)
                    }
                    .padding(14)
                    .glassEffect(.regular, in: .rect(cornerRadius: 18))
                    .opacity(0.6)
                }
            }
        }
    }

    // MARK: - All settled

    private var allSettledCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                Image(systemName: "checkerboard.shield")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(ChequeWave.mint)
                VStack(spacing: 6) {
                    Text("Checkmate. Everyone's settled.")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(ChequeWave.ink)
                    Text("The books are closed. The friendships survived.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(ChequeWave.inkSoft)
                        .multilineTextAlignment(.center)
                }
                GlassButton(title: "Get the final roast", icon: "flame.fill", variant: .secondary) {
                    Haptics.tap()
                    store.selectedTab = 2
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .transition(.scale.combined(with: .opacity))
    }
}