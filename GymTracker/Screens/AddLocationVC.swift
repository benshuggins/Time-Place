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
  func addLocationVC(_ controller: AddLocationVC, didAddLocation: Locations)
}

let dateFormatter: DateFormatter = {
   let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
    }()

class AddLocationVC: UIViewController, MKMapViewDelegate, UITextFieldDelegate {

    var locations: [Locations] = []
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
        searchBar.placeholder = "Search for Gym"
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
        }()
    
    private let textFieldNote: UITextField = {
       let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.tintColor = .black
        textField.textColor = .black
        textField.textAlignment = .left
        textField.attributedPlaceholder = NSAttributedString(
            string: "Enter Gym Name - Place Pin over Gym - Tap +",
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
        title = "Add Your Gym"
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.black]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        view.backgroundColor = .white
        view.addSubview(searchBar)
        view.addSubview(textFieldNote)
        view.addSubview(mapView)
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.addSubview(mappinImageView)
        configureUI()
        
        //MARK: - BUTTON BAR ITEMS
        let addLocationImage = UIImage(systemName: "plus.circle.fill") //location.square.fill
        let goToLocationImage = UIImage(systemName: "location.square.fill")
        let zoomButton = UIBarButtonItem(image: goToLocationImage, style: .plain, target: self, action: #selector(didTapGoToYourLocationBarButton))
        addRightButtonBar = UIBarButtonItem(image: addLocationImage, style: .plain, target: self, action: #selector(didTapSaveLocationBarButton))
        navigationItem.rightBarButtonItems = [addRightButtonBar, zoomButton]
        navigationItem.rightBarButtonItem?.isEnabled = (locations.count < 20) // Only allow a maximum of 20 tags according to apple, disable the add button
        addRightButtonBar.isEnabled = false
        setupKeyBoard()
    }
    
    private func setupKeyBoard() {
        setupKeyboardHiding() // add
    }

    private func setupKeyboardHiding() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
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
        let location1 = CLLocation(latitude: latitude, longitude: longitude)  // location Object
        performingReverseGeocoding = true
        geoCoder.reverseGeocodeLocation(location1, completionHandler: { [self]
            
          placemarks, error in
            self.lastGeocodingError = error
            
            print("PlaceMarks: \(placemarks?.last)")
            
            if error == nil, let p = placemarks, !p.isEmpty {
                self.placeMark = p.last!
                print("Address👹👹👹👹👹👹: \(p)")
            }

            self.performingReverseGeocoding = false
        })
        
        let date = Date()
        
        print("😇😇😇😇😇😇😇date: \(format(date: date))")
        
        let radius: Double = 500
        let identifier = NSUUID().uuidString // This is a unique randomly generated identifier for each location
        let note = textFieldNote.text ?? ""
        let locations = Locations(context: self.context)
        locations.placeMark = placeMark
        locations.title = note
        locations.radius = radius
        locations.longitude = longitude
        locations.latitude = latitude
        locations.identifier = NSUUID().uuidString
        locations.date = Date()
        
        //MARK: - CORE DATA SAVE
        do {
            try context.save()
        } catch {
            fatalCoreDataError(error)
        }
        delegate?.addLocationVC(self, didAddLocation: locations) //3 }
    }
    
    func format(date: Date) -> String {
        return dateFormatter.string(from: date)
    }

    @objc func didTapGoToYourLocationBarButton() {
        print("DidTapZoomBarButton")
        mapView.zoomToLocation(mapView.userLocation.location)
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
            textFieldNote.heightAnchor.constraint(equalToConstant: 60),
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
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(searchText)
    }
}

// MARK: Keyboard
extension AddLocationVC {
    @objc func keyboardWillShow(sender: NSNotification) {
        view.frame.origin.y = view.frame.origin.y - 170
    }
    @objc func keyboardWillHide(notification: NSNotification) {
        view.frame.origin.y = 0
    }
}

