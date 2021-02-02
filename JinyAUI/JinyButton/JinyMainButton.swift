//
//  JinyMainButton.swift
//  JinySDK
//
//  Created by Aravind GS on 12/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class JinyMainButton: JinyIconView {
    
    var closeTransparentView: UIView?
    
    var isDismissible = false
    
    var bottomConstraint: NSLayoutConstraint?
    
    var closeIcon = UIImageView(frame: .zero)
    
    private var closeIconHeightConstraint: NSLayoutConstraint?
    
    private var closeIconWidthConstraint: NSLayoutConstraint?
    
    let jinyDraggable = JinyDraggable()
    
    let disableDialog = JinyDisableAssistanceDialog()
    
    private var gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.init(hex: "#99090909")!.cgColor, UIColor.clear.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = CGPoint(x: 0, y: 0)
        gradientLayer.frame = CGRect.zero
       return gradientLayer
    }()
    
    init(withThemeColor: UIColor, dismissible: Bool = false) {
        super.init(frame: .zero)
        self.iconBackgroundColor = withThemeColor
        self.translatesAutoresizingMaskIntoConstraints = false
        self.layer.masksToBounds = true
        
        jinyDraggable.draggableDelegate = self
        self.addGestureRecognizer(jinyDraggable)
        
        self.isDismissible = dismissible
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension JinyMainButton: JinyDraggableDelegate {
    func iconDidDrag() {
                
        if isDismissible {
            
            if self.frame.contains(self.closeIcon.center) {
                
                closeIconWidthConstraint?.constant = 65
                closeIconHeightConstraint?.constant = 65
                
                self.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
                
                self.layoutIfNeeded()
                
                closeIcon.layoutIfNeeded()
                
            } else {
                
                closeIconWidthConstraint?.constant = 50
                closeIconHeightConstraint?.constant = 50
                    
                self.transform = .identity
                
                self.layoutIfNeeded()
                
                closeIcon.layoutIfNeeded()
            }
            
            guard let keyWindow = UIApplication.shared.keyWindow, closeTransparentView == nil else { return }
            
            closeTransparentView = UIView()
            
            closeIcon = UIImageView()
                        
            closeTransparentView?.addSubview(closeIcon)
            
            keyWindow.insertSubview(closeTransparentView!, belowSubview: self)
            
            closeTransparentView?.translatesAutoresizingMaskIntoConstraints = false
            
            keyWindow.addConstraint(NSLayoutConstraint(item: closeTransparentView!, attribute: .centerX, relatedBy: .equal, toItem: keyWindow, attribute: .centerX, multiplier: 1.0, constant: 0))
            
            keyWindow.addConstraint(NSLayoutConstraint(item: closeTransparentView!, attribute: .centerY, relatedBy: .equal, toItem: keyWindow, attribute: .centerY, multiplier: 1.0, constant: 0))
            
            keyWindow.addConstraint(NSLayoutConstraint(item: closeTransparentView!, attribute: .width, relatedBy: .equal, toItem: keyWindow, attribute: .width, multiplier: 1.0, constant: 0))
            
            keyWindow.addConstraint(NSLayoutConstraint(item: closeTransparentView!, attribute: .height, relatedBy: .equal, toItem: keyWindow, attribute: .height, multiplier: 1.0, constant: 0))
                        
            closeIcon.image = UIImage.getImageFromBundle("jiny_ping_close")
            
            closeIcon.translatesAutoresizingMaskIntoConstraints = false
            
            closeTransparentView?.addConstraint(NSLayoutConstraint(item: closeIcon, attribute: .centerX, relatedBy: .equal, toItem: closeTransparentView, attribute: .centerX, multiplier: 1.0, constant: 0))
            
            closeTransparentView?.addConstraint(NSLayoutConstraint(item: closeIcon, attribute: .bottom, relatedBy: .equal, toItem: closeTransparentView, attribute: .bottom, multiplier: 1.0, constant: -50))
            
            closeIconWidthConstraint = NSLayoutConstraint(item: closeIcon, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 50)
            
            closeIconHeightConstraint = NSLayoutConstraint(item: closeIcon, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 50)
            
            NSLayoutConstraint.activate([closeIconWidthConstraint!, closeIconHeightConstraint!])
                        
            closeTransparentView?.layer.insertSublayer(gradientLayer, below: closeIcon.layer)
            
            gradientLayer.frame = UIApplication.shared.keyWindow!.bounds
        }
    }
    
    func iconDidRelease(atLocation location: CGPoint) {
        
        self.transform = .identity
        
        self.layoutIfNeeded()
        
        var duration = 0.3
        
        if self.isDismissible && self.closeTransparentView != nil {
            
            self.closeTransparentView?.removeFromSuperview()
            
            self.closeTransparentView = nil
        }
        
        if CGRect(x: location.x, y: location.y, width: self.frame.width, height: self.frame.height).contains(self.closeIcon.center) && isDismissible {
        
            disableDialog.showBottomDialog()
            
            duration = 1.5
        }
        
        UIView.animate(withDuration: duration) {
            self.center = CGPoint(x: self.jinyDraggable.lastLocation.x, y: self.center.y)
            self.jinyDraggable.setTranslation(.zero, in: self)
        }
        
        let constant = (UIApplication.shared.keyWindow?.frame.size.height ?? 0.0) - self.frame.origin.y - self.frame.size.height
        
        if constant < mainIconConstraintConstant {
            
            self.bottomConstraint?.constant = mainIconConstraintConstant
        
        } else {
            
            self.bottomConstraint?.constant = constant
        }
    }
}
