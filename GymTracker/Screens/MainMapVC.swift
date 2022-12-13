//
//  ViewController.swift
//  GymTracker
//
//  Created by Ben Huggins on 11/19/22.
//
import UIKit
import MapKit
import CoreLocation
import CoreData

class MainMapVC: UIViewController {
   
    var locations = [Locations]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let locationManager = CLLocationManager()
    var lastLocationError: Error?
    let geoCoder = CLGeocoder()
    var placeMark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?
    private let regionMeters: Double = 10000
    
    let mapView : MKMapView = {
            let map = MKMapView()
            map.translatesAutoresizingMaskIntoConstraints = false
            map.overrideUserInterfaceStyle = .dark
            return map
        }()

    let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
       return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        title = "Gym Tracker"
        view.addSubview(mapView)
        let addLocationImage = UIImage(systemName: "plus.circle.fill") //location.square.fill
        let goToLocationImage = UIImage(systemName: "location.square.fill")
        let addLocation = UIBarButtonItem(image: addLocationImage, style: .plain, target: self, action: #selector(didTapAddLocationBarButton))
       // let add = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(goToYourLocation))
        
        let zoom = UIBarButtonItem(image: goToLocationImage, style: .plain, target: self, action: #selector(goToYourLocation))
        navigationItem.rightBarButtonItems = [addLocation, zoom]
    
        configureUI()
        checkLocationServices()
        fetchLocations()
    }
    
    
    // MARK: - Core Data Fetch
    
//    func updateLocations() {
//
//        mapView.removeAnnotation(locations as! MKAnnotation)
//        let entity = locations.entity()
//
//        let fetchRequest = NSFetchRequest<Locations>()
//        fetchRequest.entity = entity
//
//        locations = try! context.fetch(Locations.fetchRequest())
//        mapView.addAnnotations(locations)
//
//
//    }
    
    func fetchLocations() {
        do {
            self.locations = try context.fetch(Locations.fetchRequest())
          
            DispatchQueue.main.async {
                self.mapView.addAnnotations(self.locations)
                self.locations.forEach { self.add($0) }
            }
        }
        catch {
            print("Error: ", error.localizedDescription)
        }
    }
    
    func setUpLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setUpLocationManager()
            checkLocationAuthorization()
        } else {
            // show alert saying location services are turned off
        }
    }
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            mapView.showsUserLocation = true
           // centerViewOnUsersLocation()
            locationManager.startUpdatingLocation()

            break
        case .authorizedWhenInUse:
            break
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .denied:
            // show alert telling them they have to enable location services in their settings
            break
        case .restricted:
            // Parental Control: Show Alert
            break
        }
    }
    
    func centerViewOnUsersLocation() {
        mapView.tintColor = .blue
        
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionMeters, longitudinalMeters: regionMeters)
            mapView.setRegion(region, animated: true)
            
            
//            mapView.setCameraBoundary(
//              MKMapView.CameraBoundary(coordinateRegion: region),
//              animated: true)
//
//            let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 200000)
//            mapView.setCameraZoomRange(zoomRange, animated: true)
        }
    }
    
    
    // MARK: - Helper Methods - Alerts
    func showLocationServicesDeniedAlert() {
      let alert = UIAlertController(
        title: "Location Services Disabled",
        message: "Please enable location services for GymTracker in your iphone. Please go to Settings -> Privacy -> Location Services -> Enable Thankyou!",
        preferredStyle: .alert)

      let okAction = UIAlertAction(
        title: "OK",
        style: .default,
        handler: nil)
      alert.addAction(okAction)
      present(alert, animated: true, completion: nil)
    }
    
    func add(_ location: Locations) {
        locations.append(location)
      mapView.addAnnotation(location)
      //updateGeotificationsCount()
        mapView.addOverlay(MKCircle(center: location.coordinate, radius: location.radius))
    }
    //MARK: - DELETING
    func remove(_ location: Locations) {
      guard let index = locations.firstIndex(of: location) else { return }
      locations.remove(at: index)
      mapView.removeAnnotation(location)
      removeRadiusOverlay(forLocation: location)
        
        //MARK: - CORE DATA DELETE
        try context.delete(location)
        do {
           try context.save()
        } catch {
            print("Error: \(error.localizedDescription)")
        }
     // updateGeotificationsCount()
    }
    
    // MARK: MAP OVERLAY
    func addRadiusOverlay(forLocation location: Locations) {
      mapView.addOverlay(MKCircle(center: location.coordinate, radius: location.radius))
    }
    
    func removeRadiusOverlay(forLocation location: Locations) {
    let overlays = mapView.overlays
      for overlay in overlays {
        guard let circleOverlay = overlay as? MKCircle else { continue }
        let coord = circleOverlay.coordinate
        if coord.latitude == location.coordinate.latitude &&
          coord.longitude == location.coordinate.longitude &&
          circleOverlay.radius == location.radius {
          mapView.removeOverlay(circleOverlay)
          break
        }
      }
    }
    
    // MARK: LAYOUT CONFIGURATION
    private func configureUI() {
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc func goToYourLocation() {
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        if authStatus == .denied || authStatus == .restricted {
            showLocationServicesDeniedAlert()
            return
        }
        mapView.zoomToLocation(mapView.userLocation.location)
    }
    
    @objc func didTapAddLocationBarButton() {
        let addLocationVC = AddLocationVC()
        let navVC = UINavigationController(rootViewController: addLocationVC)
        addLocationVC.delegate = self   //2                                            // this is the delegate
        present(navVC, animated: true)
    }
    
  
}

extension MainMapVC: CLLocationManagerDelegate {
    
    // This fires everytime the users location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // we will be back
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // we will be back
        let status = manager.authorizationStatus

        // This is what shows the blue dot on the screen
        mapView.showsUserLocation = (status == .authorizedAlways)

        // 3
        if status != .authorizedAlways {
          let message = """
          Your geotification is saved but will only be activated once you grant
          Geotify permission to access the device location.
          """
          showAlert(withTitle: "Warning", message: message)
        }
    }
    
    // MARK: - HANDLE LOCATION MANAGER ERRORS
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError: \(error)")
        
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        
        if (error as NSError).code == CLError.regionMonitoringFailure.rawValue {
            // SHOULD AN ALERT BE PRESENTED WHEN/ if there is a regional error
            
            
            return
        }
        
        lastLocationError = error
    }

    // Convert to a readable address.
func string(from placemark: CLPlacemark) -> String {
  var line1 = ""
  if let tmp = placemark.subThoroughfare {
    line1 += tmp + " "
  }
  if let tmp = placemark.thoroughfare {
    line1 += tmp
  }
  var line2 = ""
  if let tmp = placemark.locality {
    line2 += tmp + " "
  }
  if let tmp = placemark.administrativeArea {
    line2 += tmp + " "
  }
  if let tmp = placemark.postalCode {
    line2 += tmp
  }
  return line1 + "\n" + line2
}
}

extension MainMapVC: AddLocationVCDelegate {  // 1
   
    func addLocationVC(_ controller: AddLocationVC, didAddLocation location: Locations) {
        controller.dismiss(animated: true, completion: nil)
        location.clampRadius(maxRadius: locationManager.maximumRegionMonitoringDistance)
       
        
        startMonitoring(location: location) ///Call start monitoring function 
        
        add(location)
    }
}

// MARK: - Map Annotation
extension MainMapVC: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    let identifier = "myGeotification"
   
    if annotation is Locations {
      var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
      if annotationView == nil {
        annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        annotationView?.canShowCallout = true
    
        let removeButton = UIButton(type: .custom)
        removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
        removeButton.setImage(UIImage(systemName: "trash.fill"), for: .normal)
        annotationView?.leftCalloutAccessoryView = removeButton
          //      view.canShowCallout = true
          //      view.calloutOffset = CGPoint(x: -5, y: 5)
         // let button = UIButton(type: .detailDisclosure)
          annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
          //annotationView?.rightCalloutAccessoryView = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapGraphView))
      } else {
        annotationView?.annotation = annotation
      }
      return annotationView
    }
    return nil
  }
    
    @objc func didTapGraphView() {
        
        
    }

  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      if let circleOverlay = overlay as? MKCircle {
      let circleRenderer = MKCircleRenderer(overlay: circleOverlay)
      circleRenderer.lineWidth = 1.0
      circleRenderer.strokeColor = .red
      circleRenderer.fillColor = UIColor.red.withAlphaComponent(0.4)
      return circleRenderer
    }
    return MKOverlayRenderer(overlay: overlay)
  }
    
  func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    guard let location = view.annotation as? Locations else { return }
      
      //MARK: - MAP MARKER ACCESSORY VIEW RIGHT AND LEFT BUTTONS
      if control == view.leftCalloutAccessoryView {
          remove(location)
          stopMonitoring(location: location) /// Stop monitoring a region
              } else if control == view.rightCalloutAccessoryView {
                  let detailVC = DetailLocationVC()
                  detailVC.titleString = location.title!
                  navigationController?.pushViewController(detailVC, animated: true)
              }
        }
}
//MARK: - REGION MONITORING
extension MainMapVC {
    
    func startMonitoring(location: Locations) {
      // 1
      if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
        showAlert(
          withTitle: "Error",
          message: "Geofencing is not supported on this device!")
        return
      }
      let fenceRegion = location.region

      locationManager.startMonitoring(for: fenceRegion)
    }
    func stopMonitoring(location: Locations) {
      for region in locationManager.monitoredRegions {
        guard let circularRegion = location as? CLCircularRegion, circularRegion.identifier == location.identifier else { continue }
        locationManager.stopMonitoring(for: circularRegion)
      }
    }
}


