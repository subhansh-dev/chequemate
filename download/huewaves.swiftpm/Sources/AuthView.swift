import SwiftUI
import Supabase

// MARK: - Auth View Model

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showCheckEmail = false

    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Fill in all fields"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabase.auth.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Fill in all fields"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await supabase.auth.signUp(email: email, password: password)
            if response.user != nil {
                showCheckEmail = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signInWithMagicLink() async {
        guard !email.isEmpty else {
            errorMessage = "Enter your email"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabase.auth.signInWithOTP(
                email: email,
                redirectTo: URL(string: "huewaves://auth-callback")
            )
            showCheckEmail = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        try? await supabase.auth.signOut()
    }
}

// MARK: - Auth View

struct AuthView: View {
    @StateObject private var vm = AuthViewModel()
    @State private var isSignUp = false
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    var body: some View {
        ZStack {
            MeshBackground()

            ScrollView {
                VStack(spacing: 32) {
                    header
                    toggle
                    form
                    actionButton
                    if vm.showCheckEmail { checkEmailBanner }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 40)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(HueWave.surface)
                    .frame(width: 80, height: 80)
                    .overlay(Circle().strokeBorder(HueWave.teal.opacity(0.3), lineWidth: 2))
                Image(systemName: "waveform")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(HueWave.teal)
            }

            VStack(spacing: 8) {
                Text("Huewaves")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(HueWave.ink)
                Text(isSignUp ? "Create your account" : "Welcome back")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(HueWave.inkSoft)
            }
        }
    }

    private var toggle: some View {
        HStack(spacing: 0) {
            tab(title: "Sign In", isSelected: !isSignUp) {
                withAnimation(.spring(response: 0.3)) { isSignUp = false }
            }
            tab(title: "Sign Up", isSelected: isSignUp) {
                withAnimation(.spring(response: 0.3)) { isSignUp = true }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(HueWave.surface)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(HueWave.line, lineWidth: 1))
        )
    }

    private func tab(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isSelected ? HueWave.bg : HueWave.inkSoft)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? HueWave.teal : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    private var form: some View {
        VStack(spacing: 16) {
            GlassTextField(placeholder: "Email", text: $vm.email, icon: "envelope", keyboardType: .emailAddress)
                .focused($focusedField, equals: .email)

            GlassTextField(placeholder: "Password", text: $vm.password, icon: "lock", isSecure: true)
                .focused($focusedField, equals: .password)

            if let error = vm.errorMessage {
                Text(error)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(HueWave.rose)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var actionButton: some View {
        VStack(spacing: 12) {
            GlassButton(
                title: isSignUp ? "Create Account" : "Sign In",
                icon: isSignUp ? "person.badge.plus" : "arrow.right",
                action: {
                    Task {
                        if isSignUp { await vm.signUp() } else { await vm.signIn() }
                    }
                },
                isLoading: vm.isLoading
            )

            Button {
                Task { await vm.signInWithMagicLink() }
            } label: {
                Text("Sign in with magic link")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(HueWave.inkSoft)
            }
            .disabled(vm.isLoading)
        }
    }

    private var checkEmailBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "envelope.badge")
                .foregroundStyle(HueWave.teal)
            Text("Check your email for a confirmation link")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(HueWave.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(HueWave.teal.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(HueWave.teal.opacity(0.2), lineWidth: 1))
        )
    }
}
