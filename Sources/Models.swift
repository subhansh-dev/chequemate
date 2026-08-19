import Foundation

// MARK: - Currency

enum Currency: String, CaseIterable, Identifiable, Codable {
    case inr = "INR"
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .inr: return "₹"
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        }
    }

    var locale: Locale {
        switch self {
        case .inr: return Locale(identifier: "en_IN")
        default: return Locale(identifier: "en_US")
        }
    }

    var name: String {
        switch self {
        case .inr: return "Rupee"
        case .usd: return "Dollar"
        case .eur: return "Euro"
        case .gbp: return "Pound"
        }
    }
}

// MARK: - Models

struct Person: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var tintIndex: Int = 0
}

struct Expense: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var payerID: UUID
    var amount: Double
    var note: String
}

struct Balance: Identifiable {
    let id = UUID()
    let person: Person
    let paid: Double
    let share: Double

    // Positive = gets money back, negative = owes
    var net: Double { paid - share }
}

struct Settlement: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var fromID: UUID
    var toID: UUID
    var amount: Double
    var isPaid: Bool = false
}

// MARK: - Settlement Engine

enum SettlementEngine {
    static func balances(people: [Person], expenses: [Expense]) -> [Balance] {
        guard !people.isEmpty else { return [] }
        let total = expenses.reduce(0.0) { $0 + $1.amount }
        let share = total / Double(people.count)
        return people.map { person in
            let paid = expenses.filter { $0.payerID == person.id }.reduce(0.0) { $0 + $1.amount }
            return Balance(person: person, paid: paid, share: share)
        }
    }

    // Produces the fewest possible transfers so nobody pays the same person twice.
    static func minimalSettlements(people: [Person], expenses: [Expense]) -> [Settlement] {
        let balances = balances(people: people, expenses: expenses)

        var creditors = balances
            .filter { $0.net > 0.005 }
            .sorted { $0.net > $1.net }
            .map { (person: $0.person, amount: $0.net) }

        var debtors = balances
            .filter { $0.net < -0.005 }
            .sorted { $0.net < $1.net }
            .map { (person: $0.person, amount: -$0.net) }

        var result: [Settlement] = []
        var ci = 0
        var di = 0

        while ci < creditors.count && di < debtors.count {
            let amount = min(creditors[ci].amount, debtors[di].amount)
            result.append(Settlement(
                fromID: debtors[di].person.id,
                toID: creditors[ci].person.id,
                amount: amount
            ))
            creditors[ci].amount -= amount
            debtors[di].amount -= amount
            if creditors[ci].amount < 0.005 { ci += 1 }
            if debtors[di].amount < 0.005 { di += 1 }
        }

        return result
    }
}