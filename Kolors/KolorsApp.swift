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
    let persistentContainer = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            ContentView().environment(\.managedObjectContext, persistentContainer.container.viewContext)
        }
    }
}
