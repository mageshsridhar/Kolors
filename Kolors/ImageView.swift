//
//  ImageView.swift
//  Kolors
//
//  Created by Magesh Sridhar on 3/29/21.
//

import SwiftUI

/// The Create tab: pick a photo and go straight to its palette.
struct ImageView: View {
    @State private var source: PhotoSource?
    @State private var image: UIImage?
    @State private var showPalette = false

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    SampleArtwork()
                    Text("Turn any photo into a color palette.")
                        .foregroundColor(Theme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(spacing: 10) {
                        Button("Choose Photo") { source = .library }
                            .buttonStyle(CapsuleButtonStyle())
                        if PhotoSource.isCameraAvailable {
                            Button("Take Photo") { source = .camera }
                                .buttonStyle(CapsuleButtonStyle(isPrimary: false))
                        }
                    }
                }
                .padding(16)
            }
            .background(paletteLink)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Kolors")
            .photoPicker(source: $source) { picked in
                image = picked
                showPalette = true
            }
        }
        .navigationViewStyle(.stack)
    }

    private var paletteLink: some View {
        NavigationLink(isActive: $showPalette) {
            if let image = image {
                KolorsFromImageView(image: image)
            }
        } label: {
            EmptyView()
        }
        .hidden()
    }
}

struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        ImageView()
    }
}
