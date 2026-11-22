import CoreData

extension Kolors {
    /// Newest first. Palettes from before dates were stored go last, by name.
    static let librarySort = [
        NSSortDescriptor(key: "createdAt", ascending: false),
        NSSortDescriptor(key: "paletteName", ascending: true)
    ]

    /// "Palette N", using the first number after the palette count that isn't taken.
    static func suggestedName(in context: NSManagedObjectContext) -> String {
        let request = NSFetchRequest<Kolors>(entityName: "Kolors")
        // Fetching without a store raises an exception rather than throwing.
        let hasStore = context.persistentStoreCoordinator?.persistentStores.isEmpty == false
        let names = hasStore ? ((try? context.fetch(request)) ?? []).map(\.displayName) : []
        var number = names.count + 1
        while names.contains("Palette \(number)") { number += 1 }
        return "Palette \(number)"
    }

    @discardableResult
    static func insert(
        name: String, palette: [RGBColor], imageData: Data?, thumbnailData: Data?, into context: NSManagedObjectContext
    ) -> Kolors {
        let kolor = Kolors(context: context)
        kolor.paletteName = name
        kolor.createdAt = Date()
        kolor.image = imageData
        kolor.thumbnail = thumbnailData
        for (position, rgb) in palette.enumerated() {
            let color = PaletteColor(context: context)
            color.position = Int16(position)
            color.red = Int16(rgb.red)
            color.green = Int16(rgb.green)
            color.blue = Int16(rgb.blue)
            color.palette = kolor
        }
        return kolor
    }

    var displayName: String { paletteName ?? "Untitled" }

    var paletteColors: [RGBColor] {
        let stored = colors as? Set<PaletteColor> ?? []
        return stored.sorted { $0.position < $1.position }.map {
            RGBColor(red: UInt8(clamping: $0.red), green: UInt8(clamping: $0.green), blue: UInt8(clamping: $0.blue))
        }
    }
}

extension NSManagedObjectContext {
    /// Saves pending changes, discarding them if the save fails.
    func saveOrRollback() throws {
        // Core Data raises an uncatchable exception when saving without a store.
        guard let coordinator = persistentStoreCoordinator, !coordinator.persistentStores.isEmpty else {
            rollback()
            throw CocoaError(.persistentStoreOpen)
        }
        do {
            try save()
        } catch {
            rollback()
            throw error
        }
    }
}
