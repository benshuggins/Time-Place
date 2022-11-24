//
//  Region+CoreDataProperties.swift
//  GymTracker
//
//  Created by Ben Huggins on 11/21/22.
//
//

import Foundation
import CoreData


extension Region {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Region> {
        return NSFetchRequest<Region>(entityName: "Region")
    }

    @NSManaged public var latitude: String?
    @NSManaged public var longitude: String?
    @NSManaged public var identifier: String?
    @NSManaged public var radius: Double
    @NSManaged public var title: String?

}

extension Region : Identifiable {

}
