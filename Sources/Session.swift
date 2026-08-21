import Foundation
import SwiftUI

// MARK: - Session

struct Session: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var date: Date
    var people: [Person]
    var expenses: [Expense]
    var settlements: [Settlement]
    var currency: Currency
    var imageData: [Data] = []
    var isPending: Bool = true

    var totalSpent: Double { expenses.reduce(0) { $0 + $1.amount } }
    var perHead: Double { people.isEmpty ? 0 : totalSpent / Double(people.count) }
    var pendingSettlements: [Settlement] { settlements.filter { !$0.isPaid } }
    var settledSettlements: [Settlement] { settlements.filter { $0.isPaid } }
    var allSettled: Bool { !settlements.isEmpty && pendingSettlements.isEmpty }
    var settledCount: Int { settledSettlements.count }
    var totalCount: Int { settlements.count }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(settledCount) / Double(totalCount)
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
}
