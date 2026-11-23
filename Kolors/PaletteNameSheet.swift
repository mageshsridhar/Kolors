import SwiftUI

/// Names a palette when saving or renaming it.
struct PaletteNameSheet: View {
    let title: String
    let colors: [RGBColor]
    let initialName: String
    let onSave: (String) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var name = ""
    @State private var isSaving = false
    @State private var showError = false
    @FocusState private var isFocused: Bool

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty && !isSaving }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    Text(title)
                        .font(.geist(.semibold, size: 24, relativeTo: .title2))
                        .tracking(-0.7)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Theme.fill))
                    }
                    .accessibilityLabel("Close")
                }
                PaletteStrip(colors: colors)
                    .frame(height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                HStack {
                    TextField("Palette name", text: $name)
                        .font(.geist(.medium, size: 19, relativeTo: .body))
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit(save)
                    if !name.isEmpty {
                        Button { name = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Theme.secondaryText)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Clear name")
                    }
                }
                .padding(.leading, 16)
                .frame(minHeight: 58)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.fill))
                Button("Save", action: save)
                    .buttonStyle(CapsuleButtonStyle())
                    .disabled(!canSave)
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .compactSheet(isCompact: !typeSize.isAccessibilitySize)
        .interactiveDismissDisabled(isSaving)
        .onAppear {
            name = initialName
            // Focus is ignored until the sheet has finished appearing.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isFocused = true }
        }
        .alert("Couldn't Save Palette", isPresented: $showError) {
            Button("Close", role: .cancel) {}
        } message: {
            Text("Your library hasn't changed. Please try again.")
        }
    }

    private func save() {
        guard canSave else { return }
        isSaving = true
        Task { @MainActor in
            defer { isSaving = false }
            do {
                try await onSave(trimmedName)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                UIAccessibility.post(notification: .announcement, argument: "Saved \(trimmedName)")
                dismiss()
            } catch {
                showError = true
            }
        }
    }
}

private extension View {
    @ViewBuilder func compactSheet(isCompact: Bool) -> some View {
        if #available(iOS 16, *) {
            presentationDetents([isCompact ? .height(300) : .large])
        } else {
            self
        }
    }
}
