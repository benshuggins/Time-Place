//
//  DetailTableViewCell.swift
//  GymTracker
//
//  Created by Ben Huggins on 1/4/23.
//

import UIKit

class DetailTableViewCell: UITableViewCell {
    static let identifier = "DetailTableViewCell"
    
    var enterTimelabel: UILabel = {
       let label = UILabel()
         label.textAlignment = .left
        return label
    }()
    
    var exitTimelabel: UILabel = {
       let label = UILabel()
         label.textAlignment = .left
        return label
    }()
    
    var totalTimelabel: UILabel = {
       let label = UILabel()
         label.textAlignment = .left
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
     
        contentView.addSubview(enterTimelabel)
        contentView.addSubview(exitTimelabel)
        contentView.addSubview(totalTimelabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(regionEvent: RegionEvent) {
       
        guard let enterTime = regionEvent.enterRegionTime else { return  }
        guard let exitTime = regionEvent.exitRegionTime else { return }
        guard let totalTime = regionEvent.totalRegionTime else { return }
        let enterT = format(date: enterTime)
        let exitT = format(date: exitTime)
        
        enterTimelabel.text = "Enter: \(enterT)"
        exitTimelabel.text = "Exit:   \(exitT)"
        totalTimelabel.text = "Total:  \(totalTime)"
    }
    
    func format(date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        enterTimelabel.frame = CGRect(x: 5, y: 5, width: 300, height: contentView.frame.size.height-10)
        exitTimelabel.frame = CGRect(x: 5, y: 20, width: 300, height: contentView.frame.size.height-10)
        totalTimelabel.frame = CGRect(x: 5, y: 35, width: 300, height: contentView.frame.size.height-10)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
