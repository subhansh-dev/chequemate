import SwiftUI

// MARK: - Squad Tab — Poster Zine

struct SquadView: View {
    @EnvironmentObject var store: ChequeMateStore
    @State private var newName = ""
    @State private var showAddExpense = false
    @State private var chipsAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    topStrip
                    posterHero
                    statsPoster
                    if store.people.isEmpty {
                        emptyPoster
                    } else {
                        squadPoster
                        expensesPoster
                    }
                    BarcodeStrip().padding(.top, 6)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 36)
            }
            .navigationTitle("ChequeMate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { currencyMenu } }
        }
        .sheet(isPresented: $showAddExpense) { AddExpenseSheet().environmentObject(store) }
    }

    // thin editorial strip
    private var topStrip: some View {
        HStack(spacing: 6) {
            Text("©2026").font(.system(size: 9, weight: .black, design: .monospaced)).foregroundStyle(ChequeWave.ink)
            Rectangle().fill(ChequeWave.ink.opacity(0.15)).frame(height: 0.7)
            Text("SPLIT. SETTLE. CHECKMATE.").font(.system(size: 9, weight: .black, design: .monospaced)).tracking(1).foregroundStyle(ChequeWave.blueprint)
            Spacer()
            Text("01 — SQUAD").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(ChequeWave.inkFaint)
        }
        .padding(.vertical, 6)
    }

    // big poster hero with 01 + blueprint block
    private var posterHero: some View {
        ZStack(alignment: .topTrailing) {
            PosterCard(accent: ChequeWave.blueprint) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Rectangle().fill(ChequeWave.magenta).frame(width: 28, height: 3)
                            Text("HATSUNE MIKU — wait, no —").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(ChequeWave.magenta)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            BigNumber(n: "01")
                            VStack(alignment: .leading, spacing: 1) {
                                Text("CHEQUEMATE").font(.system(size: 22, weight: .black, design: .rounded)).tracking(-0.5).foregroundStyle(ChequeWave.ink)
                                Text("佐々木 渉  —  精算ポスター").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(ChequeWave.blueprint)
                                Text("Split the tab. Keep the friendships.").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(ChequeWave.inkSoft)
                            }
                        }
                        HStack(spacing: 6) {
                            PastelPill(text: "\(store.people.count) people", tint: ChequeWave.blueprint)
                            PastelPill(text: store.money(store.totalSpent), tint: ChequeWave.magenta)
                        }
                        .padding(.top, 4)
                    }
                    Spacer()
                }
            }
            // halftone corner
            HalftoneDots(color: ChequeWave.blueprint.opacity(0.06))
                .frame(width: 120, height: 80)
                .clipShape(Rectangle())
                .allowsHitTesting(false)
        }
    }

    private var statsPoster: some View {
        HStack(spacing: 10) {
            statBlock(title: "TOTAL TAB", value: store.money(store.totalSpent), icon: "receipt.fill", color: ChequeWave.blueprint)
            statBlock(title: "PER HEAD", value: store.money(store.perHead), icon: "person.2.fill", color: ChequeWave.magenta)
        }
    }

    private func statBlock(title: String, value: String, icon: String, color: Color) -> some View {
        ZStack(alignment: .topTrailing) {
            PosterCard(accent: color) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Rectangle().fill(color).frame(width: 16, height: 16)
                            .overlay { Image(systemName: icon).font(.system(size: 9, weight: .black)).foregroundStyle(.white) }
                        Text(title).font(.system(size: 10, weight: .black, design: .monospaced)).tracking(0.8).foregroundStyle(ChequeWave.inkFaint)
                    }
                    Text(value).font(.system(size: 20, weight: .black, design: .rounded)).foregroundStyle(ChequeWave.ink).lineLimit(1).minimumScaleFactor(0.5)
                    Rule(color: color.opacity(0.18))
                    Text("¥ TAX INCLUDED — POSTER NO. 01").font(.system(size: 7, weight: .bold, design: .monospaced)).foregroundStyle(ChequeWave.inkFaint)
                }
            }
            HalftoneDots(color: color.opacity(0.07)).frame(width: 60, height: 40).clipShape(Rectangle())
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyPoster: some View {
        PosterCard(accent: ChequeWave.blueprint) {
            VStack(spacing: 12) {
                ZStack {
                    Rectangle().fill(ChequeWave.paperDeep).frame(width: 84, height: 84)
                        .overlay { Rectangle().strokeBorder(ChequeWave.ink, lineWidth: 1.2) }
                    HalftoneDots(spacing: 5, dot: 1.4).frame(width: 84, height: 84).clipShape(Rectangle()).opacity(0.5)
                    Image(systemName: "person.3.fill").font(.system(size: 22, weight: .black)).foregroundStyle(ChequeWave.blueprint)
                }
                Text("BUILD YOUR SQUAD").font(.system(size: 14, weight: .black, design: .rounded)).tracking(1).foregroundStyle(ChequeWave.ink)
                Text("Add the friends who went out with you.\nInk only — no photos needed.").font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(ChequeWave.inkSoft).multilineTextAlignment(.center)
                GlassButton(title: "Load example squad", icon: "wand.and.stars", variant: .secondary) {
                    withAnimation(.spring(response: 0.4)) { store.loadExample() }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var squadPoster: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "The Squad", desc: "Add everyone who owes or is owed. Thick ink, halftone fill.", icon: "person.3.fill", tint: ChequeWave.blueprint, number: "01")
            HStack(spacing: 8) {
                GlassTextField(placeholder: "Name — e.g. Hatsune", text: $newName, icon: "person.fill")
                GlassIconButton(icon: "plus", action: addPerson, gradient: ChequeWave.blueprintGradient)
            }
            if !store.people.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(store.people.enumerated()), id: \.element.id) { index, person in
                            personChip(person)
                                .scaleEffect(chipsAppeared ? 1 : 0.3)
                                .offset(y: chipsAppeared ? 0 : 20)
                                .opacity(chipsAppeared ? 1 : 0)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.6)
                                        .delay(Double(index) * 0.06),
                                    value: chipsAppeared
                                )
                        }
                    }.padding(.vertical, 4)
                }
                .onAppear { chipsAppeared = true }
                .onChange(of: store.people.count) { _ in
                    chipsAppeared = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation { chipsAppeared = true }
                    }
                }
            }
        }
    }

    private func personChip(_ person: Person) -> some View {
        let gradient = ChequeWave.gradient(for: person.tintIndex)
        return HStack(spacing: 7) {
            ZStack {
                Circle().fill(gradient).frame(width: 22, height: 22)
                Text(String(person.name.prefix(1).uppercased())).font(.system(size: 10, weight: .black, design: .rounded)).foregroundStyle(.white)
            }
            Text(person.name).font(.system(size: 12, weight: .black, design: .rounded)).foregroundStyle(ChequeWave.ink)
            Button { withAnimation(.spring(response: 0.3)) { store.removePerson(person.id) } } label: {
                Image(systemName: "xmark").font(.system(size: 9, weight: .black)).foregroundStyle(.white)
                    .frame(width: 16, height: 16).background { Circle().fill(ChequeWave.ink) }
            }
        }
        .padding(.leading, 6).padding(.trailing, 8).padding(.vertical, 6)
        .background { Capsule().fill(Color.white).shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3) }
        .overlay { Capsule().strokeBorder(ChequeWave.ink, lineWidth: 1) }
    }

    private var expensesPoster: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader(title: "Expenses", desc: "Who paid and for what. Poster No. 02 →", icon: "receipt.fill", tint: ChequeWave.magenta, number: "02")
                Spacer()
                if !store.expenses.isEmpty { PastelPill(text: "\(store.expenses.count) items", tint: ChequeWave.magenta) }
            }
            if store.expenses.isEmpty {
                PosterCard(accent: ChequeWave.magenta) {
                    VStack(spacing: 10) {
                        Rectangle().fill(ChequeWave.magenta.opacity(0.08)).frame(width: 56, height: 56)
                            .overlay { Rectangle().strokeBorder(ChequeWave.magenta, lineWidth: 1.2) }
                            .overlay { Image(systemName: "fork.knife").font(.system(size: 18, weight: .black)).foregroundStyle(ChequeWave.magenta) }
                        Text("NO EXPENSES YET").font(.system(size: 12, weight: .black, design: .rounded)).foregroundStyle(ChequeWave.ink)
                        Text("Tap below to log the first one. The roast is watching.").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(ChequeWave.inkSoft).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity).padding(.vertical, 6)
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(store.expenses.enumerated()), id: \.element.id) { index, expense in
                        expenseRow(expense)
                            .offset(x: chipsAppeared ? 0 : -20)
                            .opacity(chipsAppeared ? 1 : 0)
                            .animation(
                                .spring(response: 0.35, dampingFraction: 0.7)
                                    .delay(Double(index) * 0.05),
                                value: chipsAppeared
                            )
                    }
                }
            }
            GlassButton(title: "Add expense", icon: "plus", variant: .secondary) { showAddExpense = true }
        }
    }

    private func expenseRow(_ expense: Expense) -> some View {
        let payer = store.people.first { $0.id == expense.payerID }
        let gradient = payer.map { ChequeWave.gradient(for: $0.tintIndex) } ?? ChequeWave.blueprintGradient
        let payerName = payer?.name ?? "Someone"
        return HStack(spacing: 10) {
            PersonAvatar(name: payerName, gradient: gradient, size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(payerName).font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(ChequeWave.ink)
                HStack(spacing: 4) {
                    Rectangle().fill(ChequeWave.magenta).frame(width: 8, height: 8)
                    Text(expense.note.uppercased()).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(ChequeWave.inkSoft).lineLimit(1)
                }
            }
            Spacer()
            Text(store.money(expense.amount)).font(.system(size: 13, weight: .black, design: .monospaced)).foregroundStyle(ChequeWave.ink)
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background { Rectangle().fill(ChequeWave.paperDeep) }
                .overlay { Rectangle().strokeBorder(ChequeWave.ink, lineWidth: 1) }
            Button { withAnimation(.easeOut(duration: 0.2)) { store.removeExpense(expense.id) } } label: {
                Image(systemName: "trash").font(.system(size: 11, weight: .black)).foregroundStyle(.white)
                    .frame(width: 28, height: 28).background { Rectangle().fill(ChequeWave.negative) }
                    .overlay { Rectangle().strokeBorder(ChequeWave.ink, lineWidth: 1) }
            }
        }
        .padding(10)
        .background { Rectangle().fill(Color.white) }
        .overlay { Rectangle().strokeBorder(ChequeWave.ink, lineWidth: 1.2) }
    }

    private var currencyMenu: some View {
        Menu {
            ForEach(Currency.allCases) { c in Button { store.currency = c } label: { if c == store.currency { Label(c.name, systemImage: "checkmark") } else { Text(c.name) } } }
        } label: {
            HStack(spacing: 4) {
                Text(store.currency.rawValue).font(.system(size: 11, weight: .black, design: .monospaced)).foregroundStyle(.white)
                Image(systemName: "chevron.down").font(.system(size: 8, weight: .black)).foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 9).padding(.vertical, 6)
            .background { Rectangle().fill(ChequeWave.blueprint) }
            .overlay { Rectangle().strokeBorder(ChequeWave.ink, lineWidth: 1) }
        }
    }

    private func addPerson() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Haptics.tap()
        withAnimation(.spring(response: 0.4)) { store.addPerson(trimmed) }
        newName = ""
    }
}

// MARK: - Add Expense Sheet — paper

struct AddExpenseSheet: View {
    @EnvironmentObject var store: ChequeMateStore
    @Environment(\.dismiss) private var dismiss
    @State private var payerID: UUID?
    @State private var amountText = ""
    @State private var note = ""
    @FocusState private var amountFocused: Bool
    private var amount: Double { Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var isValid: Bool { payerID != nil && amount > 0 }

    private func sanitizeAmount(_ input: String) -> String {
        var filtered = input.filter { $0.isNumber || $0 == "." || $0 == "," }
        let dots = filtered.filter { $0 == "." || $0 == "," }
        if dots.count > 1 {
            let firstDotIndex = filtered.firstIndex { $0 == "." || $0 == "," }
            if let idx = firstDotIndex {
                filtered = String(filtered.prefix(through: idx)) + String(filtered.dropFirst(idx + 1).filter { $0 != "." && $0 != "," })
            }
        }
        return filtered
    }
    var body: some View {
        NavigationStack {
            ZStack {
                ChequeWave.paper.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        payerPicker
                        amountField
                        noteField
                        GlassButton(title: "Add expense", icon: "plus", action: addExpense).disabled(!isValid).opacity(isValid ? 1 : 0.4)
                    }.padding(18)
                }
            }
            .navigationTitle("NEW EXPENSE — 02").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() }.foregroundStyle(ChequeWave.inkSoft).font(.system(.callout, design: .rounded, weight: .bold)) } }
            .onAppear { if payerID == nil { payerID = store.people.first?.id }; amountFocused = true }
            .onChange(of: amountText) { newVal in
                let sanitized = sanitizeAmount(newVal)
                if sanitized != newVal { amountText = sanitized }
            }
        }
        .presentationDetents([.medium, .large])
    }
    private var payerPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) { Rectangle().fill(ChequeWave.blueprint).frame(width: 12, height: 12); Text("WHO PAID?").font(.system(size: 11, weight: .black, design: .monospaced)).tracking(1).foregroundStyle(ChequeWave.ink) }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.people) { person in
                        let selected = payerID == person.id
                        let gradient = ChequeWave.gradient(for: person.tintIndex)
                        Button {
                            Haptics.tap()
                            withAnimation(.spring(response: 0.3)) { payerID = person.id }
                        } label: {
                            HStack(spacing: 6) {
                                Circle().fill(gradient).frame(width: 18, height: 18)
                                    .overlay { Text(String(person.name.prefix(1).uppercased())).font(.system(size: 9, weight: .black, design: .rounded)).foregroundStyle(.white) }
                                Text(person.name).font(.system(size: 12, weight: .black, design: .rounded))
                            }
                            .foregroundStyle(selected ? .white : ChequeWave.ink)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background { if selected { Rectangle().fill(gradient) } else { Rectangle().fill(Color.white) } }
                            .overlay { Rectangle().strokeBorder(selected ? ChequeWave.ink : Color.black.opacity(0.12), lineWidth: 1.1) }
                        }
                    }
                }
            }
        }
    }
    private var amountField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) { Rectangle().fill(ChequeWave.magenta).frame(width: 12, height: 12); Text("HOW MUCH?").font(.system(size: 11, weight: .black, design: .monospaced)).tracking(1).foregroundStyle(ChequeWave.ink) }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(store.currency.symbol).font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(ChequeWave.blueprint)
                TextField("0", text: $amountText).keyboardType(.decimalPad).font(.system(size: 34, weight: .black, design: .rounded)).monospacedDigit().foregroundStyle(ChequeWave.ink).focused($amountFocused)
            }
            .padding(14)
            .background { Rectangle().fill(Color.white) }
            .overlay { Rectangle().strokeBorder(amountFocused ? ChequeWave.blueprint : ChequeWave.ink, lineWidth: amountFocused ? 1.6 : 1.2) }
        }
    }
    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) { Rectangle().fill(ChequeWave.paperDeep).frame(width: 12, height: 12).overlay { Rectangle().strokeBorder(ChequeWave.ink, lineWidth: 0.7) }; Text("WHAT FOR?").font(.system(size: 11, weight: .black, design: .monospaced)).tracking(1).foregroundStyle(ChequeWave.ink) }
            GlassTextField(placeholder: "Dinner, tickets, chai…", text: $note, icon: "tag.fill")
        }
    }
    private func addExpense() {
        guard let payerID, isValid else { return }
        Haptics.success()
        withAnimation(.spring(response: 0.4)) { store.addExpense(payerID: payerID, amount: amount, note: note) }
        dismiss()
    }
}
