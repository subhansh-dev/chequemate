import SwiftUI
import Supabase

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
            .task {
                for await state in supabase.auth.authStateChanges {
                    if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                        appState.isAuthenticated = state.session != nil
                        if let session = state.session {
                            appState.currentUser = session.user
                        }
                    }
                }
            }
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            MeshBackground()

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
            .tint(HueWave.teal)
        }
    }
}
// Huewaves 
