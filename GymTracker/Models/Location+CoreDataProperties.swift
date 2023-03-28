//
//  Location+CoreDataProperties.swift
//  GymTracker
//
//  Created by Ben Huggins on 2/15/23.
//
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var date: Date?
    @NSManaged public var identifier: String
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var placeMark: String?
    @NSManaged public var radius: Double
    @NSManaged public var title: String?
    @NSManaged public var regionEvent: RegionEvent?
}

// MARK: Generated accessors for regionEvent
extension Location {
    @objc(addRegionEventObject:)
    @NSManaged public func addToRegionEvent(_ value: RegionEvent)

    @objc(removeRegionEventObject:)
    @NSManaged public func removeFromRegionEvent(_ value: RegionEvent)

    @objc(addRegionEvent:)
    @NSManaged public func addToRegionEvent(_ values: NSSet)

    @objc(removeRegionEvent:)
    @NSManaged public func removeFromRegionEvent(_ values: NSSet)
}

extension Location : Identifiable {

}
