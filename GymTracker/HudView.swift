//
//  HudView.swift
//  GymTracker
//
//  Created by Ben Huggins on 1/4/23.
//

import UIKit

class HudView: UIView {

    var text = ""
    // this convenience constructor creates an instance of hudview and returns it
    class func hud(inView view: UIView, aninated: Bool) -> HudView {
        let hudView = HudView(frame: view.bounds)
        hudView.isOpaque = false
        view.addSubview(hudView)
       // hudView.frame = view.bounds
        view.isUserInteractionEnabled = false
        hudView.show(animated: true)
        return hudView
        }

    // Redraws the hudview to a smaller size this is called automatically by UIkit
    override func draw(_ rect: CGRect) {
        let boxWidth: CGFloat = 96
        let boxHeight: CGFloat = 96
        let boxRect = CGRect(x: round((bounds.size.width - boxWidth)/2), y: round((bounds.size.height - boxHeight)/2), width: boxWidth, height: boxHeight)
        let roundedRect = UIBezierPath(roundedRect: boxRect, cornerRadius: 10)
        UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.8).setFill()
        roundedRect.fill()
        
        // This adds the check mark
        if let image = UIImage(named: "Checkmark") {
            let imagePoint = CGPoint(x: center.x - round(image.size.width/2), y: center.y - round(image.size.height/2) - boxHeight/8)
            image.draw(at: imagePoint)
        }
        
        // This adds the text "tagged" to the hudview
        let attribs = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
            NSAttributedString.Key.foregroundColor: UIColor.white ]
        let textSize = text.size(withAttributes: attribs)
        let textPoint = CGPoint(x: center.x - round(textSize.width/2) , y: center.y - round(textSize.height-2) + boxHeight/4)
        text.draw(at: textPoint, withAttributes: attribs)
    }
    
    // This animates the presentation of the hudview
    func show(animated: Bool) {
        if animated {
            alpha = 0
            transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
                self.alpha = 1
                self.transform = CGAffineTransform.identity
                
            }, completion: nil)
        }
    }
        // This dismisses the hudview when it gets back to the superview
    func hide() {
        superview?.isUserInteractionEnabled = true
        removeFromSuperview()

    }
}
