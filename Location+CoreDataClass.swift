//
//  Location+CoreDataClass.swift
//  GymTracker
//
//  Created by Ben Huggins on 1/9/23.
//
//

import Foundation
import CoreData
import MapKit
import CoreLocation

@objc(Location)
public class Location: NSManagedObject, MKAnnotation {
    
    
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    public var subtitle: String? {
      return String(radius)
    }
    
    func clampRadius(maxRadius: CLLocationDegrees) {
      radius = min(radius, maxRadius)
    }

}

extension Location {
    var region: CLCircularRegion {
      let region = CLCircularRegion(
        center: coordinate,
        radius: radius,
        identifier: identifier)
      region.notifyOnEntry = true
      region.notifyOnExit = true
      return region
    }
}
