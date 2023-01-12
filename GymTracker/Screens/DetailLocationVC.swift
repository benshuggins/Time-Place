//
//  DetailLocationVC.swift
//  GymTracker
//
//  Created by Ben Huggins on 11/27/22.
//

// This is the detail setup page

// Local Push notifications
// Graph
// Log




import UIKit
import CoreLocation
import CoreData
import MapKit

class DetailLocationVC: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource {
 
    var titleString: String = ""
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//    var locations = [Locations]()
    var location = Location()
   // var regionEvent = [RegionEvent]()
    var regionEvents: [RegionEvent] = []
    
    var locationsPredicate: NSPredicate?
    
    private let label: UILabel = {
       let label = UILabel()
        label.textColor = .black
        return label
    }()
    
    let tableView: UITableView = {
        let table = UITableView()
        table.register(DetailTableViewCell.self, forCellReuseIdentifier: DetailTableViewCell.identifier)
       return table
    }()
    
        override func viewDidLoad() {
            super.viewDidLoad()
          //  view.addSubview(label)
            title = titleString
            view.addSubview(tableView)
            tableView.delegate = self
            tableView.dataSource = self
            view.backgroundColor = .white
            tableView.frame = view.bounds
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(changeFilter))
         loadSavedData()
           // loadRegion(location2)
        }
    
        @objc func changeFilter() {
            let ac = UIAlertController(title: "Filter Region Events…", message: nil, preferredStyle: .actionSheet)

            // 1
            ac.addAction(UIAlertAction(title: "Show Most Recent", style: .default) { [unowned self] _ in
                self.locationsPredicate = NSPredicate(format: "message CONTAINS[c] 'h'")
                self.loadSavedData()
            })
          
            // 3 request only commits that took place 43,200 seconds ago
            ac.addAction(UIAlertAction(title: "Show Oldest", style: .default) { [unowned self] _ in
                let twelveHoursAgo = Date().addingTimeInterval(-43200)
                self.locationsPredicate = NSPredicate(format: "date > %@", twelveHoursAgo as NSDate)
                self.loadSavedData()
            })
            
            ac.addAction(UIAlertAction(title: "Show Longest Time", style: .default) { [unowned self] _ in
                self.locationsPredicate = nil
                self.loadSavedData()
            })
            ac.addAction(UIAlertAction(title: "Show Shortest Time", style: .default) { [unowned self] _ in
                self.locationsPredicate = nil
                self.loadSavedData()
            })
            ac.addAction(UIAlertAction(title: "Show Errors", style: .default) { [unowned self] _ in
                self.locationsPredicate = nil
                self.loadSavedData()
            })
            
            ac.addAction(UIAlertAction(title: "Show Total Time for Location", style: .default) { [unowned self] _ in
                self.locationsPredicate = nil
                self.loadSavedData()
            })
            // 4 show everything again
            ac.addAction(UIAlertAction(title: "Show All", style: .default) { [unowned self] _ in
                self.locationsPredicate = nil
                self.loadSavedData()
            })

            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(ac, animated: true)
        }
   
    

    func loadSavedData()  {
        // Just get the Locations Associated with the title
       
        do {
        let request = Location.fetchRequest() as NSFetchRequest<Location>
            let pred = NSPredicate(format: "title == %@", titleString)
        request.predicate = pred
            location = try! context.fetch(request).first!
        print("😇😇😇😇😇😇😇Location: \(location)")
            
        } catch {
            print("Error: \(error)")
        }
        

        do {
            let request = RegionEvent.fetchRequest() as NSFetchRequest<RegionEvent>
            let pred = NSPredicate(format: "regionIdentifier == %@", location.identifier)
            request.predicate = pred
            regionEvents = try! context.fetch(request)


        } catch {
            print("Error: \(error)")

        }
        
        print("RegionEvents: ", regionEvents)
        
        print(regionEvents.count)
       
        print(regionEvents.first?.enterRegionTime)
    }
   
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return regionEvents.count
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let regionEvent = regionEvents[indexPath.row]
       
         let cell = tableView.dequeueReusableCell(withIdentifier: DetailTableViewCell.identifier, for: indexPath) as? DetailTableViewCell 
             
         cell?.configure(regionEvent: regionEvent)
         

         return cell!
    }
    
}
    
//    lazy var fetchedResultsController: NSFetchedResultsController<Locations> = {
//      let fetchRequest = NSFetchRequest<Locations>()
//
//      let entity = Locations.entity()
//      fetchRequest.entity = entity
//
//      let sort1 = NSSortDescriptor(key: "title", ascending: true)
//    //  let sort2 = NSSortDescriptor(key: "date", ascending: true)
//      fetchRequest.sortDescriptors = [sort1]
//
//      fetchRequest.fetchBatchSize = 20
//
//      let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,managedObjectContext: self.context, sectionNameKeyPath: "title",
//        cacheName: "Locations")
//
//      fetchedResultsController.delegate = self
//      return fetchedResultsController
//    }()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.addSubview(label)
//        view.addSubview(tableView)
//        tableView.delegate = self
//        tableView.dataSource = self
//        title = "Core Data Filtering"
//        view.backgroundColor = .white
//
////        label.text = titleString
////        // Do any additional setup after loading the view.
////        label.frame = CGRect(x: 50, y: 100, width: 200, height: 55)
//
//        performFetch()
//    }
//
//
//    deinit {
//      fetchedResultsController.delegate = nil
//    }
//
//    // MARK: - Helper methods
//    func performFetch() {
//      do {
//        try fetchedResultsController.performFetch()
//      } catch {
//        fatalCoreDataError(error)
//      }
//    }
//
////    // MARK: - Table View Delegates
////     func numberOfSections(in tableView: UITableView) -> Int {
////      return fetchedResultsController.sections!.count
////    }
//
//
//    func tableView(_ tableView: UITableView,numberOfRowsInSection section: Int) -> Int {
////      let sectionInfo = fetchedResultsController.sections![section]
////      return sectionInfo.numberOfObjects
//        return 10
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//      let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
//
//        let location = fetchedResultsController.object(at: indexPath)
//
//        cell.textLabel?.text = "hey"
//
//        return cell
//
//}

