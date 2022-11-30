//
//  Regions.swift
//  GymTracker
//
//  Created by Ben Huggins on 11/20/22.
//
//
//You could use the second option. But it'd be easier to store the latitude and longitude values separately as their own attributes. Then add a convenience method to your subclass that combines them and returns a CLLocationCoordinate2D.

import UIKit
import MapKit
import CoreLocation

class Regions: NSObject, MKAnnotation {
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
