//
//  LeapMainButton.swift
//  LeapAUI
//
//  Created by Aravind GS on 12/06/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import UIKit

class LeapCloseTransaprentView:UIView {
    override init(frame: CGRect) {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LeapMainButton: LeapIconView {
    
    var closeTransparentView: LeapCloseTransaprentView?
    
    var isDismissible = false
    
    var bottomConstraint: NSLayoutConstraint?
    
    var closeIcon = UIImageView(frame: .zero)
    
    private var closeIconHeightConstraint: NSLayoutConstraint?
    
    private var closeIconWidthConstraint: NSLayoutConstraint?
    
    let disableDialog = LeapDisableAssistanceDialog()
    
    private var gradientLayer: CAGradientLayer? = {
        let gradientLayer = CAGradientLayer()
        guard let color = UIColor.init(hex: "#99090909") else { return nil }
        gradientLayer.colors = [color.cgColor, UIColor.clear.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = CGPoint(x: 0, y: 0)
        gradientLayer.frame = CGRect.zero
       return gradientLayer
    }()
    
    init(withThemeColor: UIColor, dismissible: Bool = false) {
        super.init(frame: .zero)
        self.iconBackgroundColor = withThemeColor
        self.translatesAutoresizingMaskIntoConstraints = false
        self.elevate(with: 20)
        
        self.addGestureRecognizer(leapTappable)
        
        self.addGestureRecognizer(leapDraggable)
        self.leapDraggable.draggableDelegate = self
        
        self.isDismissible = dismissible
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LeapMainButton: LeapDraggableDelegate {
    func iconDidDrag() {
                
        if isDismissible {
            
            if self.frame.contains(self.closeIcon.center) {
                                
                closeIconWidthConstraint?.constant = 65
                closeIconHeightConstraint?.constant = 65
                
                closeIcon.updateConstraints()
                
                self.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
                
                self.layoutIfNeeded()
                
            } else {
                                
                closeIconWidthConstraint?.constant = 50
                closeIconHeightConstraint?.constant = 50
                
                closeIcon.updateConstraints()
                    
                self.transform = .identity
                
                self.layoutIfNeeded()
            }
            
            guard let keyWindow = UIApplication.shared.keyWindow, closeTransparentView == nil else { return }
            
            closeTransparentView = LeapCloseTransaprentView()
            
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
            
            closeTransparentView?.addConstraint(NSLayoutConstraint(item: closeIcon, attribute: .bottom, relatedBy: .equal, toItem: closeTransparentView, attribute: .bottom, multiplier: 1.0, constant: -mainIconBottomConstant))
            
            closeIconWidthConstraint = NSLayoutConstraint(item: closeIcon, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 50)
            
            closeIconHeightConstraint = NSLayoutConstraint(item: closeIcon, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 50)
            
            NSLayoutConstraint.activate([closeIconWidthConstraint!, closeIconHeightConstraint!])
            guard gradientLayer != nil else { return }
            closeTransparentView?.layer.insertSublayer(gradientLayer!, below: closeIcon.layer)
            guard let window = UIApplication.shared.keyWindow else { return }
            gradientLayer?.frame = window.bounds
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
            self.center = CGPoint(x: self.leapDraggable.lastLocation.x, y: self.center.y)
            self.leapDraggable.setTranslation(.zero, in: self)
        }
        
        let constant = (UIApplication.shared.keyWindow?.frame.size.height ?? 0.0) - self.frame.origin.y - self.frame.size.height
        
        if constant < mainIconBottomConstant {
            
            self.bottomConstraint?.constant = mainIconBottomConstant
        
        } else {
            
            self.bottomConstraint?.constant = constant
        }
    }
}
