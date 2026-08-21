import SwiftUI

// MARK: - Sessions View (Pending + History)

struct SessionsView: View {
    @EnvironmentObject var store: ChequeMateStore
    @State private var selectedTab = 0
    @State private var sessionToDelete: Session?
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                ChequeWave.paper.ignoresSafeArea()

                VStack(spacing: 0) {
                    segmentPicker
                    if filteredSessions.isEmpty {
                        emptyState
                    } else {
                        sessionList
                    }
                }
            }
            .navigationTitle("Sessions")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .alert("Delete Session?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    if let s = sessionToDelete {
                        Haptics.heavy()
                        store.deleteSession(s.id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This can't be undone.")
            }
        }
    }

    private var filteredSessions: [Session] {
        selectedTab == 0
            ? store.sessions.filter { $0.isPending }
            : store.sessions.filter { !$0.isPending }
    }

    private var segmentPicker: some View {
        HStack(spacing: 0) {
            segmentButton("Pending", icon: "clock.fill", index: 0, color: ChequeWave.magenta)
            segmentButton("History", icon: "checkmark.seal.fill", index: 1, color: Color(red: 0.18, green: 0.72, blue: 0.45))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func segmentButton(_ title: String, icon: String, index: Int, color: Color) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
            }
            .foregroundStyle(selectedTab == index ? color : ChequeWave.inkSoft)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                if selectedTab == index {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.1))
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: selectedTab == 0 ? "clock.badge.questionmark" : "archivebox")
                .font(.system(size: 48))
                .foregroundStyle(ChequeWave.inkSoft.opacity(0.3))
            Text(selectedTab == 0 ? "No pending sesh" : "No history yet")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(ChequeWave.inkSoft)
            Text(selectedTab == 0
                ? "Settle up and save a sesh with pending payments"
                : "Fully settled seshs will show up here")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(ChequeWave.inkSoft.opacity(0.7))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private var sessionList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredSessions) { session in
                    NavigationLink {
                        SessionDetailView(session: session)
                    } label: {
                        sessionCard(session)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            sessionToDelete = session
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            sessionToDelete = session
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }

    private func sessionCard(_ session: Session) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(session.name)
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .foregroundStyle(ChequeWave.ink)
                    Text(session.date, style: .date)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(ChequeWave.inkSoft)
                }

                Spacer()

                if !session.imageData.isEmpty {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(ChequeWave.blueprint.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "photo.stack")
                            .font(.system(size: 16))
                            .foregroundStyle(ChequeWave.blueprint.opacity(0.6))
                        Text("\(session.imageData.count)")
                            .font(.system(.caption2, design: .rounded, weight: .black))
                            .foregroundStyle(ChequeWave.blueprint)
                            .offset(x: 12, y: -10)
                    }
                }

                if session.isPending {
                    Text("PENDING")
                        .font(.system(.caption2, design: .rounded, weight: .black))
                        .foregroundStyle(ChequeWave.magenta)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background {
                            Capsule()
                                .fill(ChequeWave.magenta.opacity(0.1))
                        }
                } else {
                    Text("SETTLED")
                        .font(.system(.caption2, design: .rounded, weight: .black))
                        .foregroundStyle(Color(red: 0.18, green: 0.72, blue: 0.45))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background {
                            Capsule()
                                .fill(Color(red: 0.18, green: 0.72, blue: 0.45).opacity(0.1))
                        }
                }
            }

            Divider()
                .padding(.vertical, 10)

            HStack(spacing: 16) {
                infoPill(icon: "person.2.fill", text: "\(session.people.count)")
                infoPill(icon: "indianrupee.circle.fill", text: session.money(session.totalSpent))
                if session.isPending {
                    infoPill(icon: "arrow.triangle.2.circlepath", text: "\(session.settledCount)/\(session.totalCount)")
                }
            }

            if session.isPending {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(ChequeWave.ink.opacity(0.08))
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(ChequeWave.magenta)
                            .frame(width: geo.size.width * session.progress, height: 5)
                    }
                }
                .frame(height: 5)
                .padding(.top, 10)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: ChequeWave.ink.opacity(0.06), radius: 8, y: 3)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(ChequeWave.ink.opacity(0.04), lineWidth: 1)
        }
    }

    private func infoPill(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(ChequeWave.blueprint.opacity(0.6))
            Text(text)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(ChequeWave.inkSoft)
        }
    }
}
