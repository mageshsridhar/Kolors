//
//  Persistence.swift
//  Kolors
//
//  Created by Magesh Sridhar on 3/30/21.
//

import CoreData

struct PersistenceController{
    static let shared = PersistenceController()
    let container : NSPersistentContainer
    
    init(){
        container = NSPersistentContainer(name: "MyKolors")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError?{
                fatalError("Unresolved Error \(error)")
            }
        }
    }
}
