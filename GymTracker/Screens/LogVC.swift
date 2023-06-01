//
//  LogVC.swift
//  GymTracker
//
//  Created by Ben Huggins on 3/31/23.
//

import UIKit
import CoreData

class LogVC: UIViewController {
	
	var regionEvents = [RegionEvent]()
	//var index = Int()
	var location: Location!
	
	let tableView: UITableView = {
	   let table = UITableView()
		table.register(LogVCTableViewCell.self, forCellReuseIdentifier: LogVCTableViewCell.identifier)
		table.translatesAutoresizingMaskIntoConstraints = false
		return table
	}()

    override func viewDidLoad() {
        super.viewDidLoad()
		view.backgroundColor = .red
		view.addSubview(tableView)
		tableView.delegate = self
		tableView.dataSource = self
		tableView.frame = view.bounds
		tableView.contentInset = UIEdgeInsets.zero
	//	print("😍😍😍😍😍😍Location: ", location.regionEvent)
		
		regionEvents = DataManager.shared.getRegionEvents(location: location)
		
		print("😍😍😍😍😍😍  Region Events: ", regionEvents)
    }
	
//	init(index: Int) {
//		self.index = index
//		location = location[index]
//		super.init(nibName: nil, bundle: nil)
//	}
	
//	required init?(coder: NSCoder) {
//		fatalError("init(coder:) has not been implemented")
//	}
//	
//   

}
extension LogVC: UITableViewDelegate, UITableViewDataSource {
	
//	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//		return 40
//	}
	
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 120
	}
	
//	func numberOfSections(in tableView: UITableView) -> Int {
//		return regionEvents.sectionDate.count
//	}

	
   
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return regionEvents.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let regionEvent = regionEvents[indexPath.row]
		
		let cell = tableView.dequeueReusableCell(withIdentifier: LogVCTableViewCell.identifier, for: indexPath) as! LogVCTableViewCell
		
		cell.configure(regionEvent: regionEvent)
	//	cell.textLabel?.text = regionEvent.regionIdentifier    //location.regionEvent?.totalRegionTime
		//cell.detailTextLabel?.text = "\(location.regionEvent?.enterRegionTime)"
		//cell.detailTextLabel?.text = //song.releaseDate
		
		return cell
		
	}
}
