import CoreData
import XCTest
@testable import Kolors

final class PersistenceTests: XCTestCase {
    private var directory: URL!
    private var storeURL: URL { directory.appendingPathComponent("MyKolors.sqlite") }

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    private func fetch(_ context: NSManagedObjectContext) throws -> [Kolors] {
        let request = NSFetchRequest<Kolors>(entityName: "Kolors")
        request.sortDescriptors = [NSSortDescriptor(key: "paletteName", ascending: true)]
        return try context.fetch(request)
    }

    private func noiseJPEG() -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 600, height: 600), format: format).image { context in
            for x in stride(from: 0, to: 600, by: 4) {
                for y in stride(from: 0, to: 600, by: 4) {
                    UIColor(hue: .random(in: 0...1), saturation: 1, brightness: .random(in: 0...1), alpha: 1).setFill()
                    context.fill(CGRect(x: x, y: y, width: 4, height: 4))
                }
            }
        }.jpegData(compressionQuality: 1)!
    }

    /// Writes a store with the model the first release shipped.
    private func writeLegacyStore(image: Data) throws {
        let model = try XCTUnwrap(StoreMigrator.legacyModel())
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let store = try coordinator.addPersistentStore(
            ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil
        )
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        let entity = try XCTUnwrap(model.entitiesByName["Kolors"])
        let palette = NSManagedObject(entity: entity, insertInto: context)
        palette.setValue("Alpha", forKey: "paletteName")
        palette.setValue(image, forKey: "image")
        for number in 1...5 {
            palette.setValue("#000000", forKey: "color\(number)Hex")
            palette.setValue(Double(number * 10), forKey: "color\(number)R")
            palette.setValue(Double(number * 20), forKey: "color\(number)G")
            palette.setValue(Double(number * 51), forKey: "color\(number)B")
        }
        // A record with nothing set crashed the old library screen.
        _ = NSManagedObject(entity: entity, insertInto: context)
        try context.save()
        try coordinator.remove(store)
    }

    func testLegacyStoreMigrates() throws {
        let image = noiseJPEG()
        XCTAssertGreaterThan(image.count, 200_000, "must be large enough for external storage")
        try writeLegacyStore(image: image)

        // Twice: the second open must find the store already migrated.
        for _ in 0..<2 {
            let controller = PersistenceController(storeURL: storeURL)
            XCTAssertNil(controller.loadError)
            let palettes = try fetch(controller.container.viewContext)
            XCTAssertEqual(palettes.count, 2)

            let empty = try XCTUnwrap(palettes.first { $0.paletteName == nil })
            XCTAssertEqual(empty.paletteColors, [])
            XCTAssertEqual(empty.displayName, "Untitled")

            let alpha = try XCTUnwrap(palettes.first { $0.paletteName == "Alpha" })
            XCTAssertNil(alpha.createdAt)
            XCTAssertEqual(alpha.image, image)
            XCTAssertNotNil(alpha.thumbnail.flatMap(UIImage.init(data:)))
            let expected = [
                RGBColor(red: 10, green: 20, blue: 51),
                RGBColor(red: 20, green: 40, blue: 102),
                RGBColor(red: 30, green: 60, blue: 153),
                RGBColor(red: 40, green: 80, blue: 204),
                RGBColor(red: 50, green: 100, blue: 255)
            ]
            XCTAssertEqual(alpha.paletteColors, expected)
            XCTAssertEqual(Kolors.entity().name, "Kolors")
        }
    }

    func testCorruptStoreReportsErrorAndSaveThrows() throws {
        try Data("not a database".utf8).write(to: storeURL)
        let controller = PersistenceController(storeURL: storeURL)
        XCTAssertNotNil(controller.loadError)

        let context = controller.container.viewContext
        Kolors.insert(name: "X", palette: [], imageData: nil, thumbnailData: nil, into: context)
        XCTAssertThrowsError(try context.saveOrRollback())
        XCTAssertFalse(context.hasChanges)
    }

    func testPaletteRoundTripAndCascadeDelete() throws {
        let palette = [RGBColor(red: 1, green: 2, blue: 3), RGBColor(red: 255, green: 254, blue: 253)]
        let image = noiseJPEG()
        do {
            let context = PersistenceController(storeURL: storeURL).container.viewContext
            Kolors.insert(name: "Two", palette: palette, imageData: image, thumbnailData: nil, into: context)
            try context.saveOrRollback()
        }
        let controller = PersistenceController(storeURL: storeURL)
        let context = controller.container.viewContext
        let saved = try XCTUnwrap(fetch(context).first)
        XCTAssertEqual(saved.paletteColors, palette)
        XCTAssertEqual(saved.image, image)

        context.delete(saved)
        try context.saveOrRollback()
        XCTAssertNil(saved.managedObjectContext)
        XCTAssertEqual(try context.count(for: NSFetchRequest<NSManagedObject>(entityName: "PaletteColor")), 0)
    }

    func testFailedSaveRollsBack() throws {
        let context = PersistenceController(storeURL: storeURL).container.viewContext
        let kolor = Kolors.insert(
            name: "Bad", palette: [RGBColor(red: 0, green: 0, blue: 0)], imageData: nil, thumbnailData: nil, into: context
        )
        // Required attribute, so validation fails.
        (kolor.colors as? Set<PaletteColor>)?.first?.setValue(nil, forKey: "red")
        XCTAssertThrowsError(try context.saveOrRollback())
        XCTAssertFalse(context.hasChanges)
    }

    func testLibrarySortsNewestFirstThenUndatedByName() throws {
        let context = PersistenceController(storeURL: storeURL).container.viewContext
        for (name, date) in [("B", nil), ("Old", Date(timeIntervalSince1970: 1)), ("A", nil), ("New", Date(timeIntervalSince1970: 2))] {
            let kolor = Kolors.insert(name: name, palette: [], imageData: nil, thumbnailData: nil, into: context)
            XCTAssertNotNil(kolor.createdAt)
            kolor.createdAt = date
        }
        try context.saveOrRollback()
        let request = NSFetchRequest<Kolors>(entityName: "Kolors")
        request.sortDescriptors = Kolors.librarySort
        XCTAssertEqual(try context.fetch(request).map(\.displayName), ["New", "Old", "A", "B"])
    }

    func testSuggestedNameSkipsNamesInUse() throws {
        let context = PersistenceController(storeURL: storeURL).container.viewContext
        XCTAssertEqual(Kolors.suggestedName(in: context), "Palette 1")
        Kolors.insert(name: "Palette 2", palette: [], imageData: nil, thumbnailData: nil, into: context)
        try context.saveOrRollback()
        XCTAssertEqual(Kolors.suggestedName(in: context), "Palette 3")
    }

    func testSuggestedNameWithoutAStore() throws {
        try Data("not a database".utf8).write(to: storeURL)
        let context = PersistenceController(storeURL: storeURL).container.viewContext
        XCTAssertEqual(Kolors.suggestedName(in: context), "Palette 1")
    }
}
