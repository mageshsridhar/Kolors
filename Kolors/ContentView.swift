//
//  ContentView.swift
//  Kolors
//
//  Created by Magesh Sridhar on 3/29/21.
//

import SwiftUI

struct ContentView: View {
    @State private var showLoadError: Bool

    init(libraryFailedToLoad: Bool = false) {
        _showLoadError = State(initialValue: libraryFailedToLoad)
    }

    var body: some View {
        NavigationContainer { HomeView() }
            .font(.geistBody)
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
