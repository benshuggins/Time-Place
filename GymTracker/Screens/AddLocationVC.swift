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

protocol AddLocationVCDelegate: AnyObject {
  func addLocationVC(_ controller: AddLocationVC, didAddLocation: Location)
}

let dateFormatter: DateFormatter = {
   let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
    }()

class AddLocationVC: UIViewController, MKMapViewDelegate, UITextFieldDelegate {
  
	var isKeyBoardShowing: Bool = false
    var searchController = UISearchController(searchResultsController: SearchResultsVC())
    var selectedPin: MKPlacemark? = nil
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
    
    private let textFieldNote: UITextField = {
       let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.tintColor = .black
        textField.textColor = .black
        textField.backgroundColor = .darkGray
        textField.textAlignment = .left
        textField.attributedPlaceholder = NSAttributedString(string: " Enter Location Name via the map marker",
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
    
   private let mapView : MKMapView = {
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
        view.addSubview(textFieldNote)
        view.addSubview(mapView)
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.addSubview(mappinImageView)
        navigationItem.searchController = searchController
        title = "Add Location Tracker"
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.black]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        view.backgroundColor = .white

        /// Center  over the user's location upon entry and call it in the background 
        performSelector(inBackground: #selector(didTapGoToYourLocationBarButton), with: .none )
        //MARK: - NAV BAR BUTTON ITEMS
        let addLocationImage = UIImage(systemName: "plus.circle.fill") //location.square.fill
        let goToLocationImage = UIImage(systemName: "location.square.fill")
        let zoomButton = UIBarButtonItem(image: goToLocationImage, style: .plain, target: self, action: #selector(didTapGoToYourLocationBarButton))
        addRightButtonBar = UIBarButtonItem(image: addLocationImage, style: .plain, target: self, action: #selector(didTapSaveLocationBarButton))
        zoomButton.tintColor = UIColor.blue
        addRightButtonBar.tintColor = UIColor.systemGreen
        navigationItem.rightBarButtonItems = [addRightButtonBar, zoomButton]
        navigationItem.rightBarButtonItem?.isEnabled = (locations.count < 20)
        navigationController?.navigationBar.backgroundColor = .darkGray
        addRightButtonBar.isEnabled = false
		configureUI()
        self.hideKeyboardWhenTappedAround()

        // MARK: - SEARCH CONTROLLER
	    let searchResultsVC = SearchResultsVC()
	    searchResultsVC.delegate = self
        searchController = UISearchController(searchResultsController: searchResultsVC)
        searchController.searchResultsUpdater = searchResultsVC as UISearchResultsUpdating
        searchController.hidesNavigationBarDuringPresentation = true
        let searchBar = searchController.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for a place to add"
        navigationItem.searchController = searchController
        searchResultsVC.mapView = mapView
		
		if isFirstLaunch() {
			showAlert(withTitle: "Add your location 2 ways!", message: "Please add a location using the searchbar or by placing marker over desired location via the map and giving it a name!")
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
	}
    
    @objc func didTapGoToYourLocationBarButton() {
        print("DidTapZoomBarButton")
        mapView.zoomToLocation(mapView.userLocation.location)
    }
	
	// first app launch
	func isFirstLaunch() -> Bool {

		if (!UserDefaults.standard.bool(forKey: "launched_before")) {
			UserDefaults.standard.set(true, forKey: "launched_before")
			return true
		}
		return false
	}
    
    func format(date: Date) -> String {
       return dateFormatter.string(from: date)
   }

   //MARK: - LAYOUT CONSTRAINTS
   func configureUI() {
	   ///self.view.frame.origin.y = 0
       NSLayoutConstraint.activate([
           textFieldNote.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
           textFieldNote.leadingAnchor.constraint(equalTo: view.leadingAnchor),
           textFieldNote.trailingAnchor.constraint(equalTo: view.trailingAnchor),
           textFieldNote.heightAnchor.constraint(equalToConstant: 40),
           textFieldNote.bottomAnchor.constraint(equalTo: mapView.topAnchor)
       ])
       NSLayoutConstraint.activate([
           mapView.topAnchor.constraint(equalTo: textFieldNote.bottomAnchor),
           mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
           mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
           mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
       ])
       NSLayoutConstraint.activate([
           mappinImageView.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
           mappinImageView.centerYAnchor.constraint(equalTo: mapView.centerYAnchor)
       ])
   }

    @objc func didEnterNoteTextField(_ textField: UITextField) {
		
		if isKeyBoardShowing == true {
			configureUI()
		}
        let radiusSet = 40                                          
        let noteSet = !(textField.text?.isEmpty ?? true)
        addRightButtonBar.isEnabled = (radiusSet != 0) && noteSet
    }
    
    //MARK: - Save location from manual pan and zoom option
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
        
        let hudView = HudView.hud(inView: view, aninated: true)
          hudView.text = "Tagged"
		afterDelay(1.0) {
              hudView.hide()
              self.delegate?.addLocationVC(self, didAddLocation: location)
        }
    }
}

//MARK: Save from search bar
extension AddLocationVC: sendSearchDataBackDelegate {
   func sendBackSearchData(_ controller: SearchResultsVC, placeMark placemark: MKPlacemark) {
       let note = placemark.name
       let date = Date()
       let identifier = NSUUID().uuidString
       let radius: Double = 100
       let latitude = placemark.coordinate.latitude
       let longitude = placemark.coordinate.longitude
       
       let location = DataManager.shared.location(title: note ?? "No Title", date: date, identifier: identifier, latitude: latitude, longitude: longitude, radius: radius, placeMark: "No Address")
       DataManager.shared.save()
       
       let hudView = HudView.hud(inView: view, aninated: true)
         hudView.text = "Tagged"
         afterDelay(0.7) {
			 hudView.hide()
			 self.delegate?.addLocationVC(self, didAddLocation: location)
			 self.navigationController?.popViewController(animated: true)
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
        ])
        view.endEditing(true)
    }
}
