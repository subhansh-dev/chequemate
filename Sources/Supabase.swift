import Foundation

// MARK: - Backend Configuration

enum Backend {
    static let supabaseURL = "https://YOUR_PROJECT.supabase.co"
    static let supabaseKey = "YOUR_ANON_KEY"

    static var isConfigured: Bool {
        !supabaseURL.contains("YOUR_PROJECT") && !supabaseKey.contains("YOUR_ANON_KEY")
    }
}

// MARK: - Local Auth Service (works offline)

@MainActor
final class LocalAuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: LocalUser?

    func signIn(email: String, password: String) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        // Accept any credentials in guest mode
        let user = LocalUser(id: UUID().uuidString, email: email)
        currentUser = user
        isAuthenticated = true
    }

    func signUp(email: String, password: String) async throws {
        try await Task.sleep(nanoseconds: 800_000_000)
        let user = LocalUser(id: UUID().uuidString, email: email)
        currentUser = user
        isAuthenticated = true
    }

    func signInWithMagicLink(email: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        // In guest mode, just show the banner
    }

    func signOut() {
        currentUser = nil
        isAuthenticated = false
    }
}

struct LocalUser: Identifiable, Sendable {
    let id: String
    let email: String
}
