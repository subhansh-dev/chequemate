import SwiftUI
import UIKit

// MARK: - App Entry

@main
struct ChequeMateApp: App {
    @StateObject private var store = ChequeMateStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
        }
    }
}

// MARK: - Haptics

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Store

@MainActor
final class ChequeMateStore: ObservableObject {
    @Published var people: [Person] = []
    @Published var expenses: [Expense] = []
    @Published var settlements: [Settlement] = []
    @Published var currency: Currency = .inr
    @Published var selectedTab: Int = 0

    private let saveKey = "chequemate.state.v1"

    private let palette: [Color] = [
        ChequeWave.peach, ChequeWave.mint, ChequeWave.coral, ChequeWave.blush, ChequeWave.sand
    ]

    init() {
        load()
    }

    var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var perHead: Double {
        people.isEmpty ? 0 : totalSpent / Double(people.count)
    }

    var balances: [Balance] {
        SettlementEngine.balances(people: people, expenses: expenses)
    }

    var pendingSettlements: [Settlement] {
        settlements.filter { !$0.isPaid }
    }

    var settledSettlements: [Settlement] {
        settlements.filter { $0.isPaid }
    }

    var hasSettlements: Bool {
        !settlements.isEmpty
    }

    var allSettled: Bool {
        !settlements.isEmpty && pendingSettlements.isEmpty
    }

    var canSettle: Bool {
        people.count >= 2 && !expenses.isEmpty
    }

    func tint(for person: Person) -> Color {
        palette[person.tintIndex % palette.count]
    }

    func personName(_ id: UUID) -> String {
        people.first { $0.id == id }?.name ?? "Someone"
    }

    func money(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = currency.locale
        formatter.currencySymbol = currency.symbol
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency.symbol)0"
    }

    func addPerson(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !people.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        people.append(Person(name: trimmed, tintIndex: people.count % palette.count))
        invalidateSettlements()
        save()
    }

    func removePerson(_ id: UUID) {
        people.removeAll { $0.id == id }
        expenses.removeAll { $0.payerID == id }
        invalidateSettlements()
        save()
    }

    func addExpense(payerID: UUID, amount: Double, note: String) {
        guard amount > 0 else { return }
        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        expenses.append(Expense(
            payerID: payerID,
            amount: amount,
            note: cleanNote.isEmpty ? "the bill" : cleanNote
        ))
        invalidateSettlements()
        save()
    }

    func removeExpense(_ id: UUID) {
        expenses.removeAll { $0.id == id }
        invalidateSettlements()
        save()
    }

    func settleUp() {
        guard canSettle else { return }
        settlements = SettlementEngine.minimalSettlements(people: people, expenses: expenses)
        save()
    }

    func markPaid(_ id: UUID) {
        guard let index = settlements.firstIndex(where: { $0.id == id }) else { return }
        settlements[index].isPaid = true
        save()
    }

    func loadExample() {
        people = [
            Person(name: "Aarav", tintIndex: 0),
            Person(name: "Diya", tintIndex: 1),
            Person(name: "Rohan", tintIndex: 2),
            Person(name: "Sara", tintIndex: 3)
        ]
        expenses = [
            Expense(payerID: people[0].id, amount: 1240, note: "Dinner"),
            Expense(payerID: people[1].id, amount: 350, note: "Popcorn"),
            Expense(payerID: people[2].id, amount: 480, note: "Movie tickets"),
            Expense(payerID: people[0].id, amount: 200, note: "Chai run")
        ]
        invalidateSettlements()
        save()
    }

    func clearAll() {
        people = []
        expenses = []
        settlements = []
        save()
    }

    private func invalidateSettlements() {
        if !settlements.isEmpty {
            settlements = []
        }
    }

    // MARK: - Persistence

    private struct SavedState: Codable {
        var people: [Person]
        var expenses: [Expense]
        var settlements: [Settlement]
        var currency: Currency
    }

    private func save() {
        let state = SavedState(
            people: people,
            expenses: expenses,
            settlements: settlements,
            currency: currency
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let state = try? JSONDecoder().decode(SavedState.self, from: data) else { return }
        people = state.people
        expenses = state.expenses
        settlements = state.settlements
        currency = state.currency
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var store: ChequeMateStore

    var body: some View {
        ZStack {
            MeshBackground()
            TabView(selection: $store.selectedTab) {
                SquadView()
                    .tabItem { Label("Squad", systemImage: "person.3.fill") }
                    .tag(0)
                SettleView()
                    .tabItem { Label("Settle", systemImage: "banknote.fill") }
                    .tag(1)
                RoastView()
                    .tabItem { Label("Roast", systemImage: "flame.fill") }
                    .tag(2)
            }
            .tint(ChequeWave.peach)
        }
    }
}