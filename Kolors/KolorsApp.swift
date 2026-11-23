//
//  KolorsApp.swift
//  Kolors
//
//  Created by Magesh Sridhar on 3/29/21.
//

import SwiftUI
import CoreData

@main
struct KolorsApp: App {
    private let persistence = PersistenceController.shared

    init() {
        NavigationBarStyle.apply()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(libraryFailedToLoad: persistence.loadError != nil)
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
