//
//  JinyInViewAssist.swift
//  AUIComponents
//
//  Created by mac on 02/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit

public class JinyInViewAssist: JinyWebAssist {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Method to configure constraints for the overlay view
    func configureOverlayView() {
        
        guard let superView = self.superview else {
            
            return
        }
                        
        // Setting Constraints to self
        
        self.translatesAutoresizingMaskIntoConstraints = false

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: superView, attribute: .centerX, multiplier: 1, constant: 0))

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: superView, attribute: .centerY, multiplier: 1, constant: 0))

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: superView, attribute: .width, multiplier: 1, constant: 0))

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: superView, attribute: .height, multiplier: 1, constant: 0))
        
        // Overlay View to be semi transparent black

        if let colorString = self.assistInfo?.layoutInfo?.style.bgColor {
        
          self.backgroundColor = UIColor.colorFromString(string: colorString)
        
        } else {
            
          self.backgroundColor = UIColor.clear
        }
        
        self.isHidden = true
    }
    
    /// Method to configure WebView
    func configureWebView() {
        
        self.addSubview(webView)
        
        // Setting Corner Radius to curve at the corners
        
//        switch assistInfo?.layoutInfo?.layoutAlignment {
//
//        case JinyAlignmentType.left.rawValue:
//
//            webView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
//
//        case JinyAlignmentType.right.rawValue:
//
//            webView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
//
//        case JinyAlignmentType.bottom.rawValue:
//
//            webView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
//
//        default:
//
//            webView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
//        }
        
//        webView.clipsToBounds = true
//        webView.layer.cornerRadius = CGFloat(self.assistInfo?.layoutInfo?.style.cornerRadius ?? 0)
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if assistInfo?.layoutInfo?.outsideDismiss ?? false {
        
            performExitAnimation(animation: assistInfo?.layoutInfo?.exitAnimation ?? "")
        }
    }
}
