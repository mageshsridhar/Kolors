//
//  Persistence.swift
//  Kolors
//
//  Created by Magesh Sridhar on 3/30/21.
//

import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer
    /// Set when the library couldn't be opened or migrated.
    private(set) var loadError: Error?

    private static let currentModel = model(named: "MyKolors 2")

    init(storeURL: URL? = nil, inMemory: Bool = false) {
        if let model = Self.currentModel {
            container = NSPersistentContainer(name: "MyKolors", managedObjectModel: model)
        } else {
            container = NSPersistentContainer(name: "MyKolors")
        }

        guard let description = container.persistentStoreDescriptions.first else { return }
        if inMemory {
            description.type = NSInMemoryStoreType
        } else if let storeURL = storeURL {
            description.url = storeURL
        }
        // StoreMigrator handles migrations. An inferred one would silently drop colors.
        description.shouldInferMappingModelAutomatically = false

        do {
            if !inMemory, let url = description.url {
                try StoreMigrator.migrateIfNeeded(storeAt: url, to: container.managedObjectModel)
            }
            container.loadPersistentStores { [weak self] _, error in
                self?.loadError = error
            }
        } catch {
            loadError = error
        }
    }

    static func model(named name: String) -> NSManagedObjectModel? {
        Bundle(for: PersistenceController.self)
            .url(forResource: name, withExtension: "mom", subdirectory: "MyKolors.momd")
            .flatMap(NSManagedObjectModel.init(contentsOf:))
    }
}
