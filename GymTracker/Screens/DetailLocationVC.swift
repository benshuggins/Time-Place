//
//  DetailLocationVC.swift
//  GymTracker
//
//  Created by Ben Huggins on 11/27/22.
//
// Things to do
// reverse the tableView with predicates
// sum values within each section for the total predicates ?\
// add a searcb bar
// add the radius increaser
//




import UIKit
import CoreLocation
import CoreData
import MapKit

class DetailLocationVC: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    lazy var fetchedResultsController: NSFetchedResultsController<RegionEvent> = {
      let fetchRequest = NSFetchRequest<RegionEvent>()

      let entity = RegionEvent.entity()
      fetchRequest.entity = entity

      let sort1 = NSSortDescriptor(key: "sectionDate", ascending: true)   // just a date
      let sort2 = NSSortDescriptor(key: "enterRegionTime", ascending: true)
      fetchRequest.sortDescriptors = [sort1, sort2]

     //fetchRequest.fetchBatchSize = 20

      let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: "sectionDate", cacheName: "RegionEventsCache")

      fetchedResultsController.delegate = self
      return fetchedResultsController
    }()
    
    var titleString: String = ""
    var location = Location()
    var regionEvents: [RegionEvent] = []
    var locationsPredicate: NSPredicate?
    
    private let label: UILabel = {
       let label = UILabel()
        label.textColor = .black
        return label
    }()
    
    let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
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
                // loadSavedData()
            performFetch()
     
          //  loadSavedDataResults()
            let thisLocation = fetchLocation(title: titleString)
           // fetch the RegionEvents that match this Location 
            regionEvents = fetchRegions(locationIdentifier: thisLocation.identifier) // this holds our regionEvents
        }
    
    override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
       AppUtility.lockOrientation(.portrait)
   }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppUtility.lockOrientation(.all)
    }
    
    private func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error with fetchedResultsController \(error)")
        }
    }
    
    deinit {
        fetchedResultsController.delegate = nil
    }
    /// Get the location that matches the title location that was passed to this VC
    func fetchLocation(title: String) -> Location {
        
        do {
        let request = Location.fetchRequest() as NSFetchRequest<Location>  
            let pred = NSPredicate(format: "title == %@", titleString)
        request.predicate = pred
            location = try! context.fetch(request).first!
        } catch {
            print("Error: \(error)")
        }
        return location
    }
    
    // Fetches RegionEvents from a location identifier
    func fetchRegions(locationIdentifier: String) -> [RegionEvent] {
        
        var fetchedRegionEvents = [RegionEvent]()
        
                do {
                   // let request = RegionEvent.fetchRequest() as NSFetchRequest<RegionEvent>   // this is basic NSFEtch
                    let request: NSFetchRequest<RegionEvent> = NSFetchRequest<RegionEvent>(entityName: "RegionEvent")
                    let pred = NSPredicate(format: "ANY regionIdentifier == %@", locationIdentifier)
                    request.predicate = pred
                     fetchedRegionEvents = try! context.fetch(request)
        
                } catch {
                    print("Error: \(error)")
                }
        return fetchedRegionEvents
    }
    
    
    
//
//
//    func loadSavedData()   {
//        // Just get the Locations Associated with the title
//
//        do {
//        let request = Location.fetchRequest() as NSFetchRequest<Location>
//            let pred = NSPredicate(format: "title == %@", titleString)
//        request.predicate = pred
//            location = try! context.fetch(request).first!
//        print("😇😇😇😇😇😇😇Location: \(location)")
//
//        } catch {
//            print("Error: \(error)")
//        }
//
//        do {
//            let request = RegionEvent.fetchRequest() as NSFetchRequest<RegionEvent>
//            let pred = NSPredicate(format: "regionIdentifier == %@", location.identifier)
//            request.predicate = pred
//            regionEvents = try! context.fetch(request)
//
//        } catch {
//            print("Error: \(error)")
//        }
//    }
//
        @objc func changeFilter() {
            let ac = UIAlertController(title: "Filter Region Events…", message: nil, preferredStyle: .actionSheet)

            // 1
            ac.addAction(UIAlertAction(title: "Show Most Recent", style: .default) { [unowned self] _ in
                self.locationsPredicate = NSPredicate(format: "message CONTAINS[c] 'h'")
              //  self.fetchRegions(locationIdentifier: )
            })

            // 3 request only commits that took place 43,200 seconds ago
            ac.addAction(UIAlertAction(title: "Show Oldest", style: .default) { [unowned self] _ in
               // let twelveHoursAgo = Date().addingTimeInterval(-43200)
            //    self.locationsPredicate = NSPredicate(format: "date > %@", twelveHoursAgo as NSDate)
            //    self.loadSavedData()
            })

            ac.addAction(UIAlertAction(title: "Show Longest Time", style: .default) { [unowned self] _ in
                self.locationsPredicate = nil
              //  self.loadSavedData()
            })
            ac.addAction(UIAlertAction(title: "Show Shortest Time", style: .default) { [unowned self] _ in
                self.locationsPredicate = nil
             //   self.loadSavedData()
            })
            ac.addAction(UIAlertAction(title: "Show Errors", style: .default) { [unowned self] _ in
                self.locationsPredicate = nil
              //  self.loadSavedData()
            })

            ac.addAction(UIAlertAction(title: "Show Total Time for Location", style: .default) { [unowned self] _ in
                self.locationsPredicate = nil
                //self.loadSavedData()
            })
            // 4 show everything again
            ac.addAction(UIAlertAction(title: "Show All", style: .default) { [unowned self] _ in
                self.locationsPredicate = nil
              //  self.loadSavedData()
            })

            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(ac, animated: true)
        }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionInfo = fetchedResultsController.sections![section]
      
        var total = 0
        let subCategory = sectionInfo.objects as? [RegionEvent]
        /// This method sums the totalTime for each individual section
        for i in subCategory ?? [] {
            let name = i.sectionDate
            if name == i.sectionDate {
                if let unwrapped = i.totalRegionTime{
                    total += Int(unwrapped) ?? 0
                } else {
                }
            }
        }
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 28))
        headerView.backgroundColor = .secondarySystemBackground
        let sectionDateLabel = UILabel(frame: CGRect(x: 5, y: 5, width: 100, height: headerView.frame.size.height-10))
        sectionDateLabel.text = sectionInfo.name
        let totalLabel = UILabel(frame: CGRect(x: 100 + sectionDateLabel.frame.size.width, y: 5,width: 100, height: headerView.frame.size.height - 10))
        totalLabel.backgroundColor = .secondarySystemBackground
        totalLabel.text = "Total: \(total)  "
        totalLabel.textColor = .black
        headerView.addSubview(totalLabel)
        headerView.addSubview(sectionDateLabel)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }

     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         // let regionEvent = regionEvents[indexPath.row]
       
         let cell = tableView.dequeueReusableCell(withIdentifier: DetailTableViewCell.identifier, for: indexPath) as? DetailTableViewCell//UITableViewCell//
         
         let regionEvent = fetchedResultsController.object(at: indexPath)
         cell?.configure(regionEvent: regionEvent)
         return cell!
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] (action, view, completionHandler) in
//            self?.editRegionEventAction(indexPath: indexPath)
//            completionHandler(true)
//        }
//
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            self?.deleteRegionEventAction(indexPath: indexPath)
            completionHandler(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
//    private func editRegionEventAction(indexPath: IndexPath) {
//        let regionEvent = regionEvents[indexPath.row]
//       // let singer = singers[indexPath.row]
//        var enterTimeTextField = UITextField()
//        var exitTimeTextField = UITextField()
//
//        let alert = UIAlertController(title: "Edit Region Event Times", message: "", preferredStyle: .alert)
//        let editAction = UIAlertAction(title: "Edit", style: .default) { (action) in
//            regionEvent.setValue(enterTimeTextField.text ?? "", forKey: "enterRegionTime")
//            regionEvent.setValue(exitTimeTextField.text ?? "", forKey: "exitRegionTime")
//
//            try! self.context.save()   // Doesnt this throw?
//            self.tableView.reloadData()
//        }
//
//        alert.addTextField { (alertTextField) in
//            alertTextField.placeholder = "Edit Enter Time"
//            alertTextField.text = "\(regionEvent.enterRegionTime)"
//            enterTimeTextField = alertTextField
//        }
//
//        alert.addTextField { (alertTextField) in
//            alertTextField.placeholder = "Edit Exit Time"
//            alertTextField.text = "\(regionEvent.exitRegionTime)"
//            exitTimeTextField = alertTextField
//        }
//
//        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { (action) in
//            self.dismiss(animated: true, completion: nil)
//        }
//
//        alert.addAction(editAction)
//        alert.addAction(cancelAction)
//        present(alert, animated: true, completion: nil)
//    }
    
    private func deleteRegionEventAction(indexPath: IndexPath) {
       // let singer = singers[indexPath.row] // this is the old way
        let regionEvent = fetchedResultsController.object(at: indexPath)
       // tableView.deleteRows(at: [indexPath], with: .automatic)
        let areYouSureAlert = UIAlertController(title: "Are you sure you want to delete this Region Event?", message: "", preferredStyle: .alert)
        let yesDeleteAction = UIAlertAction(title: "Yes", style: .destructive) { [self] (action) in

            context.delete(regionEvent)
            do {
                try context.save()
               
            } catch {
                print("Error deleting object NSFetch: ", error)
            }
            //tableView.reloadData()
        }
        let noDeleteAction = UIAlertAction(title: "No", style: .default) { (action) in
            //do nothing
        }
        areYouSureAlert.addAction(noDeleteAction)
        areYouSureAlert.addAction(yesDeleteAction)
        self.present(areYouSureAlert, animated: true, completion: nil)
    }
    
}

//MARK: - NSFETCHRESULTSCONTROLLERDLEGATE
extension DetailLocationVC {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
      print("*** controllerWillChangeContent")
      tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,didChange sectionInfo: NSFetchedResultsSectionInfo,atSectionIndex sectionIndex: Int,for type: NSFetchedResultsChangeType) {
      switch type {
      case .insert:
        print("*** NSFetchedResultsChangeInsert (section)")
        tableView.insertSections(
          IndexSet(integer: sectionIndex), with: .fade)
      case .delete:
        print("*** NSFetchedResultsChangeDelete (section)")
        tableView.deleteSections(
          IndexSet(integer: sectionIndex), with: .fade)
         // tableView.deleteRows(at: [indexPath!], with: .fade)
      case .update:
        print("*** NSFetchedResultsChangeUpdate (section)")
      case .move:
        print("*** NSFetchedResultsChangeMove (section)")
      @unknown default:
        print("*** NSFetchedResults unknown type")
      }
    }
    
        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
          switch type {
          case .insert:
            print("*** NSFetchedResultsChangeInsert (object)")
            tableView.insertRows(at: [newIndexPath!], with: .fade)

          case .delete:
            print("*** NSFetchedResultsChangeDelete (object)")
            tableView.deleteRows(at: [indexPath!], with: .fade)

          case .update:
            print("*** NSFetchedResultsChangeUpdate (object)")
            if let cell = tableView.cellForRow(at: indexPath!) as? DetailTableViewCell {
              let regionEvent = controller.object(
                at: indexPath!) as! RegionEvent
                cell.configure(regionEvent: regionEvent)
                //cell.textLabel?.text = "\(regionEvent.enterRegionTime)"
            }

          case .move:
            print("*** NSFetchedResultsChangeMove (object)")
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)

          @unknown default:
            print("*** NSFetchedResults unknown type")
          }
        }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
      print("*** controllerDidChangeContent")
      tableView.endUpdates()
    }
}

//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//      switch type {
//      case .insert:
//        print("*** NSFetchedResultsChangeInsert (object)")
//        tableView.insertRows(at: [newIndexPath!], with: .fade)
//
//      case .delete:
//        print("*** NSFetchedResultsChangeDelete (object)")
//        tableView.deleteRows(at: [indexPath!], with: .fade)
//
//      case .update:
//        print("*** NSFetchedResultsChangeUpdate (object)")
//        if let cell = tableView.cellForRow(at: indexPath!) as? DetailTableViewCell {
//          let regionEvent = controller.object(
//            at: indexPath!) as! RegionEvent
//            cell.configure(regionEvent: regionEvent)
//            //cell.textLabel?.text = "\(regionEvent.enterRegionTime)"
//        }
//
//      case .move:
//        print("*** NSFetchedResultsChangeMove (object)")
//        tableView.deleteRows(at: [indexPath!], with: .fade)
//        tableView.insertRows(at: [newIndexPath!], with: .fade)
//
//      @unknown default:
//        print("*** NSFetchedResults unknown type")
//      }
//    }

//extension DetailLocationVC {
//
//    @objc public var messageDateSectionIdentifier: String? {
//        var dateString = ""
//        self.willAccessValue(forKey: "messageDateSectionIdentifier")
//        if let date = self.messageDateCreated {
//            let calendar = Formatters.calendar
//            let today = Date()
//            let yesterday = today.addingTimeInterval(-86400.0)
//            if calendar.isDate(date, inSameDayAs: today) {
//                dateString = LocalizedStrings.DateStrings.Today
//            } else if calendar.isDate(date, inSameDayAs: yesterday) {
//                dateString = LocalizedStrings.DateStrings.Yesterday
//            } else {
//                dateString = Formatters.messageDateFormatter.string(from: date)
//            }
//        }
//        self.didAccessValue(forKey: "messageDateSectionIdentifier")
//
//        return dateString
//    }
//
//}
    
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

//
//
//func loadSavedData()  {
//    // Just get the Locations Associated with the title
//
//    do {
//    let request = Location.fetchRequest() as NSFetchRequest<Location>
//        let pred = NSPredicate(format: "title == %@", titleString)
//    request.predicate = pred
//        location = try! context.fetch(request).first!
//    print("😇😇😇😇😇😇😇Location: \(location)")
//
//    } catch {
//        print("Error: \(error)")
//    }
//
//    do {
//        let request = RegionEvent.fetchRequest() as NSFetchRequest<RegionEvent>
//        let pred = NSPredicate(format: "regionIdentifier == %@", location.identifier)
//        request.predicate = pred
//        regionEvents = try! context.fetch(request)
//
//    } catch {
//        print("Error: \(error)")
//    }
//}
