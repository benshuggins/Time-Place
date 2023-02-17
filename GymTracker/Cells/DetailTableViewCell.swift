//
//  DetailTableViewCell.swift
//  GymTracker
//
//  Created by Ben Huggins on 1/4/23.
//

import UIKit

let dateFormatterCell: DateFormatter = {
   let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter
    }()

class DetailTableViewCell: UITableViewCell {
    static let identifier = "DetailTableViewCell"
    
    var totalTimelabel: UILabel = {
       let label = UILabel()
         label.textAlignment = .left
        return label
    }()
    
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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(totalTimelabel)
        contentView.addSubview(enterTimelabel)
        contentView.addSubview(exitTimelabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(regionEvent: RegionEvent) {
        guard let totalTime = regionEvent.totalRegionTime else { return }
        guard let enterTime = regionEvent.enterRegionTime else { return  }
        guard let exitTime = regionEvent.exitRegionTime else { return }

        let enterT = format(date: enterTime)
        let exitT = format(date: exitTime)
        
        totalTimelabel.text = "Total:  \(totalTime)"
        enterTimelabel.text = "Enter: \(enterT)"
        exitTimelabel.text = "Exit:    \(exitT)"
    }
    
    func format(date: Date) -> String {
        return dateFormatterCell.string(from: date)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        totalTimelabel.frame = CGRect(x: 5, y: 5, width: 300, height: contentView.frame.size.height-10)
        enterTimelabel.frame = CGRect(x: 5, y: 20, width: 300, height: contentView.frame.size.height-10)
        exitTimelabel.frame = CGRect(x: 5, y: 35, width: 300, height: contentView.frame.size.height-10)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
