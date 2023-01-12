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
    
    let defaults = UserDefaults.standard
    var locations = [Location]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let locationManager = CLLocationManager()
    var lastLocationError: Error?
    let geoCoder = CLGeocoder()
    var placeMark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?
    private let regionMeters: Double = 10000
    private var slideInTransitionDelegate: SlideInPresentationManager!
    var userIdentifierLabel = ""
    var givenNameLabel = ""
    var familyNameLabel = ""
    var emailLabel = ""
    
    let mapView : MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.overrideUserInterfaceStyle = .dark
        return map}()

    let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
       return table}()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //MARK: - Only show login screen once
        if defaults.bool(forKey: "First Launch") == true {
            print("Second or more app launch")
            defaults.set(true, forKey: "First Launch")
        } else {
            print("First Launch -- Open Sign In With Apple Screen")
            showLoginViewController()
            defaults.set(true, forKey: "First Launch")
        }
        
        mapView.delegate = self
        title = "Map"
        view.addSubview(mapView)
        let addLocationImage = UIImage(systemName: "plus.circle.fill") //location.square.fill
        let goToLocationImage = UIImage(systemName: "mappin.and.ellipse")
        let leftMenuButton = UIImage(systemName: "text.justify.left")
        let centerLocation = UIImage(systemName: "mappin.square")
        let addLocation = UIBarButtonItem(image: addLocationImage, style: .plain, target: self, action: #selector(didTapAddLocationBarButton))
        let zoom = UIBarButtonItem(image: goToLocationImage, style: .plain, target: self, action: #selector(goToYourLocation))
        navigationItem.rightBarButtonItems = [addLocation, zoom]
        let leftMenu = UIBarButtonItem(image: leftMenuButton, style: .plain, target: self, action: #selector(openLeftMenuButtonTapped))
        let centerOverLocations = UIBarButtonItem(image: centerLocation, style: .plain, target: self, action: #selector(showLocations))
        navigationItem.leftBarButtonItems = [leftMenu, centerOverLocations]
        locationManager.allowsBackgroundLocationUpdates = true
        configureUI()
        checkLocationServices()
        fetchLocations()
        
        if !locations.isEmpty {
            showLocations()
        }
    }
    
    // Centers the screen over All the Map annotations Perfectly
    func region(for annotations: [MKAnnotation]) -> MKCoordinateRegion {
      let region: MKCoordinateRegion
      switch annotations.count {
      case 0:
        region = MKCoordinateRegion(center: mapView.userLocation.coordinate,latitudinalMeters: 1000,longitudinalMeters: 1000)
      case 1:
        let annotation = annotations[annotations.count - 1]
        region = MKCoordinateRegion(center: annotation.coordinate,latitudinalMeters: 1000,longitudinalMeters: 1000)
      default:
        var topLeft = CLLocationCoordinate2D(latitude: -90,longitude: 180)
        var bottomRight = CLLocationCoordinate2D(latitude: 90,longitude: -180)
        for annotation in annotations {topLeft.latitude = max(topLeft.latitude,annotation.coordinate.latitude)
          topLeft.longitude = min(topLeft.longitude,annotation.coordinate.longitude)
          bottomRight.latitude = min(bottomRight.latitude, annotation.coordinate.latitude)
          bottomRight.longitude = max(bottomRight.longitude,annotation.coordinate.longitude)}
        let center = CLLocationCoordinate2D(latitude: topLeft.latitude - (topLeft.latitude - bottomRight.latitude) / 2,
          longitude: topLeft.longitude - (topLeft.longitude - bottomRight.longitude) / 2)
        let extraSpace = 1.1
        let span = MKCoordinateSpan(latitudeDelta: abs(topLeft.latitude - bottomRight.latitude) * extraSpace,
          longitudeDelta: abs(topLeft.longitude - bottomRight.longitude) * extraSpace)
        region = MKCoordinateRegion(center: center, span: span)
      }
      return mapView.regionThatFits(region)
    }
    
    // MARK: - Core Data Fetch
    func fetchLocations() {
        do {
            self.locations = try context.fetch(Location.fetchRequest())
            DispatchQueue.main.async {
                self.mapView.addAnnotations(self.locations)
                self.locations.forEach { self.add($0) }
            }
        }
        catch {
            print("Error: ", error.localizedDescription)
        }
    }
    // Keep Battery Level drainage manageable
    func setUpLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // 
        
        
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
            locationManager.allowsBackgroundLocationUpdates = true   // this is the second declaration one in viewDidLoad

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
        }
    }
    
    // MARK: - Helper Methods - Alerts
    func showLocationServicesDeniedAlert() {
      let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for GymTracker in your iphone. Please go to Settings -> Privacy -> Location Services -> Enable Thankyou!",
        preferredStyle: .alert)
      let okAction = UIAlertAction(title: "OK",style: .default,handler: nil)
        alert.addAction(okAction)
      present(alert, animated: true, completion: nil)
    }
    //MARK: - ADDING A LOCATION
    func add(_ location: Location) {
        locations.append(location)
      mapView.addAnnotation(location)
      //updateGeotificationsCount()
        mapView.addOverlay(MKCircle(center: location.coordinate, radius: location.radius))
    }
    //MARK: - DELETING A LOCATION
    func remove(_ location: Location) {
      guard let index = locations.firstIndex(of: location) else { return }
      locations.remove(at: index)
      mapView.removeAnnotation(location)
      removeRadiusOverlay(forLocation: location)
        
      DataManager.shared.deleteLocation(location: location)
     // updateGeotificationsCount()
    }
    
    // MARK: MAP OVERLAY
    func addRadiusOverlay(forLocation location: Location) {
      mapView.addOverlay(MKCircle(center: location.coordinate, radius: location.radius))
    }
    
    func removeRadiusOverlay(forLocation location: Location) {
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
    
    @objc func showLocations() {
        let theRegion = region(for: locations)
        mapView.setRegion(theRegion, animated: true)
    }
    
    @objc func openLeftMenuButtonTapped() {
        let controller2 = LeftMenuVC()
        slideInTransitionDelegate = SlideInPresentationManager()
        slideInTransitionDelegate.direction = .left
        controller2.modalPresentationStyle = .custom
        controller2.transitioningDelegate = slideInTransitionDelegate
        present(controller2, animated: true, completion: nil)
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
        addLocationVC.delegate = self
       // navVC.modalPresentationStyle = .overFullScreen
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
    
    // MARK: - HANDLE LOCATION MANAGER ERROR HANDLING
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Did fail with error: \(error)")
        
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

//MARK: - CALL BACK FROM ADDLOCATIONVC
extension MainMapVC: AddLocationVCDelegate {
    func addLocationVC(_ controller: AddLocationVC, didAddLocation location: Location) {
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
    if annotation is Location {
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
    
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      if let circleOverlay = overlay as? MKCircle {
      let circleRenderer = MKCircleRenderer(overlay: circleOverlay)
      circleRenderer.lineWidth = 1.0
      circleRenderer.strokeColor = .green
      circleRenderer.fillColor = UIColor.red.withAlphaComponent(0.4)
      return circleRenderer
    }
    return MKOverlayRenderer(overlay: overlay)
  }
    
  func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    guard let location = view.annotation as? Location else { return }
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
    func startMonitoring(location: Location) {
      if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
        showAlert(withTitle: "Error", message: "Geofencing is not supported on this device!")
        return
      }
      let fenceRegion = location.region
      locationManager.startMonitoring(for: fenceRegion) // Here is where we initiate region monitoring
    }
    
    func stopMonitoring(location: Location) {
      for region in locationManager.monitoredRegions {
        guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == location.identifier else { continue }
        locationManager.stopMonitoring(for: circularRegion)
      }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
      guard let region = region else {
        print("Monitoring failed for unknown region")
          
          // NEED TO ADD ALERT ACTIONS TO INFORM THE USER OF FAILURE
        return
      }
      print("Monitoring failed for region with identifier: \(region.identifier)")
        // NEED TO ADD ALERT ACTIONS TO INFORM THE USER OF FAILURE
    }
}

