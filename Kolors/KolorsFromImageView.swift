//
//  KolorsFromImageView.swift
//  Kolors
//
//  Created by Magesh Sridhar on 3/30/21.
//

import SwiftUI
import CoreData

/// A new palette, extracted from a photo.
struct KolorsFromImageView: View {
    private struct Photo {
        let id = UUID()
        let image: UIImage
    }

    @Environment(\.managedObjectContext) private var viewContext
    @State private var photo: Photo
    /// `nil` until extraction finishes.
    @State private var colors: [RGBColor]?
    @State private var extractedID: UUID?
    @State private var isSaved = false
    @State private var source: PhotoSource?
    @State private var showSaveSheet = false
    @State private var shared: SharedPalette?

    init(image: UIImage) {
        _photo = State(initialValue: Photo(image: image))
    }

    private var hasColors: Bool { colors?.isEmpty == false }

    var body: some View {
        PaletteContent(image: photo.image, colors: colors, onReplace: { source = $0 })
            .bottomDock {
                Button { showSaveSheet = true } label: {
                    if isSaved {
                        Label("Saved to Library", systemImage: "checkmark")
                    } else {
                        Text("Save Palette")
                    }
                }
                .buttonStyle(CapsuleButtonStyle())
                .disabled(isSaved || !hasColors)
            }
            .navigationTitle("New Palette")
            .navigationBarTitleDisplayMode(.inline)
            .tabBarHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: share) {
                        Label("Share palette", systemImage: "square.and.arrow.up")
                    }
                    .disabled(!hasColors)
                }
            }
            .task(id: photo.id) { await extractColors() }
            .photoPicker(source: $source) { picked in
                colors = nil
                isSaved = false
                photo = Photo(image: picked)
            }
            .sheet(isPresented: $showSaveSheet) {
                PaletteNameSheet(
                    title: "Save Palette", colors: colors ?? [],
                    initialName: Kolors.suggestedName(in: viewContext), onSave: save
                )
            }
            .sheet(item: $shared) { ShareSheet(items: $0.items) }
    }

    private func share() {
        shared = SharedPalette(name: "Color palette", image: photo.image, colors: colors ?? [])
    }

    @MainActor
    private func extractColors() async {
        let photo = self.photo
        // The task also runs when the screen reappears.
        guard extractedID != photo.id else { return }
        let palette = await Task.detached(priority: .userInitiated) {
            PaletteExtractor.palette(from: photo.image)
        }.value
        guard !Task.isCancelled else { return }
        extractedID = photo.id
        colors = palette
    }

    @MainActor
    private func save(name: String) async throws {
        let image = photo.image
        let palette = colors ?? []
        let encoded = await Task.detached(priority: .userInitiated) {
            (full: ImageProcessing.storedImageData(from: image), thumbnail: ImageProcessing.thumbnailData(from: image))
        }.value
        guard let imageData = encoded.full else { throw CocoaError(.fileWriteUnknown) }
        Kolors.insert(
            name: name, palette: palette, imageData: imageData, thumbnailData: encoded.thumbnail, into: viewContext
        )
        try viewContext.saveOrRollback()
        isSaved = true
    }
}

struct KolorsFromImageView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            KolorsFromImageView(image: UIImage(named: "Image") ?? UIImage())
        }
        .environment(\.managedObjectContext, PersistenceController(inMemory: true).container.viewContext)
    }
}
