//
//  JinyMainButton.swift
//  JinySDK
//
//  Created by Aravind GS on 12/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class JinyMainButton: UIButton {
    
    let isLeftALigned:Bool
    let isDraggable:Bool
    let isDismissable:Bool
    var bottomConstraint:NSLayoutConstraint?
    var leadingConstraint:NSLayoutConstraint?
    var closeView:UIView?
    var closeButton:UIButton?
    var lastLocation:CGPoint?
    
    init(withThemeColor:UIColor, iconInfo:Dictionary<String,Any>) {
        isLeftALigned = iconInfo["is_left_aligned"] as? Bool ?? true
        isDraggable = iconInfo["is_draggable"] as? Bool ?? false
        isDismissable = iconInfo["is_dismissable"] as? Bool ?? false
        super.init(frame: .zero)
        self.setImage(UIImage.getImageFromBundle("jiny_icon"), for: .normal)
        self.imageView?.contentMode = .scaleAspectFit
        self.imageEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        self.backgroundColor = withThemeColor
        self.translatesAutoresizingMaskIntoConstraints = false
        self.layer.cornerRadius = 28
        self.layer.masksToBounds = true
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func showButton() {
        let heightConst = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant:56)
        let aspectConst = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0)
        let kw = UIApplication.shared.windows[0]
        bottomConstraint = NSLayoutConstraint(item: kw, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 30)
        
        if isLeftALigned {
            leadingConstraint = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: kw, attribute: .leading, multiplier: 1, constant: 30)
        } else {
            leadingConstraint = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: kw, attribute: .leading, multiplier: 1, constant: kw.frame.size.width - 86)
        }
        NSLayoutConstraint.activate([heightConst, aspectConst, bottomConstraint!, leadingConstraint!])
        
        if isDraggable || isDismissable {
            let jinyDragAction:UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(moveAround(recognizer:)))
            self.addGestureRecognizer(jinyDragAction)
        }
        lastLocation = self.center
    }
    
    @objc private func moveAround(recognizer:UIPanGestureRecognizer) {
        
        let translation = recognizer.translation(in: UIApplication.shared.windows[0])
        switch recognizer.state {
        case .began:
//            if isDismissable { showCloseButton() }
            lastLocation = self.center
        case .changed:
            if isDismissable {
                self.center = CGPoint(x: self.center.x + translation.x, y: self.center.y + translation.y)
            } else {
                self.center = CGPoint(x: self.center.x, y: self.center.y + translation.y)
            }
            recognizer.setTranslation(.zero, in: self)
            
        case .ended:
            if isDismissable {
                UIView.animate(withDuration: 0.3) {
                    self.center = CGPoint(x: self.lastLocation!.x, y: self.center.y)
                } completion: { (completed) in
//                    self.removeCloseButton()
                }
            }
        default:
            break
        }
    }
    
    private func showCloseButton() {
        guard closeView == nil else { return }
        closeView = UIView(frame: .zero)
        let kw = UIApplication.shared.windows[0]
        kw.insertSubview(closeView!, belowSubview: self)
        closeView?.translatesAutoresizingMaskIntoConstraints = false
        let leading = NSLayoutConstraint(item: self.closeView!, attribute: .leading, relatedBy: .equal, toItem: kw, attribute: .leading, multiplier: 1, constant:0)
        let trailing = NSLayoutConstraint(item: kw, attribute: .trailing, relatedBy: .equal, toItem: self.closeView, attribute: .trailing, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: kw, attribute: .bottom, relatedBy: .equal, toItem: self.closeView, attribute: .bottom, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: self.closeView!, attribute: .top, relatedBy: .equal, toItem: kw, attribute: .top, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([leading, trailing, bottom, top])
        closeButton  = UIButton(frame: .zero)
        closeView!.addSubview(closeButton!)
        closeButton?.translatesAutoresizingMaskIntoConstraints = false
        
        
        
    }
    
    private func removeCloseButton() {
        guard let crossView = closeView, crossView.window != nil else { return }
        crossView.removeFromSuperview()
        closeView = nil
    }
    
}
