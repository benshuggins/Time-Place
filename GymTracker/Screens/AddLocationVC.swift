//
//  AddLocationVC.swift
//  GymTracker
//
//  Created by Ben Huggins on 11/19/22.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

protocol AddLocationVCDelegate: class {
  func addLocationVC(_ controller: AddLocationVC, didAddLocation: Location)
}

let dateFormatter: DateFormatter = {
   let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
    }()

class AddLocationVC: UIViewController, MKMapViewDelegate, UITextFieldDelegate, MKAnnotation {
  
    var latitude: CLLocationDegrees!
    var longitude: CLLocationDegrees!
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    let searchController = UISearchController(searchResultsController: nil) // display in same view your searching
    
    var locations: [Location] = []
    weak var delegate: AddLocationVCDelegate?
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let geoCoder = CLGeocoder()
    var placeMark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?
    var address: String = ""
    
    //MARK: - LAYOUT DECLARATIONS
    var addRightButtonBar: UIBarButtonItem = {
        let button = UIBarButtonItem()
        return button
        }()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search"
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
        }()
    
    private let textFieldNote: UITextField = {
       let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.tintColor = .black
        textField.textColor = .black
        textField.backgroundColor = .darkGray
        textField.textAlignment = .left
        textField.attributedPlaceholder = NSAttributedString(string: "Enter Location Name",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
        textField.addTarget(self, action: #selector(didEnterNoteTextField), for: .editingChanged)
        return textField
        }()
    
    private let textFieldRadius: UITextField = {
       let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textAlignment = .left
        textField.placeholder = "Enter radius of circle"
        return textField
        }()
    
    let mapView : MKMapView = {
            let map = MKMapView()
            map.translatesAutoresizingMaskIntoConstraints = false
            map.overrideUserInterfaceStyle = .dark
            return map
        }()
    
    private let mappinImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(scale: .large)
        let image = UIImage(systemName: "mappin.circle", withConfiguration: config)
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .red
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // 1
        searchController.searchResultsUpdater = self
        // 2
        searchController.obscuresBackgroundDuringPresentation = false
        // 3
        searchController.searchBar.placeholder = "Search Candies"
        // 4
        navigationItem.searchController = searchController
        // 5
        definesPresentationContext = true
     
        
        
        title = "Add Location Tracker"
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.red]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        view.backgroundColor = .white
        view.addSubview(searchBar)
        view.addSubview(textFieldNote)
        view.addSubview(mapView)
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.addSubview(mappinImageView)
        configureUI()
        
        searchBar.delegate = self
        
        /// Center  over the user's location upon entry and call it in the background 
        performSelector(inBackground: #selector(didTapGoToYourLocationBarButton), with: .none )
        //MARK: - NAV BAR BUTTON ITEMS
        let addLocationImage = UIImage(systemName: "plus.circle.fill") //location.square.fill
        let goToLocationImage = UIImage(systemName: "location.square.fill")
        let zoomButton = UIBarButtonItem(image: goToLocationImage, style: .plain, target: self, action: #selector(didTapGoToYourLocationBarButton))
        addRightButtonBar = UIBarButtonItem(image: addLocationImage, style: .plain, target: self, action: #selector(didTapSaveLocationBarButton))
        zoomButton.tintColor = UIColor.red
        addRightButtonBar.tintColor = UIColor.red
        navigationItem.rightBarButtonItems = [addRightButtonBar, zoomButton]
        navigationItem.rightBarButtonItem?.isEnabled = (locations.count < 20)
        navigationController?.navigationBar.backgroundColor = .darkGray
        addRightButtonBar.isEnabled = false
        self.hideKeyboardWhenTappedAround()
        setupKeyBoard()
    }
    
    @objc func didTapGoToYourLocationBarButton() {
        print("DidTapZoomBarButton")
        mapView.zoomToLocation(mapView.userLocation.location)
    }
    
    private func setupKeyBoard() {
        setupKeyboardHiding() // add
    }

    private func setupKeyboardHiding() {
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
//
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handle(keyboardShowNotification:)),
                                               name: UIResponder.keyboardDidShowNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handle2(keyboardWillHideNotification:)),
                                               name: UIResponder.keyboardDidShowNotification,
                                               object: nil)
    }
    

    @objc private func handle(keyboardShowNotification notification: Notification) {
        // 1
        print("👍🏻👍🏻👍🏻👍🏻👍🏻👍🏻Keyboard show notification")
        
        // 2
        if let userInfo = notification.userInfo,
            // 3
            let keyboardRectangle = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
           // mappinImageView.frame.origin.y = keyboardRectangle.height + 50
            
            NSLayoutConstraint.activate([
                mapView.topAnchor.constraint(equalTo: textFieldNote.bottomAnchor),
                mapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                mapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
               // mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60)
            ])
        }
    }
    
    @objc private func handle2(keyboardWillHideNotification notification: Notification) {
        // 1
        print("👎🏻👎🏻👎🏻👎🏻👎🏻👎🏻👎🏻Keyboard Hide notification")
        
        // 2
        if let userInfo = notification.userInfo,
            // 3
            let keyboardRectangle = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
          //  mappinImageView.frame.origin.y = keyboardRectangle.height - 50
            
            NSLayoutConstraint.activate([
                mapView.topAnchor.constraint(equalTo: textFieldNote.bottomAnchor),
                mapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                mapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
               // mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 60)
            ])
           
        }
    }
    
//    @objc func keyboardWillShow(sender: NSNotification) {
//       // view.frame.origin.y = view.frame.origin.y - 170
//
//
//        mappinImageView.frame.origin.y = mappinImageView.frame.origin.y - 170
//    }
//    @objc func keyboardWillHide(notification: NSNotification) {
//      //  view.frame.origin.y = 0
//        mappinImageView.frame.origin.y = mapView.frame.height/2
//    }
    
    @objc func didEnterNoteTextField(_ textField: UITextField) {
        print(textField.text ?? "")
        let radiusSet = 40                                          // wrong ???
        let noteSet = !(textField.text?.isEmpty ?? true)
        addRightButtonBar.isEnabled = (radiusSet != 0) && noteSet
    }
    
    //MARK: - DELEGATE PASS BACK MODEL
    @objc func didTapSaveLocationBarButton() {
    
        let coordinate = mapView.centerCoordinate
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        let location1 = CLLocation(latitude: latitude, longitude: longitude)
        performingReverseGeocoding = true
       
        geoCoder.reverseGeocodeLocation(location1, completionHandler: { [self]
          placemarks, error in
            self.lastGeocodingError = error
    
            if error == nil, let p = placemarks, !p.isEmpty {
                self.placeMark = p.last!
            }
            self.performingReverseGeocoding = false
        })
       //MARK: RADIUS
        let date = Date()
        let radius: Double = 100
        let identifier = NSUUID().uuidString
        let note = textFieldNote.text ?? ""
        
        let location = DataManager.shared.location(title: note, date: date, identifier: identifier, latitude: latitude, longitude: longitude, radius: radius, placeMark: "No Address")
        DataManager.shared.save()
        
        //MARK: - HudView
       // let hudView = HudView.hud(inView: navigationController!.view, aninated: true)
        let hudView = HudView.hud(inView: view, aninated: true)
          hudView.text = "Tagged"
          afterDelay(0.7) {
              hudView.hide()
              self.delegate?.addLocationVC(self, didAddLocation: location)
          }
    }
    
    func format(date: Date) -> String {
        return dateFormatter.string(from: date)
    }

    //MARK: - LAYOUT CONSTRAINTS
    func configureUI() {
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            searchBar.bottomAnchor.constraint(equalTo: textFieldNote.topAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 60)
        ])
        NSLayoutConstraint.activate([
            textFieldNote.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            textFieldNote.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textFieldNote.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textFieldNote.heightAnchor.constraint(equalToConstant: 40),
            textFieldNote.bottomAnchor.constraint(equalTo: mapView.topAnchor)
        ])
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: textFieldNote.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        NSLayoutConstraint.activate([
            mappinImageView.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            mappinImageView.centerYAnchor.constraint(equalTo: mapView.centerYAnchor),
        ])
    }
}

extension AddLocationVC: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.isUserInteractionEnabled = false
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.style = UIActivityIndicatorView.Style.medium
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        
        view.addSubview(activityIndicator)
        searchBar.resignFirstResponder()
      //  dismiss(animated: true, completion: nil)
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchBar.text
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { (localSearchResponse, error) in
            
            activityIndicator.stopAnimating()
       
            if localSearchResponse == nil {
              
                let alertController = UIAlertController(title: nil, message: "Place Not Found", preferredStyle: UIAlertController.Style.alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
           
            } else {
                let latitude = localSearchResponse?.boundingRegion.center.latitude
                let longitude = localSearchResponse?.boundingRegion.center.longitude
                
//                let annotation = MKPointAnnotation()
//                annotation.title = searchBar.text
               let coordinateCenter = CLLocationCoordinate2DMake(latitude!, longitude!)
              //  self.mapView.addAnnotation(annotation)
                
               // let region = MKCoordinateRegion(center: coordinateCenter, latitudinalMeters: 10000, longitudinalMeters: 10000)
               // self.mapView.setCenter(coordinateCenter, animated: true)
             //   self.mapView.setCameraBoundary(coordinateCenter, animated: true)
              //  self.mapView.setRegion(region, animated: true)
            //    mapView.setCameraZoomRange(<#T##cameraZoomRange: MKMapView.CameraZoomRange?##MKMapView.CameraZoomRange?#>, animated: <#T##Bool#>)/
                
                
                 
        }
         }
    }
}

extension AddLocationVC {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(AddLocationVC.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    @objc func dismissKeyboard() {
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: textFieldNote.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
           // mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 60)
        ])
        view.endEditing(true)
    }
}

extension AddLocationVC: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
         
  }
}
