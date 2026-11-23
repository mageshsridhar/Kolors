//
//  LibraryView.swift
//  Kolors
//
//  Created by Magesh Sridhar on 3/29/21.
//

import SwiftUI
import CoreData

/// Saved palettes, newest first, each a full-width photo above its colors.
struct LibraryView: View {
    @FetchRequest(sortDescriptors: Kolors.librarySort, animation: .default)
    private var kolors: FetchedResults<Kolors>
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Namespace private var zoom
    @State private var isVisible = false
    @State private var renaming: Kolors?
    @State private var deleting: Kolors?
    @State private var shared: SharedPalette?
    @State private var showDeleteError = false
    /// The top of the first photo, which sits under the status bar.
    @State private var topTone = PhotoTone.dark

    var body: some View {
        GeometryReader { proxy in
            list.edgeToEdgeSides(proxy)
        }
        .overlay(statusBarScrim, alignment: .top)
        .background(Theme.background.ignoresSafeArea())
        .photoScreen(title: "Library", lightStatusBar: topTone == .dark)
        .onAppear {
            isVisible = true
            closeIfEmpty()
        }
        .onDisappear { isVisible = false }
        .onChange(of: kolors.isEmpty) { _ in closeIfEmpty() }
        .sheet(item: $renaming) { kolor in
            PaletteNameSheet(
                title: "Rename Palette", colors: kolor.paletteColors, initialName: kolor.displayName
            ) { name in
                kolor.paletteName = name
                try viewContext.saveOrRollback()
            }
        }
        .sheet(item: $shared) { ShareSheet(items: $0.items) }
        .alert("Delete Palette?", isPresented: isDeleting, presenting: deleting) { kolor in
            Button("Delete", role: .destructive) { delete(kolor) }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("This can't be undone.")
        }
        .alert("Couldn't Delete Palette", isPresented: $showDeleteError) {
            Button("Close", role: .cancel) {}
        } message: {
            Text("Your library hasn't changed. Please try again.")
        }
    }

    private var list: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(Array(kolors.enumerated()), id: \.element.objectID) { index, kolor in
                    NavigationLink(destination: SavedPaletteView(kolor: kolor, zoom: zoom)) {
                        LibraryRow(kolor: kolor, isFirst: index == 0) { tone in
                            if index == 0 { topTone = tone }
                        }
                    }
                    .buttonStyle(.plain)
                    .zoomSource(id: kolor.objectID, in: zoom)
                    .contextMenu { menu(for: kolor) }
                }
            }
        }
        .noTopScrollEdgeEffect()
        .ignoresSafeArea(edges: [.top, .horizontal])
    }

    private var statusBarScrim: some View {
        GeometryReader { proxy in
            topTone.scrim(fromTop: true)
                .frame(height: proxy.safeAreaInsets.top + 60)
                .ignoresSafeArea(edges: [.top, .horizontal])
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder private func menu(for kolor: Kolors) -> some View {
        Button { renaming = kolor } label: { Label("Rename", systemImage: "pencil") }
        Button { share(kolor) } label: { Label("Share", systemImage: "square.and.arrow.up") }
        Button(role: .destructive) { deleting = kolor } label: { Label("Delete", systemImage: "trash") }
    }

    private var isDeleting: Binding<Bool> {
        Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })
    }

    /// The library is only reachable while it has palettes, so leave once the last one is deleted.
    private func closeIfEmpty() {
        if isVisible, kolors.isEmpty { dismiss() }
    }

    private func share(_ kolor: Kolors) {
        let image = kolor.image.flatMap(UIImage.init(data:))
        shared = SharedPalette(name: kolor.displayName, image: image, colors: kolor.paletteColors)
    }

    private func delete(_ kolor: Kolors) {
        viewContext.delete(kolor)
        do {
            try viewContext.saveOrRollback()
        } catch {
            showDeleteError = true
        }
    }
}

private struct LibraryRow: View {
    @ObservedObject var kolor: Kolors
    let isFirst: Bool
    /// Reports the tone of the top of the photo once it has loaded.
    let onTopTone: (PhotoTone) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var photo: LoadedPhoto?

    var body: some View {
        VStack(spacing: 0) {
            Color.black
                .frame(height: photoHeight)
                .overlay(image)
                .clipped()
                .overlay(name, alignment: .bottomLeading)
            PaletteStrip(colors: kolor.paletteColors)
                .frame(height: 52)
                // Keeps a white or near-white palette from disappearing into the page.
                .overlay(Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1), alignment: .bottom)
        }
        .contentShape(Rectangle())
        .accessibilityElement()
        .accessibilityLabel("\(kolor.displayName), \(kolor.paletteColors.countLabel)")
        .accessibilityAddTraits(.isButton)
        .task(id: kolor.objectID) { await load() }
    }

    /// The first row also sits under the status bar.
    private var photoHeight: CGFloat {
        (typeSize.isAccessibilitySize ? 270 : 198) + (isFirst ? 76 : 0)
    }

    @ViewBuilder private var image: some View {
        if let photo = photo {
            Image(uiImage: photo.image).resizable().aspectRatio(contentMode: .fill)
        } else if let thumbnail = kolor.thumbnail.flatMap(UIImage.init(data:)) {
            Image(uiImage: thumbnail).resizable().aspectRatio(contentMode: .fill).blur(radius: 6)
        }
    }

    private var name: some View {
        let tone = photo?.bottomTone ?? .dark
        return PhotoNameLabel(name: kolor.displayName, tone: tone, size: 26, style: .title)
            .sidePadding(20)
            .padding(.top, 40)
            .padding(.bottom, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tone.scrim(fromTop: false))
    }

    /// Loads the photo at screen size off the main thread.
    private func load() async {
        let key = kolor.objectID.uriRepresentation() as NSURL
        if let cached = LoadedPhoto.cache.object(forKey: key) {
            show(cached)
            return
        }
        guard let data = kolor.image else { return }
        let loaded = await Task.detached(priority: .userInitiated) {
            ImageProcessing.downsampled(data, maxPixels: 1200).map(LoadedPhoto.init)
        }.value
        if let loaded = loaded {
            LoadedPhoto.cache.setObject(loaded, forKey: key)
            show(loaded)
        }
    }

    private func show(_ loaded: LoadedPhoto) {
        photo = loaded
        onTopTone(loaded.topTone)
    }
}

private final class LoadedPhoto {
    static let cache: NSCache<NSURL, LoadedPhoto> = {
        let cache = NSCache<NSURL, LoadedPhoto>()
        cache.countLimit = 30
        return cache
    }()

    let image: UIImage
    let topTone: PhotoTone
    let bottomTone: PhotoTone

    init(image: UIImage) {
        self.image = image
        topTone = PhotoTone.of(image, top: true)
        bottomTone = PhotoTone.of(image, top: false)
    }
}

struct LibraryView_Previews: PreviewProvider {
    static let persistence: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        Kolors.insert(
            name: "Sunset", palette: SampleArtwork.palette, imageData: nil, thumbnailData: nil,
            into: controller.container.viewContext
        )
        return controller
    }()

    static var previews: some View {
        NavigationContainer { LibraryView() }
            .environment(\.managedObjectContext, persistence.container.viewContext)
    }
}
