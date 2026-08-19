import SwiftUI

// MARK: - Squad Tab

struct SquadView: View {
    @EnvironmentObject var store: ChequeMateStore

    @State private var newName = ""
    @State private var showAddExpense = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    brandHeader
                    statsRow

                    if store.people.isEmpty {
                        emptySquadCard
                    } else {
                        squadSection
                        expensesSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .navigationTitle("ChequeMate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { currencyMenu }
            }
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseSheet()
                .environmentObject(store)
        }
    }

    // MARK: - Brand header

    private var brandHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "checkerboard.shield")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(ChequeWave.peach)
                Text("ChequeMate")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(ChequeWave.ink)
            }
            Text("Split it. Settle it. Checkmate.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(ChequeWave.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(title: "Total tab", value: store.money(store.totalSpent), icon: "receipt.fill", tint: ChequeWave.peach)
            statCard(title: "Per head", value: store.money(store.perHead), icon: "person.2.fill", tint: ChequeWave.mint)
        }
    }

    private func statCard(title: String, value: String, icon: String, tint: Color) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(tint)
                    Text(title.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(ChequeWave.inkFaint)
                }
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(ChequeWave.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty squad

    private var emptySquadCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(ChequeWave.peach)
                VStack(spacing: 6) {
                    Text("Build your squad")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(ChequeWave.ink)
                    Text("Add the friends who went out with you. Then start logging who paid for what.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(ChequeWave.inkSoft)
                        .multilineTextAlignment(.center)
                }
                GlassButton(title: "Load example squad", icon: "wand.and.stars", variant: .secondary) {
                    withAnimation(.spring(response: 0.4)) {
                        store.loadExample()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Squad section

    private var squadSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(index: "01", tag: "Who's in", title: "The Squad", desc: "Add everyone who owes or is owed.")

            HStack(spacing: 10) {
                GlassTextField(placeholder: "Name", text: $newName, icon: "person.fill")

                GlassIconButton(icon: "plus", action: addPerson)
            }

            if !store.people.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(store.people) { person in
                            personChip(person)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func personChip(_ person: Person) -> some View {
        let tint = store.tint(for: person)
        return HStack(spacing: 8) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)
            Text(person.name)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(ChequeWave.ink)
            Button {
                withAnimation(.spring(response: 0.3)) {
                    store.removePerson(person.id)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ChequeWave.inkFaint)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular.tint(tint.opacity(0.14)), in: .capsule)
    }

    // MARK: - Expenses section

    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(index: "02", tag: "The damage", title: "Expenses", desc: "Who paid and for what.")

            if store.expenses.isEmpty {
                GlassCard {
                    VStack(spacing: 12) {
                        Image(systemName: "receipt.fill")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(ChequeWave.inkFaint)
                        Text("No expenses yet")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(ChequeWave.ink)
                        Text("Tap below to log the first one. The roast is watching.")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(ChequeWave.inkSoft)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(store.expenses) { expense in
                        expenseRow(expense)
                    }
                }
            }

            GlassButton(title: "Add expense", icon: "plus", variant: .secondary) {
                showAddExpense = true
            }
        }
    }

    private func expenseRow(_ expense: Expense) -> some View {
        let payer = store.people.first { $0.id == expense.payerID }
        let tint = payer.map { store.tint(for: $0) } ?? ChequeWave.inkFaint

        return HStack(spacing: 14) {
            Circle()
                .fill(tint)
                .frame(width: 34, height: 34)
                .overlay {
                    Text(String((payer?.name.first).map(String.init) ?? "?"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.7))
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(payer?.name ?? "Someone")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(ChequeWave.ink)
                Text("paid for \(expense.note)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(ChequeWave.inkSoft)
                    .lineLimit(1)
            }
            Spacer()
            Text(store.money(expense.amount))
                .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                .foregroundStyle(ChequeWave.ink)
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    store.removeExpense(expense.id)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ChequeWave.inkFaint)
            }
        }
        .padding(14)
        .glassEffect(.regular.tint(tint.opacity(0.08)), in: .rect(cornerRadius: 18))
    }

    // MARK: - Currency menu

    private var currencyMenu: some View {
        Menu {
            ForEach(Currency.allCases) { currency in
                Button {
                    store.currency = currency
                } label: {
                    if currency == store.currency {
                        Label(currency.name, systemImage: "checkmark")
                    } else {
                        Text(currency.name)
                    }
                }
            }
        } label: {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(ChequeWave.peach)
        }
    }

    private func addPerson() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Haptics.tap()
        withAnimation(.spring(response: 0.4)) {
            store.addPerson(trimmed)
        }
        newName = ""
    }
}

// MARK: - Add Expense Sheet

struct AddExpenseSheet: View {
    @EnvironmentObject var store: ChequeMateStore
    @Environment(\.dismiss) private var dismiss

    @State private var payerID: UUID?
    @State private var amountText = ""
    @State private var note = ""
    @FocusState private var amountFocused: Bool

    private var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var isValid: Bool {
        payerID != nil && amount > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ChequeWave.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        payerPicker
                        amountField
                        noteField
                        GlassButton(title: "Add expense", icon: "plus", action: addExpense)
                            .disabled(!isValid)
                            .opacity(isValid ? 1 : 0.4)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("New expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(ChequeWave.inkSoft)
                }
            }
            .onAppear {
                if payerID == nil {
                    payerID = store.people.first?.id
                }
                amountFocused = true
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var payerPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Who paid?")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(ChequeWave.ink)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.people) { person in
                        let selected = payerID == person.id
                        let tint = store.tint(for: person)
                        Button {
                            Haptics.tap()
                            withAnimation(.spring(response: 0.3)) {
                                payerID = person.id
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(tint)
                                    .frame(width: 8, height: 8)
                                Text(person.name)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(selected ? .black.opacity(0.8) : ChequeWave.ink)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background {
                                if selected {
                                    Capsule().fill(tint)
                                }
                            }
                            .glassEffect(.regular.tint(tint.opacity(selected ? 0.4 : 0.1)), in: .capsule)
                        }
                    }
                }
            }
        }
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How much?")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(ChequeWave.ink)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(store.currency.symbol)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(ChequeWave.peach)
                TextField("0", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(ChequeWave.ink)
                    .focused($amountFocused)
            }
            .padding(18)
            .glassEffect(.regular.tint(ChequeWave.peach.opacity(0.08)), in: .rect(cornerRadius: 20))
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What for?")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(ChequeWave.ink)

            GlassTextField(placeholder: "Dinner, tickets, chaiâ€¦", text: $note, icon: "tag.fill")
        }
    }

    private func addExpense() {
        guard let payerID, isValid else { return }
        Haptics.success()
        withAnimation(.spring(response: 0.4)) {
            store.addExpense(payerID: payerID, amount: amount, note: note)
        }
        dismiss()
    }
}