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
		textField.textColor = UIColor.lightGray
		textField.layer.cornerRadius = 6
		textField.backgroundColor = .systemGray3						//" Enter Location Name via the map marker"
        textField.textAlignment = .left								//"Enter map marker name..."
        textField.attributedPlaceholder = NSAttributedString(string: " Enter map marker name...",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
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
	
	private let textFieldBackingView: UIView = {
		let backView = UIView()
		backView.backgroundColor = .systemGray3
		backView.translatesAutoresizingMaskIntoConstraints = false
		return backView
	}()
	
	private let keyBoardBackingView: UIView = {
		let keyBackView = UIView()
		keyBackView.backgroundColor = .systemGray3
		keyBackView.translatesAutoresizingMaskIntoConstraints = false
		return keyBackView
	}()
		
    
    override func viewDidLoad() {
        super.viewDidLoad()
		view.backgroundColor = .lightGray
        view.addSubview(mapView)
		view.addSubview(textFieldBackingView)
		
		view.addSubview(keyBoardBackingView)  
		
		textFieldBackingView.addSubview(textFieldNote)
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
		zoomButton.tintColor = .systemBlue
        addRightButtonBar.tintColor = UIColor.systemGreen
        navigationItem.rightBarButtonItems = [addRightButtonBar, zoomButton]
        navigationItem.rightBarButtonItem?.isEnabled = (locations.count < 20)
        navigationController?.navigationBar.backgroundColor = .darkGray
        addRightButtonBar.isEnabled = false
		configureUI()
        //self.hideKeyboardWhenTappedAround()

        // MARK: - SEARCH CONTROLLER
	    let searchResultsVC = SearchResultsVC()
	    searchResultsVC.delegate = self
        searchController = UISearchController(searchResultsController: searchResultsVC)
        searchController.searchResultsUpdater = searchResultsVC as UISearchResultsUpdating
        searchController.hidesNavigationBarDuringPresentation = false  // true
        let searchBar = searchController.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search online for a place to add"
		searchBar.showsCancelButton = false
        navigationItem.searchController = searchController
        searchResultsVC.mapView = mapView
		///Hide the suggestion bar above the keyboard
		textFieldNote.spellCheckingType = .no
		textFieldNote.autocorrectionType = .no
		searchBar.spellCheckingType = .no
		searchBar.autocorrectionType = .no
		
		if isFirstLaunch() {
			showAlert(withTitle: "You can add locations 2 ways.", message: "Use either the search bar or move the map. Use the keyboard to give it a name.")
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
		textFieldNote.becomeFirstResponder()
		
		//searchController.becomeFirstResponder()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
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
           textFieldNote.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
           textFieldNote.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
           textFieldNote.heightAnchor.constraint(equalToConstant: 45),
           textFieldNote.bottomAnchor.constraint(equalTo: mapView.topAnchor)
       ])
	   
	   NSLayoutConstraint.activate([
		textFieldBackingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
		textFieldBackingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
		textFieldBackingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
		textFieldBackingView.heightAnchor.constraint(equalToConstant: 45),
		textFieldBackingView.bottomAnchor.constraint(equalTo: mapView.topAnchor)
	   ])
	   
       NSLayoutConstraint.activate([
           mapView.topAnchor.constraint(equalTo: textFieldNote.bottomAnchor),
           mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
           mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
           mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -200)
       ])
       NSLayoutConstraint.activate([
           mappinImageView.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
           mappinImageView.centerYAnchor.constraint(equalTo: mapView.centerYAnchor)
       ])
	   
	   NSLayoutConstraint.activate([
		  keyBoardBackingView.topAnchor.constraint(equalTo: mapView.bottomAnchor),
		  keyBoardBackingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
		  keyBoardBackingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
		  keyBoardBackingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
	   ])
   }

    @objc func didEnterNoteTextField(_ textField: UITextField) {
		if isKeyBoardShowing == true {
			configureUI()
		}
        let radiusSet = 100
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

