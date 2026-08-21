import SwiftUI

// MARK: - Save Session View (prompt after settling)

struct SaveSessionView: View {
    @EnvironmentObject var store: ChequeMateStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var showImagePicker = false
    @State private var pickedImages: [UIImage] = []
    @State private var asPending = false
    @State private var saved = false

    var body: some View {
        NavigationStack {
            ZStack {
                ChequeWave.paper.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        header
                        nameField
                        photoSection
                        saveToggle
                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Skip") { dismiss() }
                        .foregroundStyle(ChequeWave.inkSoft)
                        .font(.system(.callout, design: .rounded, weight: .bold))
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(images: $pickedImages)
            }
            .interactiveDismissDisabled(!saved)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(ChequeWave.blueprint.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(ChequeWave.blueprint)
            }
            .padding(.top, 8)

            Text("Save this sesh?")
                .font(.system(.title2, design: .rounded, weight: .black))
                .foregroundStyle(ChequeWave.ink)

            Text("\(store.people.count) people · \(store.expenses.count) expenses · \(store.money(store.totalSpent)) total")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(ChequeWave.inkSoft)
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NAME IT")
                .font(.system(.caption2, design: .rounded, weight: .black))
                .foregroundStyle(ChequeWave.blueprint)
                .tracking(1.2)

            TextField("e.g. Pizza Night, Goa Trip...", text: $name)
                .font(.system(.body, design: .rounded))
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: ChequeWave.ink.opacity(0.06), radius: 4, y: 2)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(ChequeWave.ink.opacity(0.08), lineWidth: 1)
                }
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PHOTOS")
                    .font(.system(.caption2, design: .rounded, weight: .black))
                    .foregroundStyle(ChequeWave.magenta)
                    .tracking(1.2)
                Spacer()
                if !pickedImages.isEmpty {
                    Text("\(pickedImages.count) selected")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(ChequeWave.inkSoft)
                }
            }

            Button {
                Haptics.tap()
                showImagePicker = true
            } label: {
                if pickedImages.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 32))
                            .foregroundStyle(ChequeWave.blueprint.opacity(0.5))
                        Text("Add photos from the sesh")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(ChequeWave.inkSoft)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                            .shadow(color: ChequeWave.ink.opacity(0.04), radius: 3, y: 1)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                            )
                            .foregroundStyle(ChequeWave.blueprint.opacity(0.25))
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(pickedImages.indices, id: \.self) { i in
                                imageThumb(pickedImages[i], index: i)
                            }
                            addMoreButton
                        }
                    }
                }
            }
        }
    }

    private func imageThumb(_ img: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Button {
                Haptics.tap()
                pickedImages.remove(at: index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            .offset(x: 6, y: -6)
        }
    }

    private var addMoreButton: some View {
        Button {
            Haptics.tap()
            showImagePicker = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(ChequeWave.blueprint.opacity(0.5))
                .frame(width: 90, height: 90)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ChequeWave.blueprint.opacity(0.06))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                        )
                        .foregroundStyle(ChequeWave.blueprint.opacity(0.2))
                }
        }
    }

    private var saveToggle: some View {
        VStack(spacing: 12) {
            toggleRow(
                icon: "clock.fill",
                iconColor: ChequeWave.magenta,
                title: "Pending",
                subtitle: "Not everyone paid yet — settle later",
                isOn: $asPending
            )

            toggleRow(
                icon: "checkmark.seal.fill",
                iconColor: Color(red: 0.18, green: 0.72, blue: 0.45),
                title: "History",
                subtitle: "All settled — save for memory",
                isOn: Binding(
                    get: { !asPending },
                    set: { asPending = !$0 }
                )
            )
        }
    }

    private func toggleRow(icon: String, iconColor: Color, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Button {
            Haptics.tap()
            isOn.wrappedValue.toggle()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(ChequeWave.ink)
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(ChequeWave.inkSoft)
                }

                Spacer()

                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isOn.wrappedValue ? iconColor : ChequeWave.inkSoft.opacity(0.3))
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: ChequeWave.ink.opacity(0.04), radius: 3, y: 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isOn.wrappedValue ? iconColor.opacity(0.3) : Color.clear,
                        lineWidth: 1.5
                    )
            }
        }
    }

    private var saveButton: some View {
        Button {
            Haptics.heavy()
            saveSession()
        } label: {
            Text(saved ? "Saved!" : "Save Sesh")
                .font(.system(.headline, design: .rounded, weight: .black))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            saved
                            ? LinearGradient(colors: [Color(red: 0.18, green: 0.72, blue: 0.45)], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [ChequeWave.blueprint, ChequeWave.blueprint.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                        .shadow(color: ChequeWave.blueprint.opacity(0.25), radius: 10, y: 4)
                }
        }
        .disabled(saved || name.trimmingCharacters(in: .whitespaces).isEmpty)
        .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty && !saved ? 0.5 : 1)
        .padding(.top, 8)
    }

    private func saveSession() {
        let imageData = pickedImages.compactMap { $0.jpegData(compressionQuality: 0.7) }
        let session = Session(
            name: name.trimmingCharacters(in: .whitespaces),
            date: Date(),
            people: store.people,
            expenses: store.expenses,
            settlements: store.settlements,
            currency: store.currency,
            imageData: imageData,
            isPending: asPending
        )
        store.saveSession(session)
        saved = true
        Haptics.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }
}
