import SwiftUI

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var isLoading = false

    var body: some View {
        ZStack {
            MeshBackground()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text(initials)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(HueWave.peach)
                            .frame(width: 90, height: 90)
                            .glassEffect(.regular.tint(HueWave.peach.opacity(0.1)), in: .circle)

                        VStack(spacing: 4) {
                            Text(displayName)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(HueWave.ink)
                            Text(email)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(HueWave.inkSoft)
                        }
                    }
                    .padding(.top, 40)

                    statsCard

                    VStack(spacing: 12) {
                        GlassButton(title: "Sign Out", icon: "arrow.right.square", action: signOut, variant: .ghost)
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
        }
    }

    private var initials: String {
        let email = appState.currentUser?.email ?? "guest"
        return String(email.prefix(1)).uppercased()
    }

    private var displayName: String {
        appState.currentUser?.email.components(separatedBy: "@").first?.capitalized ?? "Guest"
    }

    private var email: String {
        appState.currentUser?.email ?? "guest@huewaves.app"
    }

    private var statsCard: some View {
        GlassCard {
            HStack(spacing: 0) {
                statItem(value: "3", label: "Modes")
                Divider().frame(height: 40).background(HueWave.inkFaint.opacity(0.2))
                statItem(value: "∞", label: "Sessions")
                Divider().frame(height: 40).background(HueWave.inkFaint.opacity(0.2))
                statItem(value: "1", label: "Streak")
            }
            .padding(.vertical, 20)
        }
        .padding(.horizontal, 20)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(HueWave.peach)
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(HueWave.inkFaint)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func signOut() {
        isLoading = true
        appState.signOut()
        isLoading = false
    }
}

// MARK: - Sessions View

struct SessionsView: View {
    var body: some View {
        ZStack {
            MeshBackground()

            VStack(spacing: 24) {
                Text("Sessions")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(HueWave.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 40)

                GlassCard {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 40))
                            .foregroundStyle(HueWave.inkFaint)
                        Text("No sessions yet")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(HueWave.ink)
                        Text("Start your first sensory experience to see it here")
                            .font(.system(size: 15))
                            .foregroundStyle(HueWave.inkSoft)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }
}
