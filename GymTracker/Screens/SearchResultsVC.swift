//
//  SearchResultsVC.swift
//  GymTracker
//
//  Created by Ben Huggins on 2/13/23.
//

import UIKit
import MapKit


//1
protocol sendSearchDataBackDelegate: class {
    func sendBackSearchData(_ controller: SearchResultsVC, placeMark: MKPlacemark)
}

class SearchResultsVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {
    
    var mapView: MKMapView? = nil
    var matchingItems:[MKMapItem] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    let tableView: UITableView = {
       let table = UITableView()
       table.register(SearchResultsTC.self, forCellReuseIdentifier: SearchResultsTC.identifier)
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    weak var delegate: sendSearchDataBackDelegate?  //2

    override func viewDidLoad() {
        super.viewDidLoad()
         navigationController?.navigationBar.isHidden = true
         tableView.frame = view.bounds
         tableView.delegate = self
         tableView.dataSource = self
         view.addSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         return 100
     }
     
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return matchingItems.count
     }
     
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultsTC.identifier) as! SearchResultsTC
        let selectedItem = matchingItems[indexPath.row].placemark
        cell.configureSelectedItem(selectedItem: selectedItem)  
        return cell
     }
     
     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         let placeMark = matchingItems[indexPath.row].placemark
         
         // Do a Core data save here and then pass it on back to the mainmapView and it will work
         self.delegate?.sendBackSearchData(self, placeMark: placeMark)  //3
         dismiss(animated: true, completion: nil)
     }

    func updateSearchResults(for searchController: UISearchController) {
      //  searchController.searchResultsController?.view.isHidden = false
        guard let mapView = mapView, let searchBarText = searchController.searchBar.text else { return }
        let request = MKLocalSearch.Request()
           request.naturalLanguageQuery = searchBarText
           request.region = mapView.region
           let search = MKLocalSearch(request: request)     /// This is the search request that gets
        search.start { [self] response, _ in
               guard let response = response else { return }
               self.matchingItems = response.mapItems          // these are the items that get returned
            print("Matching Items: ", self.matchingItems)
               self.tableView.reloadData()
       }
    }

}
