import Foundation

// MARK: - Tone

enum RoastTone: String, CaseIterable, Identifiable {
    case roast
    case wholesome
    case stoic

    var id: String { rawValue }

    var label: String {
        switch self {
        case .roast: return "Roast"
        case .wholesome: return "Wholesome"
        case .stoic: return "Stoic"
        }
    }

    var icon: String {
        switch self {
        case .roast: return "flame.fill"
        case .wholesome: return "heart.fill"
        case .stoic: return "banknote.fill"
        }
    }
}

// MARK: - Output

struct RoastOutput {
    let headline: String
    let detail: String
    let closing: String
    let icon: String
}

// MARK: - Seeded RNG (deterministic per take)

struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    init(seed: Int) {
        state = UInt64(truncatingIfNeeded: seed)
        if state == 0 { state = 0x9E3779B97F4A7C15 }
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

private struct Picker {
    var rng: SeededGenerator

    mutating func one<T>(_ array: [T]) -> T {
        array[Int.random(in: 0..<array.count, using: &rng)]
    }
}

// MARK: - Sass Engine

enum SassEngine {
    static func generate(
        people: [Person],
        expenses: [Expense],
        settlements: [Settlement],
        currency: Currency,
        tone: RoastTone,
        seed: Int
    ) -> RoastOutput {
        var picker = Picker(rng: SeededGenerator(seed: seed))

        let total = expenses.reduce(0.0) { $0 + $1.amount }
        let avg = people.isEmpty ? 0 : total / Double(people.count)
        let count = people.count

        let money: (Double) -> String = { amount in
            let rounded = (amount * 100).rounded() / 100
            let text = rounded.rounded() == rounded
                ? String(Int(rounded))
                : String(format: "%.2f", rounded)
            return currency.symbol + text
        }

        func spent(_ id: UUID) -> Double {
            expenses.filter { $0.payerID == id }.reduce(0) { $0 + $1.amount }
        }

        var biggest: Person?
        var biggestPaid: Double = 0
        for person in people {
            let amount = spent(person.id)
            if amount > biggestPaid {
                biggestPaid = amount
                biggest = person
            }
        }

        let zeroPayers = people.filter { spent($0.id) < 0.005 }
        let zeroNames = zeroPayers.map(\.name)
        let zeroList = ListFormatter.localizedString(byJoining: zeroNames)

        let pending = settlements.filter { !$0.isPaid }
        let owesAmount = pending.reduce(0.0) { $0 + $1.amount }
        let pendingCount = pending.count
        let allSettled = !settlements.isEmpty && pending.isEmpty

        var debtorTotals: [UUID: Double] = [:]
        for settlement in pending {
            debtorTotals[settlement.fromID, default: 0] += settlement.amount
        }
        let mostIndebted = debtorTotals.max { $0.value < $1.value }

        let plural = pendingCount == 1 ? "payment" : "payments"

        // ---- Phases ----

        if people.isEmpty {
            return emptySquad(tone: tone, picker: &picker)
        }

        if expenses.isEmpty {
            return emptyTab(tone: tone, picker: &picker, count: count, money: money)
        }

        if settlements.isEmpty {
            return timeToSettle(
                tone: tone,
                picker: &picker,
                biggest: biggest,
                biggestPaid: biggestPaid,
                zeroList: zeroList,
                total: total,
                avg: avg,
                money: money
            )
        }

        if allSettled {
            return peaceRestored(
                tone: tone,
                picker: &picker,
                total: total,
                count: count,
                biggest: biggest,
                biggestPaid: biggestPaid,
                zeroCount: zeroPayers.count,
                money: money
            )
        }

        return stillChasing(
            tone: tone,
            picker: &picker,
            owesAmount: owesAmount,
            pendingCount: pendingCount,
            plural: plural,
            mostIndebted: mostIndebted,
            money: money,
            name: { id in people.first { $0.id == id }?.name ?? "Someone" }
        )
    }

    // MARK: - Phase: No people

    private static func emptySquad(tone: RoastTone, picker: inout Picker) -> RoastOutput {
        let bank: [RoastOutput]
        switch tone {
        case .roast:
            bank = [
                RoastOutput(
                    headline: "An empty squad.",
                    detail: "No friends. No bills. No drama. Peak emotional efficiency.",
                    closing: "Add at least two legends and a bill to break the streak.",
                    icon: "person.2.slash.fill"
                ),
                RoastOutput(
                    headline: "The void is split evenly between no one.",
                    detail: "Nothing to calculate, nothing to argue about.",
                    closing: "A squad of zero owes nothing to nobody. Technically perfect.",
                    icon: "person.2.slash.fill"
                )
            ]
        case .wholesome:
            bank = [
                RoastOutput(
                    headline: "Every squad starts with one name.",
                    detail: "Add your people and the good math begins.",
                    closing: "Great splits are built one friend at a time.",
                    icon: "person.2.fill"
                ),
                RoastOutput(
                    headline: "A blank slate full of possibility.",
                    detail: "Whoever you add next is the future of this ledger.",
                    closing: "Friendship first. Figures after.",
                    icon: "person.2.fill"
                )
            ]
        case .stoic:
            bank = [
                RoastOutput(
                    headline: "Ledger: empty.",
                    detail: "No parties, no entries, no disputes.",
                    closing: "A balanced life begins with an empty account.",
                    icon: "person.2.slash.fill"
                ),
                RoastOutput(
                    headline: "No members on file.",
                    detail: "Reconciliation is trivial when nobody exists.",
                    closing: "Awaiting participants.",
                    icon: "person.2.slash.fill"
                )
            ]
        }
        return picker.one(bank)
    }

    // MARK: - Phase: People but no expenses

    private static func emptyTab(tone: RoastTone, picker: inout Picker, count: Int, money: (Double) -> String) -> RoastOutput {
        let bank: [RoastOutput]
        switch tone {
        case .roast:
            bank = [
                RoastOutput(
                    headline: "The squad is ready. The bill is not.",
                    detail: "\(count) people, \(money(0)) spent. Either you stayed home or tonight was a total blackout.",
                    closing: "Add an expense before the roast loses its material.",
                    icon: "tray.fill"
                ),
                RoastOutput(
                    headline: "A group outing with zero expenses?",
                    detail: "Suspiciously frugal for a friend group with your history.",
                    closing: "Go out. Buy something. Return with receipts.",
                    icon: "tray.fill"
                )
            ]
        case .wholesome:
            bank = [
                RoastOutput(
                    headline: "A clean slate.",
                    detail: "\(count) friends, nothing owed yet. Enjoy the peace.",
                    closing: "Every great story starts with a first purchase.",
                    icon: "sparkles"
                ),
                RoastOutput(
                    headline: "Zero pressure, zero math.",
                    detail: "Your group has already won the night by showing up.",
                    closing: "Whenever you're ready, the calculator is warm.",
                    icon: "sparkles"
                )
            ]
        case .stoic:
            bank = [
                RoastOutput(
                    headline: "No transactions recorded.",
                    detail: "\(count) participants, \(money(0)) total. The ledger is calm.",
                    closing: "Add entries to begin reconciliation.",
                    icon: "list.clipboard.fill"
                ),
                RoastOutput(
                    headline: "Ledger: open, unfunded.",
                    detail: "Awaiting first debit before projections can run.",
                    closing: "Record your first expense to proceed.",
                    icon: "list.clipboard.fill"
                )
            ]
        }
        return picker.one(bank)
    }

    // MARK: - Phase: Expenses but not settled

    private static func timeToSettle(
        tone: RoastTone,
        picker: inout Picker,
        biggest: Person?,
        biggestPaid: Double,
        zeroList: String,
        total: Double,
        avg: Double,
        money: (Double) -> String
    ) -> RoastOutput {
        let heroName = biggest?.name ?? "No one"
        let heroLine = biggest.map { _ in "\(heroName) fronted \(money(biggestPaid)) of the \(money(total)) tab." } ?? "No one paid a single unit. Impressive restraint."

        let bank: [RoastOutput]
        switch tone {
        case .roast:
            bank = [
                RoastOutput(
                    headline: "\(heroName) carried the whole squad.",
                    detail: heroLine + (zeroList.isEmpty ? "" : " Meanwhile, \(zeroList) paid a combined \(money(0)). Statistically, a phantom.")
                        + " The rest of you owe a lifetime of \'same time next week\'.",
                    closing: "Hit Settle Up. The math is about to get personal.",
                    icon: "creditcard.fill"
                ),
                RoastOutput(
                    headline: "Someone paid \(money(biggestPaid)).",
                    detail: "It was \(heroName). It was not the group chat.",
                    closing: "Settle Up, before the hero develops a hero complex.",
                    icon: "creditcard.fill"
                )
            ]
        case .wholesome:
            bank = [
                RoastOutput(
                    headline: "\(heroName) is the group's hero tonight.",
                    detail: heroLine + " Give them the first slice of whatever comes next.",
                    closing: "Settle Up will sort the rest. Everyone chips in, nobody stresses.",
                    icon: "heart.fill"
                ),
                RoastOutput(
                    headline: "One generous soul, zero complaints.",
                    detail: "\(heroName) put \(money(biggestPaid)) on the line so the night could happen.",
                    closing: "A fair split keeps the friendship and the fandom intact.",
                    icon: "heart.fill"
                )
            ]
        case .stoic:
            bank = [
                RoastOutput(
                    headline: "Outlay: \(money(total)).",
                    detail: "Contribution is uneven. \(heroName) bears \(money(biggestPaid)). Average liability per member: \(money(avg)).",
                    closing: "Run settlement to equalize the burden.",
                    icon: "chart.bar.fill"
                ),
                RoastOutput(
                    headline: "Distribution pending.",
                    detail: "\(money(total)) across the group, concentrated in one wallet.",
                    closing: "Settlement will redistribute the balance fairly.",
                    icon: "chart.bar.fill"
                )
            ]
        }
        return picker.one(bank)
    }

    // MARK: - Phase: Some payments pending

    private static func stillChasing(
        tone: RoastTone,
        picker: inout Picker,
        owesAmount: Double,
        pendingCount: Int,
        plural: String,
        mostIndebted: (key: UUID, value: Double)?,
        money: (Double) -> String,
        name: (UUID) -> String
    ) -> RoastOutput {
        let debtorName = mostIndebted.map { name($0.key) } ?? "Someone"

        let bank: [RoastOutput]
        switch tone {
        case .roast:
            bank = [
                RoastOutput(
                    headline: "\(money(owesAmount)) is still on the table.",
                    detail: "\(pendingCount) \(plural) pending. Somewhere out there, \(debtorName) is feeling very, very busy.",
                    closing: "Hit Mark Paid as the cash lands. Or send this to the group chat as a gentle threat.",
                    icon: "timer"
                ),
                RoastOutput(
                    headline: "The invoice has been sent. The invoice has been ignored.",
                    detail: "\(pendingCount) \(plural) outstanding. The interest here is purely emotional.",
                    closing: "Nudge, screenshot, then nudge again. You know the drill.",
                    icon: "timer"
                )
            ]
        case .wholesome:
            bank = [
                RoastOutput(
                    headline: "Almost there — \(money(owesAmount)) to go.",
                    detail: "\(pendingCount) \(plural) waiting. Your friends aren't avoiding you, they're just directionally challenged.",
                    closing: "A gentle nudge closes the loop. You've got this.",
                    icon: "hand.thumbsup.fill"
                ),
                RoastOutput(
                    headline: "The finish line is visible.",
                    detail: "\(pendingCount) \(plural) left. Every one you mark paid is one less thing to think about.",
                    closing: "Celebrate the small wins. Then celebrate the big one.",
                    icon: "hand.thumbsup.fill"
                )
            ]
        case .stoic:
            bank = [
                RoastOutput(
                    headline: "Outstanding balance: \(money(owesAmount)).",
                    detail: "\(pendingCount) \(plural) remain unreconciled.",
                    closing: "Settlement completes upon payment confirmation.",
                    icon: "doc.text.magnifyingglass"
                ),
                RoastOutput(
                    headline: "Reconciliation in progress.",
                    detail: "\(pendingCount) \(plural) pending final clearance.",
                    closing: "Confirm receipts to close the books.",
                    icon: "doc.text.magnifyingglass"
                )
            ]
        }
        return picker.one(bank)
    }

    // MARK: - Phase: Everything settled

    private static func peaceRestored(
        tone: RoastTone,
        picker: inout Picker,
        total: Double,
        count: Int,
        biggest: Person?,
        biggestPaid: Double,
        zeroCount: Int,
        money: (Double) -> String
    ) -> RoastOutput {
        let heroName = biggest?.name ?? "Everyone"
        let zeroNote = zeroCount == 0 ? "" : " (\(zeroCount) of you paid nothing and you know who you are)"

        let bank: [RoastOutput]
        switch tone {
        case .roast:
            bank = [
                RoastOutput(
                    headline: "The books are balanced. Checkmate.",
                    detail: "\(money(total)) split across \(count) people. \(heroName) may or may not forgive you for the \(zeroNote).",
                    closing: "Friendship intact. Rent due next month.",
                    icon: "checkmark.seal.fill"
                ),
                RoastOutput(
                    headline: "Everyone paid up. The bro code thanks you.",
                    detail: "\(money(total)) moved between \(count) wallets with only minor emotional damage.",
                    closing: "Now spend the extra cash on another round.",
                    icon: "checkmark.seal.fill"
                )
            ]
        case .wholesome:
            bank = [
                RoastOutput(
                    headline: "All settled. Zero drama.",
                    detail: "\(money(total)) between \(count) friends, fully squared. That's how friendship survives money.",
                    closing: "Now go spend the extra cash on another round.",
                    icon: "sparkles"
                ),
                RoastOutput(
                    headline: "Peace restored.",
                    detail: "Every rupee accounted for, every friendship intact.",
                    closing: "Best group chat in the world just got richer.",
                    icon: "sparkles"
                )
            ]
        case .stoic:
            bank = [
                RoastOutput(
                    headline: "Reconciliation complete.",
                    detail: "\(money(total)) distributed across \(count) participants. Zero outstanding liabilities.",
                    closing: "Accounts closed. Efficiency achieved.",
                    icon: "checkmark.seal.fill"
                ),
                RoastOutput(
                    headline: "Ledger balanced.",
                    detail: "All transfers confirmed. No open positions.",
                    closing: "The group is solvent again.",
                    icon: "checkmark.seal.fill"
                )
            ]
        }
        return picker.one(bank)
    }
}