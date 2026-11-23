//
//  HomeView.swift
//  Kolors
//
//  Created by Magesh Sridhar on 3/29/21.
//

import SwiftUI
import CoreData

/// The first screen: pick a photo to get its palette, or open the library.
struct HomeView: View {
    @FetchRequest private var newest: FetchedResults<Kolors>
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var source: PhotoSource?
    @State private var image: UIImage?
    @State private var showPalette = false
    @State private var showLibrary = false

    init() {
        let request = NSFetchRequest<Kolors>(entityName: "Kolors")
        request.sortDescriptors = Kolors.librarySort
        request.fetchLimit = 3
        _newest = FetchRequest(fetchRequest: request, animation: .default)
    }

    /// Very large text, or a short landscape screen, doesn't fit without scrolling.
    private var scrolls: Bool { typeSize.isAccessibilitySize || verticalSizeClass == .compact }

    var body: some View {
        GeometryReader { proxy in
            layout(screenHeight: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom)
                .edgeToEdgeSides(proxy)
        }
        .background(Theme.background.ignoresSafeArea())
        .background(links)
        .photoScreen(title: "Kolors", lightStatusBar: false)
        .photoPicker(source: $source) { picked in
            image = picked
            showPalette = true
        }
    }

    @ViewBuilder private func layout(screenHeight: CGFloat) -> some View {
        Group {
            if scrolls {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        artwork.frame(height: 300)
                        heading
                        photoButtons.sidePadding(20).padding(.top, 28).padding(.bottom, 12)
                    }
                }
                .noTopScrollEdgeEffect()
            } else {
                VStack(spacing: 0) {
                    // A set share of the screen, taller with no Library row. It gives up height first
                    // when the text and buttons need it, as on small screens.
                    artwork.frame(minHeight: 160, maxHeight: screenHeight * (newest.isEmpty ? 0.62 : 0.57))
                    heading
                    Spacer(minLength: 28)
                    photoButtons.sidePadding(20).padding(.bottom, 12)
                }
            }
        }
        .ignoresSafeArea(edges: [.top, .horizontal])
    }

    private var artwork: some View {
        VStack(spacing: 0) {
            SampleArtwork()
            PaletteStrip(colors: SampleArtwork.palette).frame(height: 84)
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Separate lines, because line spacing can't be tightened below the font's own.
            VStack(alignment: .leading, spacing: -6) {
                Text("Color from").tracking(-1.6)
                Text("any photo").tracking(-1.6)
            }
            .font(.geist(.semibold, size: 40, relativeTo: .largeTitle))
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            if !newest.isEmpty {
                libraryButton.padding(.top, 22)
            }
        }
        .sidePadding(20)
        .padding(.top, 28)
    }

    private var libraryButton: some View {
        Button { showLibrary = true } label: {
            HStack(spacing: 12) {
                Text("Library").font(.geist(.medium, size: 17, relativeTo: .body))
                Spacer(minLength: 0)
                if !typeSize.isAccessibilitySize {
                    ForEach(newest) { kolor in
                        PaletteStrip(colors: kolor.paletteColors)
                            .frame(width: 50, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.secondaryText)
            }
            .padding(.leading, 20)
            .padding(.trailing, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 60)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.fill))
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Library")
        .accessibilityHint("Your saved palettes")
    }

    @ViewBuilder private var photoButtons: some View {
        if typeSize.isAccessibilitySize {
            VStack(spacing: 10) {
                Button("Choose Photo") { source = .library }
                    .buttonStyle(CapsuleButtonStyle())
                if PhotoSource.isCameraAvailable {
                    Button("Take Photo") { source = .camera }
                        .buttonStyle(CapsuleButtonStyle(isPrimary: false))
                }
            }
        } else {
            HStack(spacing: 10) {
                Button { source = .library } label: {
                    Label("Choose Photo", systemImage: "photo")
                }
                .buttonStyle(CapsuleButtonStyle())
                if PhotoSource.isCameraAvailable {
                    Button { source = .camera } label: {
                        Image(systemName: "camera")
                    }
                    .buttonStyle(CircleButtonStyle())
                    .accessibilityLabel("Take Photo")
                }
            }
        }
    }

    private var links: some View {
        ZStack {
            NavigationLink(isActive: $showPalette) {
                if let image = image {
                    NewPaletteView(image: image)
                }
            } label: {
                EmptyView()
            }
            NavigationLink(isActive: $showLibrary) {
                LibraryView()
            } label: {
                EmptyView()
            }
        }
        .hidden()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationContainer { HomeView() }
            .environment(\.managedObjectContext, PersistenceController(inMemory: true).container.viewContext)
    }
}
