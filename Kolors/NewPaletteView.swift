//
//  NewPaletteView.swift
//  Kolors
//
//  Created by Magesh Sridhar on 3/30/21.
//

import SwiftUI
import CoreData

/// A new palette, extracted from a photo.
struct NewPaletteView: View {
    let image: UIImage

    @Environment(\.managedObjectContext) private var viewContext
    /// `nil` until extraction finishes.
    @State private var colors: [RGBColor]?
    @State private var savedName: String?
    @State private var showSaveSheet = false
    @State private var shared: SharedPalette?

    private var hasColors: Bool { colors?.isEmpty == false }

    var body: some View {
        PaletteContent(title: savedName ?? "New Palette", image: image, colors: colors, name: savedName)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: share) {
                        BarIcon(title: "Share palette", systemImage: "square.and.arrow.up")
                    }
                    .disabled(!hasColors)
                    saveButton
                }
            }
            .task { await extractColors() }
            .sheet(isPresented: $showSaveSheet) {
                PaletteNameSheet(
                    title: "Save Palette", colors: colors ?? [],
                    initialName: Kolors.suggestedName(in: viewContext), onSave: save
                )
            }
            .sheet(item: $shared) { ShareSheet(items: $0.items) }
    }

    @ViewBuilder private var saveButton: some View {
        let isSaved = savedName != nil
        // Not a Label: toolbars show only a label's icon.
        let button = Button { showSaveSheet = true } label: {
            HStack(spacing: 6) {
                if isSaved {
                    Image(systemName: "checkmark")
                }
                Text(isSaved ? "Saved" : "Save")
            }
            .font(.geistButton)
            .modifier(SaveLabelColor(isSaved: isSaved))
        }
        .disabled(isSaved || !hasColors)
        if #available(iOS 26, *) {
            button
                .buttonStyle(.glassProminent)
                .tint(isSaved ? .clear : .accentColor)
        } else {
            button.buttonStyle(BarTextButtonStyle())
        }
    }

    private func share() {
        shared = SharedPalette(name: savedName ?? "Color palette", image: image, colors: colors ?? [])
    }

    @MainActor
    private func extractColors() async {
        // The task also runs when the screen reappears.
        guard colors == nil else { return }
        let image = self.image
        let palette = await Task.detached(priority: .userInitiated) {
            PaletteExtractor.palette(from: image)
        }.value
        guard !Task.isCancelled else { return }
        colors = palette
    }

    @MainActor
    private func save(name: String) async throws {
        let image = self.image
        let palette = colors ?? []
        let encoded = await Task.detached(priority: .userInitiated) {
            (full: ImageProcessing.storedImageData(from: image), thumbnail: ImageProcessing.thumbnailData(from: image))
        }.value
        guard let imageData = encoded.full else { throw CocoaError(.fileWriteUnknown) }
        Kolors.insert(
            name: name, palette: palette, imageData: imageData, thumbnailData: encoded.thumbnail, into: viewContext
        )
        try viewContext.saveOrRollback()
        savedName = name
    }
}

/// Set on the label itself, because iOS 26's toolbar overrides a color set on the button.
private struct SaveLabelColor: ViewModifier {
    let isSaved: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.foregroundStyle(isSaved ? Color.primary : Color(.systemBackground))
        } else {
            content
        }
    }
}

struct NewPaletteView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationContainer {
            NewPaletteView(image: UIImage(named: "Image") ?? UIImage())
        }
        .environment(\.managedObjectContext, PersistenceController(inMemory: true).container.viewContext)
    }
}
