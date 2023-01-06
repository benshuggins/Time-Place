//
//  LeftMenuVC.swift
//  GymTracker
//
//  Created by Ben Huggins on 1/1/23.
//

import UIKit
import AuthenticationServices

class LeftMenuVC: UIViewController {
    
    var sectionTitles = ["About Demo App", "Developer", "Ben Huggins URL", "Get Code", "LOGOUT"]
        var sectionContent = [["How App Works"],["Linkedin","Github"],["My Website"],["Youtube"], ["LOGOUT"]]
       
    let tableView: UITableView = {
       let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
       // table.register(RightTableHeaderCell.self, forHeaderFooterViewReuseIdentifier: "header")
        return table
    }()
    
//    override func viewWillAppear(_ animated: Bool) {
//        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.all, andRotateTo: UIInterfaceOrientation.portrait)
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        self.view.layer.cornerRadius = 20
        self.view.layer.masksToBounds = true
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        if #available(iOS 13.0, *) {
                    navigationController?.navigationBar.prefersLargeTitles = true
                    navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
                } else {
                    // Fallback on earlier versions
                }
                // remove bottom blank cells in the table view
                tableView.tableFooterView = UIView(frame: CGRect.zero)
        
                //iPad Layout: adds blank space to the left and right of the table view
                tableView.cellLayoutMarginsFollowReadableWidth = true
                
                // Remove text 'Settings' from back button
                navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
}
    extension LeftMenuVC: UITableViewDelegate, UITableViewDataSource {
    
         func numberOfSections(in tableView: UITableView) -> Int {
                return sectionTitles.count
            }
            
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                
                switch section {
                case 0:
                    return sectionContent[0].count      // section 0 is ABOUT APP
                case 1:
                    return sectionContent[1].count      // section 1 is the 2nd section 'Api Used'
                case 2:
                    return sectionContent[2].count      // section 2 is the 3rd section 'Get Code'
                case 3:
                    return sectionContent[3].count      // section 2 is the 3rd section 'Get Code'
                case 4:
                    return sectionContent[4].count
                default:
                    return sectionContent[0].count
                }
        }
    
            func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
                return sectionTitles[section]  // section 0 is the 1st section
            }
        
            func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            //cell.accessoryType = .disclosureIndicator
                // Configure the cell...array of content within array of headers
                cell.textLabel?.text = sectionContent[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
                
                switch (indexPath as NSIndexPath).section {
                    
                case 0:  // Section 0 ABOUT APP
                    cell.accessoryType = .disclosureIndicator
                   
                case 1: // Section 1 Developer
                    cell.accessoryType = .none
                    
                case 2:  // Section 2 API USED
                    cell.accessoryType = .none
                    
                case 3:  // Section 3 LOGOUT
                    cell.accessoryType = .none
                case 4:  // Section 3 LOGOUT
                    cell.accessoryType = .none
                    
                
        default: break
                }
                return cell
            }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                
        switch (indexPath as NSIndexPath).section {
               
            // Section 0 About App
        case 0:
            switch (indexPath as NSIndexPath).row {
            case 0:
                print("open an alertView")
              showSimpleAlert()
             
            default:
            print(#function, "Error in Switch")
            } // end case section 0 switch
    
            // section 1: Developer
        case 1:
            switch (indexPath as NSIndexPath).row {
            case 0:
                print("Linkedin Developer")
                if let url = URL(string: "https://www.linkedin.com/in/benhuggins42/") {
                UIApplication.shared.open(url)
                }
            case 1:
                // My GitHub
                if let url = URL(string: "https://github.com/benshuggins") {
                UIApplication.shared.open(url)
                }
           
            default:
                print("Can't get to benshuggins github")
            }
            
        case 2: // Section 2 Api Used:
            switch (indexPath as NSIndexPath).row {
            case 0:
                if let url = URL(string: "https://www.youtube.com/watch?v=Wq1KXrKN9Ao&t=45s&ab_channel=Benjammin") {
                UIApplication.shared.open(url)
                }
            default:
            print(#function, "Error in Switch")
            }
            
        case 3: // Section 3 Get Code:
            switch (indexPath as NSIndexPath).row {
            case 0:
                if let url = URL(string: "https://www.youtube.com/watch?v=Wq1KXrKN9Ao&t=45s&ab_channel=Benjammin") {
                UIApplication.shared.open(url)
                }
            default:
            print(#function, "Error in Switch")
            }
            
        case 4: // Section 4 LOGOUT
            switch (indexPath as NSIndexPath).row {
            case 0:
                print("Log Out Button Tapped")
                KeychainItem.deleteUserIdentifierFromKeychain()
                DispatchQueue.main.async {
                    self.showLoginViewController()
                }
            default:
            print(#function, "Error in Switch")
            }
                    
        default: break
        }
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        func showSimpleAlert() {
            let alert = UIAlertController(title: "The Point", message: "This Demo app compares how Covid19 has affected Countries of the World on 3 metrics: Total Cases, Total Recovered Cases, Total Deaths per day all Graphically", preferredStyle: .alert)
  
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: { _ in
                   //Cancel Action
               }))
               self.present(alert, animated: true, completion: nil)
           }
    }



