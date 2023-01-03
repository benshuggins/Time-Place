//
//  LeftMenuTVCell.swift
//  GymTracker
//
//  Created by Ben Huggins on 1/1/23.
//

import UIKit

protocol LeftMenuButtonActionDelegate: AnyObject {
    func didTapButton(data: String)
}

class LeftMenuTVCell: UITableViewCell {
    
    private let button = UIButton()
    
    public weak var delegate: LeftMenuButtonActionDelegate?
    private var string: String?

    public func configure(with string: String) {
        self.string = string
    }
    
    var data = String()
    static let identifier = "DeveloperMenuTableViewCell"
    
    let uiView: UIView = {
       let uiView = UIView()
       return uiView
    }()
    
    let label: UILabel = {
       let label = UILabel()
        return label
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
 
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .systemGray
     contentView.layer.cornerRadius = 12
        contentView.addSubview(uiView)
    
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didTapButton() {
        //guard let string = string else {return}
        delegate?.didTapButton(data: data)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.addSubview(button)
        contentView.addSubview(label)
        
        button.frame = CGRect(x: 0, y: 0, width: contentView.frame.size.width, height: contentView.frame.size.height)
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        label.text = data
        label.frame = contentView.bounds
    }
}
