//
//  KolorsView.swift
//  Kolors
//
//  Created by Magesh Sridhar on 3/29/21.
//

import SwiftUI
import CoreData

/// The Library tab.
struct KolorsView: View {
    var onCreate: () -> Void = {}

    @FetchRequest(sortDescriptors: Kolors.librarySort, animation: .default)
    private var kolors: FetchedResults<Kolors>
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showDeleteError = false

    var body: some View {
        NavigationView {
            Group {
                if kolors.isEmpty {
                    EmptyLibrary(onCreate: onCreate)
                } else {
                    list
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Library")
            .alert("Couldn't Delete Palette", isPresented: $showDeleteError) {
                Button("Close", role: .cancel) {}
            } message: {
                Text("Your library hasn't changed. Please try again.")
            }
        }
        .navigationViewStyle(.stack)
    }

    private var list: some View {
        List {
            ForEach(kolors) { kolor in
                PaletteCard(kolor: kolor)
                    // Keeps the card tappable without the list's disclosure arrow.
                    .background(
                        NavigationLink(destination: KolorView(kolor: kolor)) { EmptyView() }
                            .opacity(0)
                            .accessibilityHidden(true)
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Theme.background)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
            .onDelete(perform: delete)
        }
        .listStyle(.plain)
        .clearListBackground()
    }

    private func delete(offsets: IndexSet) {
        offsets.map { kolors[$0] }.forEach(viewContext.delete)
        do {
            try viewContext.saveOrRollback()
        } catch {
            showDeleteError = true
        }
    }
}

private struct PaletteCard: View {
    @ObservedObject var kolor: Kolors

    var body: some View {
        let colors = kolor.paletteColors
        VStack(spacing: 0) {
            PaletteStrip(colors: colors).frame(height: 64)
            HStack(spacing: 12) {
                Group {
                    if let thumbnail = kolor.thumbnail.flatMap(UIImage.init(data:)) {
                        Image(uiImage: thumbnail).resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "photo").foregroundColor(Theme.secondaryText)
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(kolor.displayName).font(.headline)
                    Text(colors.countLabel).font(.subheadline).foregroundColor(Theme.secondaryText)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement()
        .accessibilityLabel("\(kolor.displayName), \(colors.countLabel)")
        .accessibilityAddTraits(.isButton)
    }
}

private struct EmptyLibrary: View {
    let onCreate: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    Theme.fill
                    Theme.card
                    Theme.fill
                }
                .frame(width: 150, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.bottom, 16)
                .accessibilityHidden(true)
                Text("No palettes yet").font(.title2.bold())
                Text("Palettes you save will appear here.").foregroundColor(Theme.secondaryText)
                Button("Create a Palette", action: onCreate)
                    .buttonStyle(CapsuleButtonStyle())
                    .padding(.top, 14)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)
            .padding(.top, 96)
        }
    }
}

private extension View {
    @ViewBuilder func clearListBackground() -> some View {
        if #available(iOS 16, *) {
            scrollContentBackground(.hidden)
        } else {
            self
        }
    }
}

struct KolorsView_Previews: PreviewProvider {
    static let persistence: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        Kolors.insert(
            name: "Sunset", palette: SampleArtwork.palette, imageData: nil, thumbnailData: nil,
            into: controller.container.viewContext
        )
        return controller
    }()

    static var previews: some View {
        KolorsView().environment(\.managedObjectContext, persistence.container.viewContext)
    }
}
