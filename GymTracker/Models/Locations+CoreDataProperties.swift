//
//  Locations+CoreDataProperties.swift
//  GymTracker
//
//  Created by Ben Huggins on 12/9/22.
//
//

import Foundation
import CoreData


extension Locations {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Locations> {
        return NSFetchRequest<Locations>(entityName: "Locations")
    }

    @NSManaged public var date: Date?
    @NSManaged public var identifier: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var placeMark: NSObject?
    @NSManaged public var radius: Double
    @NSManaged public var title: String?

}

extension Locations : Identifiable {

}
