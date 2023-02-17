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
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    lazy var persistentContainer: NSPersistentContainer = {
      let container = NSPersistentContainer(name: "DataModel")
      container.loadPersistentStores(completionHandler: { (storeDescription, error) in
        if let error = error as NSError? {
          fatalError("Unresolved error \(error), \(error.userInfo)") }
      })
      return container
    }()
    
    // MARK: - Core Data Saving support
    func save () {
      let context = context
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
    
    // Save a single Location
    func location(title: String, date: Date, identifier: String, latitude: Double, longitude: Double, radius: Double, placeMark: String) -> Location {
        let location = Location(context: context)
        location.title = title
        location.date = date
        location.identifier = identifier
        location.latitude = latitude
        location.longitude = longitude
        location.radius = radius
        location.placeMark = placeMark
        return location
    }
    
    // Fetches RegionEvents from a location identifier 
    func fetchRegions(locationIdentifier: String) -> [RegionEvent] {
        var fetchedRegionEvents = [RegionEvent]()
        
                do {
                   // let request = RegionEvent.fetchRequest() as NSFetchRequest<RegionEvent>   // this is basic NSFEtch
                    let request: NSFetchRequest<RegionEvent> = NSFetchRequest<RegionEvent>(entityName: "RegionEvent")
                    let pred = NSPredicate(format: "ANY regionIdentifier == %@", locationIdentifier)
                    request.predicate = pred
                     fetchedRegionEvents = try! context.fetch(request)
        
                } catch {
                    print("Error: \(error)")
                }
        return fetchedRegionEvents
    }
    
    

    // Save a regionEvent attached to it's Location
//    func regionEvent(enterRegionTime: Date, exitRegionTime: Date!, totalRegionTime: String, regionIdentifer: String, location: Location) -> RegionEvent {
//        let regionEvent = RegionEvent(context: context)
//        regionEvent.enterRegionTime = enterRegionTime
//        regionEvent.exitRegionTime = exitRegionTime
//        regionEvent.totalRegionTime = totalRegionTime   // there is no total time saved yet
//        regionEvent.regionIdentifier = regionIdentifer
//        location.addToRegionEvent(regionEvent)
//        
//        return regionEvent
//    }
    

    func getRegionEvents(location: Location) -> [RegionEvent] {
        let context = context
        let request: NSFetchRequest<RegionEvent> = RegionEvent.fetchRequest()
        request.predicate = NSPredicate(format: "location = %@", location)
        //request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        var fetchedRegionEvents: [RegionEvent] = []
        
        do {
            fetchedRegionEvents = try context.fetch(request)

        } catch let error {
            print("Error fetching songs \(error)")
        }
        return fetchedRegionEvents
    }
    
    //MARK: - DELETE A LOCATION CORE DATA
    func deleteLocation(location: Location) {
        let context = context
        context.delete(location)
        save()
    }
 
    //MARK: - MATCH REGION TO LOCATION USING IDENTIFIER
   //  I send you identifier from region and you give me back the title name
    func matchLocation(from identifier: String) -> Location? {
        let context = context
        var location: [Location] = []
            let request = Location.fetchRequest() as NSFetchRequest<Location>
            let pred = NSPredicate(format: "identifier == %@", identifier)
            request.predicate = pred
        do {
            location = try context.fetch(request)
            print("Is this the name? : \(String(describing: location.first))")
        } catch {
            print("Error: \(error)")
        }
        return location.first
         }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    


    
    
    

