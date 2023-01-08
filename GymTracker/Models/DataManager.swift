//
//  DataManager.swift
//  GymTracker
//
//  Created by Ben Huggins on 12/27/22.
//

import Foundation
import CoreData
import MapKit


class DataManager {
    
    static let shared = DataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
      let container = NSPersistentContainer(name: "DataModel")
      container.loadPersistentStores(completionHandler: { (storeDescription, error) in
        if let error = error as NSError? {
          fatalError("Unresolved error \(error), \(error.userInfo)") }
      })
      return container
    }()
    
    
//     Saving

    func location(title: String, date: Date, identifier: String, latitude: Double, longitude: Double, radius: Double, placeMark: String) -> Location {

        let location = Location(context: persistentContainer.viewContext)
        location.title = title
        location.date = date
        location.identifier = identifier
        location.latitude = latitude
        location.longitude = longitude
        location.radius = radius
        location.placeMark = placeMark
        
        return location
    }
    
    // MARK: - Core Data Saving support
    func saveContext () {
      let context = persistentContainer.viewContext
      if context.hasChanges {
        do {
          try context.save()
        } catch {
          // Replace this implementation with code to handle the error appropriately.
          // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
          let nserror = error as NSError
          fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
      }
    }

        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    


    
    
    

