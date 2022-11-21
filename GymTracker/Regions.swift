//
//  Regions.swift
//  GymTracker
//
//  Created by Ben Huggins on 11/20/22.
//

import UIKit
import MapKit
import CoreLocation

class Region: NSObject, MKAnnotation {
  let title: String?
  var radius: Double
  let identifier: String
  let coordinate: CLLocationCoordinate2D   // This is required for an MKAnnotation
    
    
    var subtitle: String? {   // This is automatically called by MKAnnotation class and is the second title in tag on map
      return title
    }

  init(title: String?, radius: Double, identifier: String, coordinate: CLLocationCoordinate2D) {
    self.title = title
    self.radius = radius
    self.identifier = identifier
    self.coordinate = coordinate
    super.init()
  }

    
    func clampRadius(maxRadius: CLLocationDegrees) {
      radius = min(radius, maxRadius)
    }
}
