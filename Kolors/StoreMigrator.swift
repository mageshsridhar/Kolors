import CoreData
import UIKit

/// Moves stores written by the first release, with 20 color attributes per palette, to the related
/// `PaletteColor` entity. Core Data can't infer this mapping and would drop the colors.
enum StoreMigrator {
    enum MigrationError: Error {
        case unknownStoreVersion
    }

    static func migrateIfNeeded(storeAt url: URL, to model: NSManagedObjectModel) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: url)
        guard !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) else { return }

        guard let legacyModel = legacyModel(),
              legacyModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) else {
            throw MigrationError.unknownStoreVersion
        }

        // Migrate beside the original and swap only on success, so a failure leaves the store untouched.
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let migratedURL = directory.appendingPathComponent(url.lastPathComponent)

        let manager = NSMigrationManager(sourceModel: legacyModel, destinationModel: model)
        try manager.migrateStore(
            from: url, sourceType: NSSQLiteStoreType, options: nil,
            with: mapping(from: legacyModel, to: model),
            toDestinationURL: migratedURL, destinationType: NSSQLiteStoreType, destinationOptions: nil
        )
        try NSPersistentStoreCoordinator(managedObjectModel: model).replacePersistentStore(
            at: url, destinationOptions: nil,
            withPersistentStoreFrom: migratedURL, sourceOptions: nil, ofType: NSSQLiteStoreType
        )
    }

    /// The first release's model. Its entities use plain managed objects so that they don't compete with
    /// the current model for the generated `Kolors` class, which would break `Kolors.entity()`.
    static func legacyModel() -> NSManagedObjectModel? {
        let model = PersistenceController.model(named: "MyKolors")
        model?.entities.forEach { $0.managedObjectClassName = NSStringFromClass(NSManagedObject.self) }
        return model
    }

    private static func mapping(from source: NSManagedObjectModel, to destination: NSManagedObjectModel) -> NSMappingModel {
        let palettes = NSEntityMapping()
        palettes.name = "KolorsToKolors"
        palettes.mappingType = .customEntityMappingType
        palettes.sourceEntityName = "Kolors"
        palettes.sourceEntityVersionHash = source.entitiesByName["Kolors"]?.versionHash
        palettes.destinationEntityName = "Kolors"
        palettes.destinationEntityVersionHash = destination.entitiesByName["Kolors"]?.versionHash
        palettes.entityMigrationPolicyClassName = NSStringFromClass(PaletteMigrationPolicy.self)
        palettes.sourceExpression = NSExpression(
            format: "FETCH(FUNCTION($manager, 'fetchRequestForSourceEntityNamed:predicateString:', 'Kolors', 'TRUEPREDICATE'), $manager.sourceContext, NO)"
        )

        let model = NSMappingModel()
        model.entityMappings = [palettes]
        return model
    }
}

final class PaletteMigrationPolicy: NSEntityMigrationPolicy {
    override func createDestinationInstances(
        forSource source: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager
    ) throws {
        let context = manager.destinationContext
        let palette = NSEntityDescription.insertNewObject(forEntityName: "Kolors", into: context)
        palette.setValue(source.value(forKey: "paletteName"), forKey: "paletteName")

        let image = source.value(forKey: "image") as? Data
        palette.setValue(image, forKey: "image")
        palette.setValue(image.flatMap(UIImage.init(data:)).flatMap(ImageProcessing.thumbnailData), forKey: "thumbnail")

        for number in 1...5 where source.value(forKey: "color\(number)Hex") != nil {
            let color = NSEntityDescription.insertNewObject(forEntityName: "PaletteColor", into: context)
            color.setValue(number - 1, forKey: "position")
            for (legacy, key) in [("R", "red"), ("G", "green"), ("B", "blue")] {
                let value = source.value(forKey: "color\(number)\(legacy)") as? Double ?? 0
                color.setValue(Int(min(max(value, 0), 255)), forKey: key)
            }
            color.setValue(palette, forKey: "palette")
        }
        manager.associate(sourceInstance: source, withDestinationInstance: palette, for: mapping)
    }
}
