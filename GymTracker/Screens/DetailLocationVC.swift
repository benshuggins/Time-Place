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

class DetailLocationVC: UIViewController {
    
    var titleString: String = ""
    
    private let label: UILabel = {
       let label = UILabel()
        label.textColor = .black
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(label)
        title = titleString
        view.backgroundColor = .white
        
        label.text = titleString
        // Do any additional setup after loading the view.
        label.frame = CGRect(x: 50, y: 100, width: 200, height: 55)
    }
    

 

}
