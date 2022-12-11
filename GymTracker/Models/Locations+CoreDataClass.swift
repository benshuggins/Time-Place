//
//  Locations+CoreDataClass.swift
//  GymTracker
//
//  Created by Ben Huggins on 12/9/22.
//
//

import Foundation
import CoreData
import MapKit

@objc(Locations)
public class Locations: NSManagedObject, MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    
    public var subtitle: String? {   // This is automatically called by MKAnnotation class and is the second title in tag on map
      return title
    }
    
  
   // public var coordinate: CLLocationCoordinate2D
    

}
