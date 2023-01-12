//
//  RegionEvent+CoreDataProperties.swift
//  GymTracker
//
//  Created by Ben Huggins on 1/9/23.
//
//

import Foundation
import CoreData


extension RegionEvent {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RegionEvent> {
        return NSFetchRequest<RegionEvent>(entityName: "RegionEvent")
    }

    @NSManaged public var enterRegionTime: Date?
    @NSManaged public var exitRegionTime: Date?
    @NSManaged public var totalRegionTime: String?
    @NSManaged public var regionIdentifier: String
    @NSManaged public var location: Location?

}

extension RegionEvent : Identifiable {

}
