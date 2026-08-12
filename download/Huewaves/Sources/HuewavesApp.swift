import SwiftUI

@main
struct HuewavesApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isAuthenticated {
                    MainTabView()
                        .environmentObject(appState)
                } else {
                    AuthView()
                        .environmentObject(appState)
                }
            }
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: LocalUser?
    @Published var isGuest = true
    let authService = LocalAuthService()

    func signInAsGuest() {
        isGuest = true
        isAuthenticated = true
    }

    func signOut() {
        authService.signOut()
        isAuthenticated = false
        isGuest = false
        currentUser = nil
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            MeshBackground()

            if appState.isGuest {
                GuestExperienceView()
            } else {
                TabView(selection: $selectedTab) {
                    ExperienceView()
                        .tabItem {
                            Image(systemName: "waveform.circle.fill")
                            Text("Experience")
                        }
                        .tag(0)

                    SessionsView()
                        .tabItem {
                            Image(systemName: "clock.fill")
                            Text("Sessions")
                        }
                        .tag(1)

                    ProfileView()
                        .tabItem {
                            Image(systemName: "person.fill")
                            Text("Profile")
                        }
                        .tag(2)
                }
                .tint(HueWave.peach)
            }
        }
    }
}

// MARK: - Guest Experience

struct GuestExperienceView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedMode: SensoryMode = .colorToSound

    var body: some View {
        ZStack {
            MeshBackground()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Huewaves")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(HueWave.ink)
                        Text("Guest Mode")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(HueWave.peach)
                    }
                    Spacer()
                    Button("Sign In") {
                        appState.signOut()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(HueWave.peach)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                GlassEffectContainer {
                    HStack(spacing: 8) {
                        ForEach(SensoryMode.allCases, id: \.self) { mode in
                            ModeChip(mode: mode, isSelected: selectedMode == mode) {
                                withAnimation(.spring(response: 0.3)) { selectedMode = mode }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ScrollView {
                    Group {
                        switch selectedMode {
                        case .colorToSound:
                            ColorToSoundView()
                        case .soundToVisual:
                            SoundToVisualView()
                        case .audioToHaptic:
                            AudioToHapticView()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}
