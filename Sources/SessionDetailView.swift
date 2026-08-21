import SwiftUI

// MARK: - Session Detail View

struct SessionDetailView: View {
    let session: Session
    @EnvironmentObject var store: ChequeMateStore
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    @State private var showFullImage: UIImage?
    @State private var selectedImageIndex = 0

    var body: some View {
        ZStack {
            ChequeWave.paper.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    heroSection
                    if !session.imageData.isEmpty { photosSection }
                    summarySection
                    peopleSection
                    expensesSection
                    settlementsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(ChequeWave.inkSoft)
                }
            }
        }
        .alert("Delete Session?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Haptics.heavy()
                store.deleteSession(session.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(item: $showFullImage) { img in
            FullImageView(image: img)
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        session.isPending
                        ? ChequeWave.magenta.opacity(0.1)
                        : Color(red: 0.18, green: 0.72, blue: 0.45).opacity(0.1)
                    )
                    .frame(width: 70, height: 70)
                Image(systemName: session.isPending ? "clock.fill" : "checkmark.seal.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(session.isPending ? ChequeWave.magenta : Color(red: 0.18, green: 0.72, blue: 0.45))
            }

            Text(session.name)
                .font(.system(.title2, design: .rounded, weight: .black))
                .foregroundStyle(ChequeWave.ink)
                .multilineTextAlignment(.center)

            Text(session.date, style: .date)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(ChequeWave.inkSoft)

            HStack(spacing: 8) {
                if session.isPending {
                    Label("Pending", systemImage: "clock")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(ChequeWave.magenta)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background {
                            Capsule()
                                .fill(ChequeWave.magenta.opacity(0.1))
                        }
                } else {
                    Label("Settled", systemImage: "checkmark")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(Color(red: 0.18, green: 0.72, blue: 0.45))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background {
                            Capsule()
                                .fill(Color(red: 0.18, green: 0.72, blue: 0.45).opacity(0.1))
                        }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: ChequeWave.ink.opacity(0.06), radius: 10, y: 4)
        }
    }

    // MARK: - Photos

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 13))
                    .foregroundStyle(ChequeWave.blueprint.opacity(0.6))
                Text("PHOTOS")
                    .font(.system(.caption2, design: .rounded, weight: .black))
                    .foregroundStyle(ChequeWave.blueprint)
                    .tracking(1.2)
                Text("\(session.imageData.count)")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(ChequeWave.inkSoft)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(session.imageData.indices, id: \.self) { i in
                        if let uiImage = UIImage(data: session.imageData[i]) {
                            Button {
                                showFullImage = uiImage
                            } label: {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: ChequeWave.ink.opacity(0.04), radius: 6, y: 2)
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        HStack(spacing: 0) {
            summaryPill(
                title: "Total",
                value: session.money(session.totalSpent),
                color: ChequeWave.blueprint
            )
            Divider().frame(height: 40).padding(.horizontal, 12)
            summaryPill(
                title: "Per Head",
                value: session.money(session.perHead),
                color: ChequeWave.magenta
            )
            Divider().frame(height: 40).padding(.horizontal, 12)
            summaryPill(
                title: "People",
                value: "\(session.people.count)",
                color: Color(red: 0.18, green: 0.72, blue: 0.45)
            )
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: ChequeWave.ink.opacity(0.04), radius: 6, y: 2)
        }
    }

    private func summaryPill(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(.caption2, design: .rounded, weight: .black))
                .foregroundStyle(color.opacity(0.6))
                .tracking(1)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .black))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - People

    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("SQUAD", icon: "person.2.fill", color: ChequeWave.blueprint)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(session.people) { person in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(palette[person.tintIndex % palette.count])
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(String(person.name.prefix(1)).uppercased())
                                        .font(.system(.caption, design: .rounded, weight: .black))
                                        .foregroundStyle(.white)
                                )
                            Text(person.name)
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(ChequeWave.ink)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background {
                            Capsule()
                                .fill(palette[person.tintIndex % palette.count].opacity(0.1))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Expenses

    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("EXPENSES", icon: "indianrupee.circle.fill", color: ChequeWave.magenta)

            VStack(spacing: 8) {
                ForEach(session.expenses) { expense in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(palette[expense.payerID.hashValue % palette.count])
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text(String(session.personName(expense.payerID).prefix(1)).uppercased())
                                    .font(.system(.caption2, design: .rounded, weight: .black))
                                    .foregroundStyle(.white)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.personName(expense.payerID))
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(ChequeWave.ink)
                            Text(expense.note)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(ChequeWave.inkSoft)
                        }

                        Spacer()

                        Text(session.money(expense.amount))
                            .font(.system(.subheadline, design: .rounded, weight: .black))
                            .foregroundStyle(ChequeWave.ink)
                    }
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(palette[expense.payerID.hashValue % palette.count].opacity(0.04))
                    }
                }
            }
        }
    }

    // MARK: - Settlements

    private var settlementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                "SETTLEMENTS",
                icon: "arrow.triangle.2.circlepath",
                color: Color(red: 0.18, green: 0.72, blue: 0.45)
            )

            if session.settlements.isEmpty {
                Text("No settlements needed")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(ChequeWave.inkSoft)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                    }
            } else {
                VStack(spacing: 8) {
                    ForEach(session.settlements) { s in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(s.isPaid ? Color(red: 0.18, green: 0.72, blue: 0.45) : ChequeWave.inkSoft.opacity(0.3))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: s.isPaid ? "checkmark" : "arrow.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                )

                            Text(session.personName(s.fromID))
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(ChequeWave.ink)

                            Text(session.money(s.amount))
                                .font(.system(.subheadline, design: .rounded, weight: .black))
                                .foregroundStyle(ChequeWave.magenta)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background {
                                    Capsule()
                                        .fill(ChequeWave.magenta.opacity(0.08))
                                }

                            Image(systemName: "arrow.right")
                                .font(.system(size: 10))
                                .foregroundStyle(ChequeWave.inkSoft)

                            Text(session.personName(s.toID))
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(ChequeWave.ink)

                            Spacer()

                            if s.isPaid {
                                Text("PAID")
                                    .font(.system(.caption2, design: .rounded, weight: .black))
                                    .foregroundStyle(Color(red: 0.18, green: 0.72, blue: 0.45))
                            }
                        }
                        .padding(12)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(s.isPaid ? Color(red: 0.18, green: 0.72, blue: 0.45).opacity(0.04) : Color.white)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color.opacity(0.6))
            Text(title)
                .font(.system(.caption2, design: .rounded, weight: .black))
                .foregroundStyle(color)
                .tracking(1.2)
        }
    }

    private let palette: [Color] = [
        ChequeWave.lavender, ChequeWave.mint, ChequeWave.peach,
        ChequeWave.sky, ChequeWave.blush
    ]
}

// MARK: - Full Image Viewer

struct FullImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4)
                    }
                    .padding(20)
                }
                Spacer()
            }
        }
    }
}

// MARK: - UIImage Identifiable wrapper

extension UIImage: @retroactive Identifiable {
    public var id: String { UUID().uuidString }
}
