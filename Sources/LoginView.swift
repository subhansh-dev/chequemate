import SwiftUI

// MARK: - Login View — Neo Poster / Zine

struct LoginView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var email = ""
    @State private var password = ""
    @State private var cardAppeared = false
    @State private var tiltX: CGFloat = 0
    @State private var tiltY: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var iconRotation: Double = 0
    @State private var glowScale: CGFloat = 1.0
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    var body: some View {
        ZStack {
            ChequeWave.paper.ignoresSafeArea()

            // Paper grain texture
            Canvas { ctx, size in
                let seed: UInt64 = 0x9E3779B97F4A7C15
                var rng = SeededRNG(seed: seed)
                for _ in 0..<1200 {
                    let x = CGFloat.random(in: 0..<size.width, using: &rng)
                    let y = CGFloat.random(in: 0..<size.height, using: &rng)
                    let r: CGFloat = CGFloat.random(in: 0.2...0.6, using: &rng)
                    let a = Double.random(in: 0.03...0.08, using: &rng)
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(.black.opacity(a)))
                }
            }
            .opacity(0.4)
            .ignoresSafeArea()

            // Blueprint grid background
            Canvas { ctx, size in
                let step: CGFloat = 22
                let line = Path { p in
                    var x: CGFloat = 0
                    while x < size.width {
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: size.height))
                        x += step
                    }
                    var y: CGFloat = 0
                    while y < size.height {
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: size.width, y: y))
                        y += step
                    }
                }
                ctx.stroke(line, with: .color(ChequeWave.blueprint.opacity(0.04)), lineWidth: 0.5)
            }
            .ignoresSafeArea()

            // Floating kanji
            FloatingKanji(text: "精算")

            // Halftone corner decoration
            VStack {
                HStack {
                    HalftoneDots(color: ChequeWave.blueprint.opacity(0.06))
                        .frame(width: 140, height: 100)
                        .clipShape(Rectangle())
                    Spacer()
                }
                Spacer()
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    // Logo area
                    logoSection

                    Spacer().frame(height: 40)

                    // Login card with 3D tilt
                    loginCard
                        .rotation3DEffect(.degrees(Double(tiltY * 2)), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
                        .rotation3DEffect(.degrees(Double(tiltX * 2)), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let maxTilt: CGFloat = 4
                                    tiltX = min(max(value.translation.width / 40, -maxTilt), maxTilt)
                                    tiltY = min(max(-value.translation.height / 40, -maxTilt), maxTilt)
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.4)) {
                                        tiltX = 0
                                        tiltY = 0
                                    }
                                }
                        )

                    Spacer().frame(height: 24)

                    // Guest mode
                    guestButton

                    Spacer().frame(height: 40)

                    // Barcode footer
                    loginBarcode
                        .padding(.horizontal, 20)

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                cardAppeared = true
            }
            // Shimmer sweep
            withAnimation(.linear(duration: 1.5).delay(0.8)) {
                shimmerOffset = 600
            }
        }
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: 12) {
            // Shield icon with pulsing glow rings
            ZStack {
                // Glow ring 1
                Circle()
                    .stroke(ChequeWave.blueprint.opacity(0.15), lineWidth: 1.5)
                    .frame(width: 90, height: 90)
                    .scaleEffect(glowScale)
                    .opacity(2.0 - glowScale)

                // Glow ring 2
                Circle()
                    .stroke(ChequeWave.blueprint.opacity(0.08), lineWidth: 1)
                    .frame(width: 110, height: 110)
                    .scaleEffect(glowScale * 1.1)
                    .opacity(1.5 - glowScale)

                // Glow ring 3
                Circle()
                    .stroke(ChequeWave.magenta.opacity(0.06), lineWidth: 0.8)
                    .frame(width: 130, height: 130)
                    .scaleEffect(glowScale * 1.2)
                    .opacity(1.0 - glowScale * 0.8)

                // Shield icon with slow 3D rotation
                ZStack {
                    Rectangle()
                        .fill(ChequeWave.blueprint)
                        .frame(width: 64, height: 64)
                    Image(systemName: "checkerboard.shield")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(.white)
                }
                .overlay { Rectangle().strokeBorder(ChequeWave.ink, lineWidth: 1.4) }
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                .rotation3DEffect(.degrees(iconRotation), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            }

            VStack(spacing: 4) {
                Text("CHEQUEMATE")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .tracking(-0.5)
                    .foregroundStyle(ChequeWave.ink)

                HStack(spacing: 6) {
                    Rectangle().fill(ChequeWave.magenta).frame(width: 20, height: 2)
                    Text("精算ポスター")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(ChequeWave.blueprint)
                    Rectangle().fill(ChequeWave.magenta).frame(width: 20, height: 2)
                }
            }
            .opacity(cardAppeared ? 1 : 0)
            .offset(y: cardAppeared ? 0 : 10)
        }
        .onAppear {
            // Slow 3D rotation
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                iconRotation = 360
            }
            // Pulsing glow
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowScale = 1.15
            }
        }
    }

    // MARK: - Login Card

    private var loginCard: some View {
        ZStack(alignment: .topLeading) {
            // Shimmer overlay
            LinearGradient(
                colors: [.clear, .white.opacity(0.4), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 300, height: 400)
            .offset(x: shimmerOffset, y: -100)
            .rotationEffect(.degrees(25))
            .clipped()
            .allowsHitTesting(false)

            PosterCard(accent: ChequeWave.blueprint) {
                VStack(alignment: .leading, spacing: 20) {
                    // Card header
                    HStack(spacing: 8) {
                        BigNumber(n: "00")
                        VStack(alignment: .leading, spacing: 1) {
                            Text("SIGN IN")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(ChequeWave.ink)
                            Text("ACCOUNT ACCESS")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .tracking(1)
                                .foregroundStyle(ChequeWave.blueprint)
                        }
                        Spacer()
                        KanjiSide(text: "ログイン")
                    }

                    Rule(color: ChequeWave.blueprint.opacity(0.2))

                    // Email field
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Rectangle().fill(ChequeWave.blueprint).frame(width: 12, height: 12)
                            Text("EMAIL")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .tracking(1)
                                .foregroundStyle(ChequeWave.ink)
                        }
                        posterTextField(
                            text: $email,
                            placeholder: "you@email.com",
                            icon: "envelope.fill",
                            isFocused: focusedField == .email
                        )
                        .focused($focusedField, equals: .email)
                    }

                    // Password field
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Rectangle().fill(ChequeWave.magenta).frame(width: 12, height: 12)
                            Text("PASSWORD")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .tracking(1)
                                .foregroundStyle(ChequeWave.ink)
                        }
                        posterTextField(
                            text: $password,
                            placeholder: "••••••••",
                            icon: "lock.fill",
                            isFocused: focusedField == .password
                        )
                        .focused($focusedField, equals: .password)
                    }

                    // Sign in button
                    GlassButton(title: "Sign In", icon: "arrow.right") {
                        Haptics.tap()
                        isLoggedIn = true
                    }

                    // Create account
                    GlassButton(title: "Create Account", icon: "person.badge.plus", variant: .secondary) {
                        Haptics.tap()
                        isLoggedIn = true
                    }
                }
            }
        }
        .opacity(cardAppeared ? 1 : 0)
        .offset(y: cardAppeared ? 0 : 30)
    }

    // MARK: - Poster Text Field

    private func posterTextField(text: Binding<String>, placeholder: String, icon: String, isFocused: Bool) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Rectangle().fill(isFocused ? ChequeWave.blueprint : Color.black.opacity(0.06))
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isFocused ? .white : ChequeWave.inkFaint)
            }
            .frame(width: 28, height: 28)

            TextField("", text: text, prompt: Text(placeholder).foregroundStyle(ChequeWave.inkFaint))
                .keyboardType(icon == "envelope.fill" ? .emailAddress : .default)
                .textContentType(icon == "lock.fill" ? .password : .emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .font(.system(.callout, design: .rounded, weight: .medium))
        .foregroundStyle(ChequeWave.ink)
        .frame(height: 46)
        .padding(.horizontal, 12)
        .background { Rectangle().fill(Color.white) }
        .overlay {
            Rectangle().strokeBorder(
                isFocused ? ChequeWave.blueprint : ChequeWave.ink,
                lineWidth: isFocused ? 1.6 : 1.2
            )
        }
        .animation(HueMotion.spring, value: isFocused)
    }

    // MARK: - Guest Button

    private var guestButton: some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.4)) {
                isLoggedIn = true
            }
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(ChequeWave.magenta.opacity(0.12))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "person.fill.questionmark")
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(ChequeWave.magenta)
                        }
                        .overlay { Rectangle().strokeBorder(ChequeWave.magenta, lineWidth: 1) }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("GUEST MODE")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .tracking(0.8)
                            .foregroundStyle(ChequeWave.ink)
                        Text("No login required — test immediately")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(ChequeWave.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(ChequeWave.magenta)
                }
                .padding(14)
                .background { Rectangle().fill(Color.white) }
                .overlay {
                    AnimatedDashedBorder(color: ChequeWave.magenta, cornerRadius: 0, lineWidth: 1.2)
                }
            }
        }
        .buttonStyle(.plain)
        .opacity(cardAppeared ? 1 : 0)
        .offset(y: cardAppeared ? 0 : 20)
    }

    // MARK: - Barcode Footer

    private var loginBarcode: some View {
        VStack(spacing: 6) {
            HStack(spacing: 2) {
                ForEach(0..<30, id: \.self) { _ in
                    Rectangle()
                        .fill(ChequeWave.ink)
                        .frame(width: CGFloat.random(in: 1...2.5), height: 14)
                }
            }
            HStack {
                Text("CHEQUEMATE v1.0 — NO DATA LEAVES YOUR PHONE")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(ChequeWave.inkFaint)
                Spacer()
                Text("©2026")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(ChequeWave.inkFaint)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background { Rectangle().fill(Color.white) }
        .overlay { Rectangle().strokeBorder(ChequeWave.ink.opacity(0.12), lineWidth: 0.7) }
    }
}
