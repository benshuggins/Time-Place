//
//  ViewController.swift
//  GymTracker
//
//  Created by Ben Huggins on 11/19/22.
//
// Build everything with appdelegate managedObjectContext

// I am currently not using NSFetchResultscontroller and I wont

import UIKit
import MapKit
import CoreLocation
import CoreData

class MainMapVC: UIViewController, NSFetchedResultsControllerDelegate {
	
	var locations = [Location]() {   // local
		didSet {
			
			self.tableView.reloadData()
			//self.tableView.beginUpdates()
			//mapView.addOverlay(locations as! MKOverlay)
		//	mapView.addOverlay(MKCircle(center: locations.coordinate, radius: locations.radius))
			if locations.isEmpty { self.showEmptyAlert() }
		}
	}
	
    let defaults = UserDefaults.standard
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let locationManager = CLLocationManager()
    var lastLocationError: Error?
    let geoCoder = CLGeocoder()
    var placeMark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?
    private let regionMeters: Double = 40
    private var slideInTransitionDelegate: SlideInPresentationManager!
    var userIdentifierLabel = ""
    var givenNameLabel = ""
    var familyNameLabel = ""
    var emailLabel = ""
	
	lazy var stackView: UIStackView = {
		let stack = UIStackView()
		stack.axis = .vertical
		stack.spacing = 20.0
		stack.alignment = .fill
		stack.distribution = .fillEqually
		[self.tableView,
			self.mapView].forEach { stack.addArrangedSubview($0) }
		return stack
	}()
	
	let tableView: UITableView = {
		let table = UITableView()
		table.layer.cornerRadius = 10
		table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
		table.translatesAutoresizingMaskIntoConstraints = false
		return table
	}()
    
    let mapView : MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.overrideUserInterfaceStyle = .dark
        return map
	}()
	
	let goToLocationButton = UIButton()
    let centerOverRegionsButton = UIButton()
	let addNewButton = UIButton()
	
	lazy var fetchedResultsController: NSFetchedResultsController<Location> = {
	  let fetchRequest = NSFetchRequest<Location>()

	  let entity = Location.entity()
	  fetchRequest.entity = entity

	  let sort1 = NSSortDescriptor(key: "title", ascending: true)
	//  let sort2 = NSSortDescriptor(key: "enterRegionTime", ascending: true)
	  fetchRequest.sortDescriptors = [sort1]
	 fetchRequest.fetchBatchSize = 20

		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: "title", cacheName: "Locations")

	  fetchedResultsController.delegate = self
	  return fetchedResultsController
	}()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
        //MARK: - Only show login screen once
        if defaults.bool(forKey: "First Launch") == true {
            print("Second or more app launch")
            defaults.set(true, forKey: "First Launch")
        } else {
            print("First Launch -- Open Sign In With Apple Screen")
            showLoginViewController()
            defaults.set(true, forKey: "First Launch")
        }
		navigationController?.navigationBar.backgroundColor = .purple
		navigationController?.toolbar.barTintColor = .purple
		view.addSubview(tableView)
		
        mapView.delegate = self
		mapView.layer.cornerRadius = 10
        title = "Time@Place"
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
		
		view.backgroundColor = .purple
		view.addSubview(stackView)
        stackView.addSubview(tableView)
		stackView.addSubview(mapView)
		stackView.frame = view.bounds
		tableView.dataSource = self
		tableView.delegate = self
		
		mapView.addSubview(goToLocationButton)
		mapView.addSubview(centerOverRegionsButton)
		tableView.addSubview(addNewButton)
		
		configureUI()
		checkLocationServices()
		fetchLocations()
		configureButtons()

		addNewButton.addTarget(self, action: #selector(didTapAddLocationBarButton), for: .touchUpInside)
		centerOverRegionsButton.addTarget(self, action: #selector(showLocations), for: .touchUpInside)
		goToLocationButton.addTarget(self, action: #selector(goToYourLocation), for: .touchUpInside)

		let leftMenuButton = UIImage(systemName: "text.justify.left")
        let leftMenu = UIBarButtonItem(image: leftMenuButton, style: .plain, target: self, action: #selector(openLeftMenuButtonTapped))

        navigationItem.leftBarButtonItem = leftMenu
        locationManager.allowsBackgroundLocationUpdates = true
       
        if locations.isEmpty { self.showEmptyAlert() }
        if !locations.isEmpty { showLocations() }
		
		 performFetch()  // this is for NSFetchresultscontrolller
    }
	
	//THIS IS THE FETCH FOR THE TABLEVIEW
	private func performFetch() {

		do {
			try fetchedResultsController.performFetch()
			tableView.reloadData()
		} catch {
			print("Error with fetchedResultsController \(error)")
		}
	}
	
//
//	deinit {
//		fetchedResultsController.delegate = nil
//	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(true)
		AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
		
		if !locations.isEmpty { showLocations() }
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(true)
		AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
	}
    
    func showEmptyAlert() {
        self.showAlert(withTitle: "No Locations!", message: "To add a Location, Tap the green + button!")
    }

    /// Centers the screen over All the Map annotations Perfectly
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
    
    // MARK: - Core Data Fetch For the map!! I have 2 fetches one for tableView and one for the map
  // This is for the map
	func fetchLocations() {
	
        do {
            self.locations = try context.fetch(Location.fetchRequest())
			print("😅😅😅😅😅😅😅😅😅😅Locations Count: , \(locations.count)")
			DispatchQueue.main.async {
                self.mapView.addAnnotations(self.locations)
				//self.locations.forEach { self.add($0) }
				
				//self.locations.forEach { //self.locations.forEach { self.add($0) } }
				
				// this adds an overlay to the map when refetched!!!
				for location in self.locations {
					self.mapView.addOverlay(MKCircle(center: location.coordinate, radius: location.radius))
				}
            }
        }
        catch {
            showAlert(withTitle: "Error", message: "There has been an error: \(error.localizedDescription)")
            print("Error: ", error.localizedDescription)
        }
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setUpLocationManager()
            checkLocationAuthorization()
        } else {
            showAlert(withTitle: "!!!", message: "Your Location Services are turned off!")
        }
    }
    func setUpLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest   
    }
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            mapView.showsUserLocation = true
           // centerViewOnUsersLocation()
            locationManager.startUpdatingLocation()
            locationManager.allowsBackgroundLocationUpdates = true

            break
        case .authorizedWhenInUse:
            break
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .denied:
				showAlert(withTitle: "Please Enable Location Services", message: "Please enable in your iPhone's settings page! Thanks")
            break
        case .restricted:
            break
			@unknown default:
				fatalError()
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
      let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for GymTracker in your iphone. Please go to Settings > Privacy > Location Services > Enable Thankyou!",
        preferredStyle: .alert)
      let okAction = UIAlertAction(title: "OK",style: .default,handler: nil)
        alert.addAction(okAction)
      present(alert, animated: true, completion: nil)
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
	private func configureButtons() {
		goToLocationButton.configuration = .tinted()
		goToLocationButton.configuration?.baseForegroundColor = .systemBlue
		goToLocationButton.configuration?.image = UIImage(systemName: "location.square")
		goToLocationButton.configuration?.buttonSize = .medium
		goToLocationButton.frame = CGRect(x: 300, y: 5, width: 50, height: 50)
		goToLocationButton.configuration?.imagePadding = 6
	
		centerOverRegionsButton.configuration = .tinted()
		centerOverRegionsButton.configuration?.baseForegroundColor = .red
		centerOverRegionsButton.configuration?.image = UIImage(systemName: "mappin.square")
		centerOverRegionsButton.configuration?.imagePadding = 6
		centerOverRegionsButton.frame = CGRect(x: 5, y: 5, width: 50, height: 50)
		
		let largeConfig = UIImage.SymbolConfiguration(pointSize: 35, weight: .bold, scale: .large)
		let largeBoldDoc = UIImage(systemName: "plus.circle.fill", withConfiguration: largeConfig)
		addNewButton.setImage(largeBoldDoc, for: .normal)
		addNewButton.configuration = .borderless()
		addNewButton.configuration?.baseForegroundColor = .systemGreen
		addNewButton.frame = CGRect(x: 269, y: 250, width: 100, height: 100)
	}
	
    private func configureUI() {

		NSLayoutConstraint.activate([
			tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
			tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
			tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
			tableView.bottomAnchor.constraint(equalTo: mapView.topAnchor, constant: -10)
			//tableView.heightAnchor.constraint(equalTo: view.frame.size.height/2)
		])
		NSLayoutConstraint.activate([
			mapView.topAnchor.constraint(equalTo: tableView.bottomAnchor),
			mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
			mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
			mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
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
        addLocationVC.delegate = self                                               //5
        present(navVC, animated: true)
    }
}

extension MainMapVC: CLLocationManagerDelegate {
 
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let status = manager.authorizationStatus
        /// This is what shows the blue dot on the screen
        mapView.showsUserLocation = (status == .authorizedAlways)
	
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
           showAlert(withTitle: "Error!", message: "Region Monitoring Failed!")
            return
        }
        lastLocationError = error
    }

    /// Convert to a readable address.
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
	
	//MARK: - ADDING A LOCATION AND OVERLAY TO THE MAP
	func add(_ location: Location) {
		locations.append(location)     // local, when I should really save and pull?? FRC was making the problem
		// call save here?
		 
	   mapView.addAnnotation(location)
	  //updateGeotificationsCount()
		mapView.addOverlay(MKCircle(center: location.coordinate, radius: location.radius))
		if !locations.isEmpty { showLocations() }
	}
}
//MARK: - CALL BACK FROM ADDLOCATIONVC
/// send back data delegate
extension MainMapVC: AddLocationVCDelegate {                                                    //6
    func addLocationVC(_ controller: AddLocationVC, didAddLocation location: Location) {
        controller.dismiss(animated: true, completion: nil)
        location.clampRadius(maxRadius: locationManager.maximumRegionMonitoringDistance)
        startMonitoring(location: location) ///Call start monitoring function
		add(location)    					// I am calling add here on way back from the delegate
    }
}

// MARK: - Map Annotation
extension MainMapVC: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    let identifier = "myGeotification"
    if annotation is Location {
      var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
								// this might be it
      if annotationView == nil {
        annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        annotationView?.canShowCallout = true
		   
        let removeButton = UIButton(type: .custom)
        removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
        removeButton.setImage(UIImage(systemName: "trash.fill"), for: .normal)
        annotationView?.leftCalloutAccessoryView = removeButton
          annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
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
				  
				  let logVC = LogVC()
				  logVC.location = location
				  navigationController?.pushViewController(logVC, animated: true)
				  
//                  let detailVC = DetailLocationVC()
//                  detailVC.titleString = location.title!
//                  navigationController?.pushViewController(detailVC, animated: true)
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
      locationManager.startMonitoring(for: fenceRegion) /// Initiate Geofencing
    }
    
    func stopMonitoring(location: Location) {
      for region in locationManager.monitoredRegions {
        guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == location.identifier else { continue }
        locationManager.stopMonitoring(for: circularRegion)
      }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
      guard let region = region else {
          showAlert(withTitle: "Error!", message: "Location Monitoring failed for unknown region")
        return
      }
        showAlert(withTitle: "Error!", message: "Monitoring failed for region with identifier: \(region.identifier)")
    }
}

extension MainMapVC: UITableViewDelegate, UITableViewDataSource {
	
	
	// currently the tableView is not using NSFRC
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let title1 = locations[indexPath.row].title
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
	    
		//let location = fetchedResultsController.object(at: indexPath)
		cell.textLabel?.text = title1//location.title
		return cell
	}
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		 return locations.count
//		let sectionInfo = fetchedResultsController.sections?[section]
//		return sectionInfo!.numberOfObjects
	 }
//	
//	func numberOfSections(in tableView: UITableView) -> Int {
//		//return fetchedResultsController.sections?.count ?? 2
//		return 1
//	}
//
	
	// 
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		//let location = fetchedResultsController.object(at: indexPath)
		let logVC = LogVC()
//		let indexPath = tableView.indexPathForSelectedRow!
//
//
		let location = locations[indexPath.row]
		logVC.location = location
		let destinationTitle = location.title
		logVC.title = destinationTitle

		//detailVC.titleString = location.title!
		navigationController?.pushViewController(logVC, animated: true)
//
//		let location = locations[indexPath.row]
//		let detailVC = DetailLocationVC()
//		detailVC.titleString = location.title ?? ""
//		navigationController?.pushViewController(detailVC, animated: true)
	}
}



// Here is Core Data
//extension MainMapVC {
//
//	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//		print("*** controllerWillChangeContent")
//		tableView.beginUpdates()
//	  }
//
//	  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,didChange anObject: Any,at indexPath: IndexPath?,
//		for type: NSFetchedResultsChangeType,
//		newIndexPath: IndexPath?) {
//		switch type {
//		case .insert:
//		  print("*** NSFetchedResultsChangeInsert (object)")
//		  tableView.insertRows(at: [newIndexPath!], with: .fade)
//
//		case .delete:
//		  print("*** NSFetchedResultsChangeDelete (object)")
//		  tableView.deleteRows(at: [indexPath!], with: .fade)
//
//			//THIS MIGHT BE A GOOD PLACE TO CHECK ?
//
//		case .update:
//		  print("*** NSFetchedResultsChangeUpdate (object)")
//			if let cell = tableView.cellForRow(at: indexPath!) {
//			let location = controller.object(at: indexPath!) as! Location
//				  // cell.configure(for: singer)
//				cell.textLabel?.text = location.title
//		  }
//
//		case .move:
//		  print("*** NSFetchedResultsChangeMove (object)")
//		  tableView.deleteRows(at: [indexPath!], with: .fade)
//		  tableView.insertRows(at: [newIndexPath!], with: .fade)
//
//		@unknown default:
//		  print("*** NSFetchedResults unknown type")
//		}
//	  }
//
//	  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo,
//		atSectionIndex sectionIndex: Int,
//		for type: NSFetchedResultsChangeType
//	  ) {
//		switch type {
//		case .insert:
//		  print("*** NSFetchedResultsChangeInsert (section)")
//		  tableView.insertSections(
//			IndexSet(integer: sectionIndex), with: .fade)
//		case .delete:
//		  print("*** NSFetchedResultsChangeDelete (section)")
//		  tableView.deleteSections(
//			IndexSet(integer: sectionIndex), with: .fade)
//		case .update:
//		  print("*** NSFetchedResultsChangeUpdate (section)")
//		case .move:
//		  print("*** NSFetchedResultsChangeMove (section)")
//		@unknown default:
//		  print("*** NSFetchedResults unknown type")
//		}
//	  }
//
//	  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//		print("*** controllerDidChangeContent")
//		tableView.endUpdates()
//	  }
//}
