//
//  AddLocationVC.swift
//  GymTracker
//
//  Created by Ben Huggins on 11/19/22.
//

import UIKit
import MapKit
import CoreLocation


protocol AddLocationVCDelegate: class {
  func addLocationVC(_ controller: AddLocationVC, didAddRegion: Regions)
}


class AddLocationVC: UIViewController, MKMapViewDelegate, UITextFieldDelegate {
    
    weak var delegate: AddLocationVCDelegate?
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
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
    
    var addRightButtonBar: UIBarButtonItem = {
       let button = UIBarButtonItem()
       return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Your Gym"
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.black]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        view.backgroundColor = .white
        view.addSubview(searchBar)
        view.addSubview(textFieldNote)
       // view.addSubview(textFieldRadius)
        view.addSubview(mapView)
        mapView.delegate = self
        mapView.showsUserLocation = true
        configureUI()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(didTapGoToYourLocationBarButton))
        
        addRightButtonBar = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapSaveLocationBarButton))
        navigationItem.rightBarButtonItem = addRightButtonBar
        addRightButtonBar.isEnabled = false
    }
    
    @objc func didEnterNoteTextField(_ textField: UITextField) {
        print(textField.text ?? "")
        let radiusSet = 40                                          // wrong ???
        let noteSet = !(textField.text?.isEmpty ?? true)
        addRightButtonBar.isEnabled = (radiusSet != 0) && noteSet
    }
    
    // This is where I build a model??
    @objc func didTapSaveLocationBarButton() {
        
        print("didTapAddButton")
        let coordinate = mapView.centerCoordinate
        
        
        let radius: Double = 40
        let identifier = NSUUID().uuidString
        let note = textFieldNote.text ?? ""
        let region = Regions(title: note, radius: radius, identifier: identifier, coordinate: coordinate)
        delegate?.addLocationVC(self, didAddRegion: region)
    }
    
    @objc func didTapGoToYourLocationBarButton() {
        print("DidTapZoomBarButton")
        mapView.zoomToLocation(mapView.userLocation.location)
    }
    
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
        
//        NSLayoutConstraint.activate([
//            textFieldRadius.topAnchor.constraint(equalTo: textFieldNote.bottomAnchor),
//            textFieldRadius.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
//            textFieldRadius.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
//            textFieldRadius.heightAnchor.constraint(equalToConstant: 60),
//            textFieldRadius.bottomAnchor.constraint(equalTo: mapView.topAnchor)
//        ])
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: textFieldNote.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
