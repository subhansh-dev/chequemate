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
                    InstrumentView()
                        .tabItem {
                            Image(systemName: "waveform.circle.fill")
                            Text("Play")
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

// MARK: - Guest Experience (full instrument, no auth required)

struct GuestExperienceView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            MeshBackground()

            InstrumentView()
                .overlay(alignment: .topTrailing) {
                    Button("Sign In") {
                        appState.signOut()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HueWave.peach)
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }
        }
    }
}
