//
//  Locations+CoreDataProperties.swift
//  GymTracker
//
//  Created by Ben Huggins on 12/27/22.
//
//

import Foundation
import CoreData
import MapKit
import CoreLocation

extension Locations {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Locations> {
        return NSFetchRequest<Locations>(entityName: "Locations")
    }

    @NSManaged public var date: Date?
    @NSManaged public var identifier: String
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var placeMark: CLPlacemark?
    @NSManaged public var radius: CLLocationDistance
    @NSManaged public var title: String?
    @NSManaged public var regionEvent: RegionEvent?

}

// MARK: Generated accessors for regionEvent
extension Locations {

    @objc(addRegionEventObject:)
    @NSManaged public func addToRegionEvent(_ value: RegionEvent)

    @objc(removeRegionEventObject:)
    @NSManaged public func removeFromRegionEvent(_ value: RegionEvent)

    @objc(addRegionEvent:)
    @NSManaged public func addToRegionEvent(_ values: NSSet)

    @objc(removeRegionEvent:)
    @NSManaged public func removeFromRegionEvent(_ values: NSSet)
}

extension Locations : Identifiable {

}
