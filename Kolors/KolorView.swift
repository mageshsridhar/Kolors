//
//  KolorView.swift
//  Kolors
//
//  Created by Magesh Sridhar on 3/30/21.
//

import SwiftUI
import CoreData

/// A saved palette.
struct KolorView: View {
    /// What's on screen, kept so that nothing disappears while a deleted palette's screen closes.
    private struct Snapshot {
        var name: String
        let image: UIImage?
        let colors: [RGBColor]
    }

    let kolor: Kolors

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var snapshot: Snapshot?
    @State private var showRename = false
    @State private var showDeleteConfirmation = false
    @State private var showDeleteError = false
    @State private var shared: SharedPalette?

    var body: some View {
        PaletteContent(image: snapshot?.image, colors: snapshot?.colors ?? [])
            .bottomDock {
                Button(action: share) {
                    Label("Share Palette", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(CapsuleButtonStyle(isPrimary: false))
                .disabled(snapshot?.colors.isEmpty != false)
            }
            .navigationTitle(snapshot?.name ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .tabBarHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { showRename = true } label: { Label("Rename", systemImage: "pencil") }
                        Button(role: .destructive) { showDeleteConfirmation = true } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis")
                    }
                }
            }
            .onAppear(perform: load)
            .sheet(isPresented: $showRename) {
                PaletteNameSheet(
                    title: "Rename Palette", colors: snapshot?.colors ?? [],
                    initialName: snapshot?.name ?? "", onSave: rename
                )
            }
            .sheet(item: $shared) { ShareSheet(items: $0.items) }
            .alert("Delete Palette?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive, action: delete)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This can't be undone.")
            }
            .alert("Couldn't Delete Palette", isPresented: $showDeleteError) {
                Button("Close", role: .cancel) {}
            } message: {
                Text("Your library hasn't changed. Please try again.")
            }
    }

    private func load() {
        guard snapshot == nil, !kolor.isDeleted, kolor.managedObjectContext != nil else { return }
        snapshot = Snapshot(
            name: kolor.displayName, image: kolor.image.flatMap(UIImage.init(data:)), colors: kolor.paletteColors
        )
    }

    private func share() {
        guard let snapshot = snapshot else { return }
        shared = SharedPalette(name: snapshot.name, image: snapshot.image, colors: snapshot.colors)
    }

    @MainActor
    private func rename(to name: String) async throws {
        kolor.paletteName = name
        try viewContext.saveOrRollback()
        snapshot?.name = name
    }

    private func delete() {
        viewContext.delete(kolor)
        do {
            try viewContext.saveOrRollback()
            dismiss()
        } catch {
            showDeleteError = true
        }
    }
}
