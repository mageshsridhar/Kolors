//
//  ContentView.swift
//  Kolors
//
//  Created by Magesh Sridhar on 3/29/21.
//

import SwiftUI

struct ContentView: View {
    private enum Tab {
        case create, library
    }

    @State private var tab = Tab.create
    @State private var showLoadError: Bool

    init(libraryFailedToLoad: Bool = false) {
        _showLoadError = State(initialValue: libraryFailedToLoad)
    }

    var body: some View {
        TabView(selection: $tab) {
            ImageView()
                .tabItem { Label("Create", systemImage: "plus.circle") }
                .tag(Tab.create)
            KolorsView { tab = .create }
                .tabItem { Label("Library", systemImage: "paintpalette") }
                .tag(Tab.library)
        }
        .alert("Library Unavailable", isPresented: $showLoadError) {
            Button("Close", role: .cancel) {}
        } message: {
            Text("Your saved palettes couldn't be opened, and new ones can't be saved right now. Try restarting the app.")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController(inMemory: true).container.viewContext)
    }
}
