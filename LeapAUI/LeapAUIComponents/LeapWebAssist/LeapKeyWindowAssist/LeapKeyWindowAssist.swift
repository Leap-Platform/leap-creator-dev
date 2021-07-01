//
//  LeapKeyWindowAssist.swift
//  LeapAUI
//
//  Created by mac on 02/09/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// A super class for the LeapKeyWindowAssist AUI Components.
class LeapKeyWindowAssist: LeapWebAssist {
    
    /// height constraint to increase the constant when html resizes
    var heightConstraint: NSLayoutConstraint?
    
    /// source view of the AUIComponent that is relatively positioned.
    weak var inView: UIView?
    
    /// - Parameters:
    ///   - assistDict: A dictionary value for the type LeapAssistInfo.
    init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, baseUrl: String?) {
        super.init(frame: CGRect.zero, baseUrl: baseUrl)
        
        self.assistInfo = LeapAssistInfo(withDict: assistDict)
        
        guard let iconDict = iconDict else {
            
            return
        }
        
        self.iconInfo = LeapIconInfo(withDict: iconDict)
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
        
        webviewContainer.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        webView.leadingAnchor.constraint(equalTo: webviewContainer.leadingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: webviewContainer.topAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: webviewContainer.trailingAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: webviewContainer.bottomAnchor).isActive = true
        self.addSubview(webviewContainer)
    }
    
    /// Method to configure WebView
    func configureWebView() {
                
        // Setting Corner Radius to curve at the corners
        
        switch assistInfo?.layoutInfo?.layoutAlignment {
        
        case LeapAlignmentType.left.rawValue:
                        
            if #available(iOS 11.0, *) {
                webView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            } else {
                // Fallback on earlier versions
            }
            
        case LeapAlignmentType.right.rawValue:
            
            if #available(iOS 11.0, *) {
                webView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            } else {
                // Fallback on earlier versions
            }
            
        case LeapAlignmentType.bottom.rawValue:
            
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
            performExitAnimation(animation: assistInfo?.layoutInfo?.exitAnimation ?? "fade_out", byUser: true, autoDismissed: false, byContext: false, panelOpen: false, action: [constant_body: [constant_close: true]])
        }
    }
}
