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
        let image = UIImage(systemName: "mappin.circle")
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
        
//mappinImageView.frame = CGRect(x: 150, y: 100, width: 20, height: 20)
        mapView.addSubview(mappinImageView)
        
        
        configureUI()
        
        //MARK: - BUTTON BAR ITEMS
        let addLocationImage = UIImage(systemName: "plus.circle.fill") //location.square.fill
        let goToLocationImage = UIImage(systemName: "location.square.fill")
        
        let zoomButton = UIBarButtonItem(image: goToLocationImage, style: .plain, target: self, action: #selector(didTapGoToYourLocationBarButton))
        addRightButtonBar = UIBarButtonItem(image: addLocationImage, style: .plain, target: self, action: #selector(didTapSaveLocationBarButton))
        navigationItem.rightBarButtonItems = [addRightButtonBar, zoomButton]
        addRightButtonBar.isEnabled = false
    }
    
    @objc func didEnterNoteTextField(_ textField: UITextField) {
        print(textField.text ?? "")
        let radiusSet = 40                                          // wrong ???
        let noteSet = !(textField.text?.isEmpty ?? true)
        addRightButtonBar.isEnabled = (radiusSet != 0) && noteSet
    }
    
    @objc func didTapSaveLocationBarButton() {
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
