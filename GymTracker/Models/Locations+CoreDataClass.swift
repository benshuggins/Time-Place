//
//  Locations+CoreDataClass.swift
//  GymTracker
//
//  Created by Ben Huggins on 12/27/22.
//
//

import Foundation
import CoreData
import CoreLocation
import MapKit

@objc(Locations)
public class Locations: NSManagedObject, MKAnnotation {
   
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
 
extension Locations {
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
