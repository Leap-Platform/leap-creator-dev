//
//  JinyKeyWindowAssist.swift
//  JinyDemo
//
//  Created by mac on 02/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// A super class for the JinyKeyWindowAssist AUI Components.
class JinyKeyWindowAssist: JinyWebAssist {
    
    /// height constraint to increase the constant when html resizes
    var heightConstraint: NSLayoutConstraint?
    
    /// source view of the AUIComponent that is relatively positioned.
    weak var inView: UIView?
    
    /// - Parameters:
    ///   - assistDict: A dictionary value for the type AssistInfo.
    init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil) {
        super.init(frame: CGRect.zero)
        
        self.assistInfo = AssistInfo(withDict: assistDict)
        
        guard let iconDict = iconDict else {
            
            return
        }
        
        self.iconInfo = IconInfo(withDict: iconDict)
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
        
          self.backgroundColor = UIColor.init(hex: colorString) ?? UIColor.black.withAlphaComponent(0.65)
        
        } else {
            
          self.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        }
        
        if let highlightAnchor = self.assistInfo?.highlightAnchor, !highlightAnchor {
            
            self.backgroundColor = .clear
        }
        
        self.isHidden = true
        
        self.elevate(with: CGFloat(assistInfo?.layoutInfo?.style.elevation ?? 0))
        
        self.addSubview(webView)
    }
    
    /// Method to configure WebView
    func configureWebView() {
                
        // Setting Corner Radius to curve at the corners
        
        switch assistInfo?.layoutInfo?.layoutAlignment {
        
        case JinyAlignmentType.left.rawValue:
                        
            if #available(iOS 11.0, *) {
                webView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            } else {
                // Fallback on earlier versions
            }
            
        case JinyAlignmentType.right.rawValue:
            
            if #available(iOS 11.0, *) {
                webView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            } else {
                // Fallback on earlier versions
            }
            
        case JinyAlignmentType.bottom.rawValue:
            
            if #available(iOS 11.0, *) {
                webView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            } else {
                // Fallback on earlier versions
            }
            
        default:

            if #available(iOS 11.0, *) {
                webView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            } else {
                // Fallback on earlier versions
            }
        }
        
        webView.clipsToBounds = true
        webView.layer.cornerRadius = CGFloat(self.assistInfo?.layoutInfo?.style.cornerRadius ?? 0)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if assistInfo?.layoutInfo?.dismissAction.outsideDismiss ?? false {
            performExitAnimation(animation: assistInfo?.layoutInfo?.exitAnimation ?? "fade_out", byUser: true, autoDismissed: false, byContext: false, panelOpen: false, action: nil)
        }
    }
}
