//
//  Regions.swift
//  GymTracker
//
//  Created by Ben Huggins on 11/20/22.
//
//
//You could use the second option. But it'd be easier to store the latitude and longitude values separately as their own attributes. Then add a convenience method to your subclass that combines them and returns a CLLocationCoordinate2D.


// So for Core Data we need to convert to latitude and longitude

import UIKit
import MapKit
import CoreLocation

class Regions: NSObject, MKAnnotation {
  let title: String?
  var radius: Double
  let identifier: String
  let placeMark: CLPlacemark?
  let date: Date
  
    let coordinate: CLLocationCoordinate2D   // This is required for an MKAnnotation
    
    var latitude: Double {
        return coordinate.latitude
    }
    var longitude: Double {
        return coordinate.longitude
    }
    
    
    var subtitle: String? {   // This is automatically called by MKAnnotation class and is the second title in tag on map
      return title
    }

    init(title: String?, radius: Double, identifier: String, coordinate: CLLocationCoordinate2D, placeMark: CLPlacemark?, date: Date) {
    self.title = title
    self.radius = radius
    self.identifier = identifier
    self.coordinate = coordinate
    self.placeMark = placeMark
    self.date = date
    super.init()
  }

    
    func clampRadius(maxRadius: CLLocationDegrees) {
      radius = min(radius, maxRadius)
    }
}

//
//extension Region  {
//    public var coordinate: CLLocationCoordinate2D {
//        // latitude and longitude are optional NSNumbers
//        guard let latitude = latitude, let longitude = longitude else {
//            return kCLLocationCoordinate2DInvalid
//        }
//
//        let latDegrees = CLLocationDegrees(latitude)
//        let longDegrees = CLLocationDegrees(longitude)
//        return CLLocationCoordinate2D(latitude: latDegrees!, longitude: longDegrees!)
//    }
//}
