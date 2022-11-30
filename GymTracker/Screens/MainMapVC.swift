//
//  ViewController.swift
//  GymTracker
//
//  Created by Ben Huggins on 11/19/22.
//

// Check this is being updated

import UIKit
import MapKit
import CoreLocation

class MainMapVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let locationManager = CLLocationManager()
    
    private var models = [ToDoListItem]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    private let regionMeters: Double = 10000
    
    var regions: [Regions] = []  //SOT
    
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
      
//        let vc = AddLocationVC()
//        vc.delegate = self
        
        mapView.delegate = self
        title = "Gym Tracker"
        view.addSubview(mapView)
        //xview.addSubview(tableView)
        getAllItems()
        tableView.delegate = self
        tableView.dataSource = self
       // tableView.frame = view.bounds
        
        let addLocationImage = UIImage(systemName: "plus.circle.fill") //location.square.fill
        let goToLocationImage = UIImage(systemName: "location.square.fill")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapBarButton))
       // let add = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAddLocationBarButton))
        
        
        let addLocation = UIBarButtonItem(image: addLocationImage, style: .plain, target: self, action: #selector(didTapAddLocationBarButton))
       // let add = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(goToYourLocation))
        
        let zoom = UIBarButtonItem(image: goToLocationImage, style: .plain, target: self, action: #selector(goToYourLocation))
        
        navigationItem.rightBarButtonItems = [addLocation, zoom]
        
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
                headerView.clipsToBounds = true
        
//        headerView.addSubview(mapView)
//        tableView.tableHeaderView = headerView
 
        configureUI()
        checkLocationServices()
       
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
    
    
    // MARK: Functions that update the model/associated views with geotification changes
    func add(_ region: Regions) {
      regions.append(region)
      mapView.addAnnotation(region)
      addRadiusOverlay(forRegion: region)
      //updateGeotificationsCount()
    }
    
    func remove(_ region: Regions) {
      guard let index = regions.firstIndex(of: region) else { return }
      regions.remove(at: index)
      mapView.removeAnnotation(region)
      removeRadiusOverlay(forRegion: region)
     // updateGeotificationsCount()
    }
    
    // MARK: Map overlay functions
    func addRadiusOverlay(forRegion region: Regions) {
      mapView.addOverlay(MKCircle(center: region.coordinate, radius: region.radius))
    }
    
    func removeRadiusOverlay(forRegion region: Regions) {
      // Find exactly one overlay which has the same coordinates & radius to remove
//        guard let overlays = mapView.overlays else { return }
    let overlays = mapView.overlays
      for overlay in overlays {
        guard let circleOverlay = overlay as? MKCircle else { continue }
        let coord = circleOverlay.coordinate
        if coord.latitude == region.coordinate.latitude &&
          coord.longitude == region.coordinate.longitude &&
          circleOverlay.radius == region.radius {
          mapView.removeOverlay(circleOverlay)
          break
        }
      }
    }
    
    
    
    // MARK: -
    // MARK: LAYOUT CONFIGURATION
    
    //LAYOUT CONFIGURATION
    
    private func configureUI() {
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc func goToYourLocation() {
        mapView.zoomToLocation(mapView.userLocation.location)
    }
    
    @objc func didTapAddLocationBarButton() {
        let addLocationVC = AddLocationVC()
        let navVC = UINavigationController(rootViewController: addLocationVC)
        addLocationVC.delegate = self   //2                                            // this is the delegate
        present(navVC, animated: true)
    }
    
    @objc func didTapBarButton() {
        let alert = UIAlertController(title: "Add Entry", message: "add", preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        alert.addAction(UIAlertAction(title: "Add item", style: .cancel, handler: { [weak self] _ in
        
            guard let field = alert.textFields?.first, let text = field.text, !text.isEmpty else {
                return
            }
            self?.createItem(name: text)
        }))
            present(alert, animated: true)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        guard let name = model.name else {return cell}
        guard let date = model.createdAt else {return cell}
        
        let formatter2 = DateFormatter()
        formatter2.timeStyle = .medium
        formatter2.dateStyle = .medium
        //print(formatter2.string(from: today))
        
        cell.textLabel?.text =  "\(name) - \(formatter2.string(from: date))"
   
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = models[indexPath.row]
        
        let sheet = UIAlertController(title: "Edit", message: nil, preferredStyle: .actionSheet)
      
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        sheet.addAction(UIAlertAction(title: "Edit", style: .default, handler: { _ in
           
            
            
            let alert = UIAlertController(title: "Edit Item", message: "add", preferredStyle: .alert)
            alert.addTextField(configurationHandler: nil)
            alert.textFields?.first?.text = item.name
            alert.addAction(UIAlertAction(title: "Save", style: .cancel, handler: { [weak self] _ in
            
                guard let field = alert.textFields?.first, let newName = field.text, !newName.isEmpty else {
                    return
                }
                self?.updateItem(item: item, newName: newName)
            }))
            self.present(alert, animated: true)
            
            
            
        }))
        sheet.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            
            self?.deleteItem(item: item)
        }))
            present(sheet, animated: true)
        
    }
    
    
    // CoreData
    func getAllItems() {
        do {
            models = try context.fetch(ToDoListItem.fetchRequest())
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
           
        } catch {
          // handle error
        }
    }
    
    func createItem(name: String) {
        let newItem = ToDoListItem(context: context)
        newItem.name = name
        newItem.createdAt = Date()
        
        do {
            try context.save()
            getAllItems()
        } catch {
            
        }
    }
    
    func deleteItem(item: ToDoListItem) {
        context.delete(item)
        
        do {
            try context.save()
            getAllItems()
        } catch {
            
        }
    }

    func updateItem(item: ToDoListItem, newName: String ) {
        item.name = newName
        do {
            try context.save()
            getAllItems()
        } catch {
            
        }
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
}

extension MainMapVC: AddLocationVCDelegate {  // 1
   
    func addLocationVC(_ controller: AddLocationVC, didAddRegion region: Regions) {
        controller.dismiss(animated: true, completion: nil)
        region.clampRadius(maxRadius: locationManager.maximumRegionMonitoringDistance)
        add(region)
    }
}

// This adds an annotation to the map
// MARK: - Map Annotation
extension MainMapVC: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    let identifier = "myGeotification"
   
    if annotation is Regions {
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
    if overlay is MKCircle {
      let circleRenderer = MKCircleRenderer(overlay: overlay)
      circleRenderer.lineWidth = 1.0
      circleRenderer.strokeColor = .purple
      circleRenderer.fillColor = UIColor.purple.withAlphaComponent(0.4)
      return circleRenderer
    }
    return MKOverlayRenderer(overlay: overlay)
  }
    
  func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    // Delete geotification
    guard let region = view.annotation as? Regions else { return }
      
      
      if control == view.leftCalloutAccessoryView {
                  print("left accessory selected")
          remove(region)
          
              } else if control == view.rightCalloutAccessoryView {
                  
                  
                  print(region.title)
                  let detailVC = DetailLocationVC()
                  detailVC.titleString = region.title!
                  navigationController?.pushViewController(detailVC, animated: true)
                  print("right accessory selected")
              }
  
   // saveAllGeotifications()
  }
}
