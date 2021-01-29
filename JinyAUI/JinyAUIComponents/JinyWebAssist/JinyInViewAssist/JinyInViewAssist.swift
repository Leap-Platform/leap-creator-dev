//
//  JinyInViewAssist.swift
//  JinyDemo
//
//  Created by mac on 02/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit

public class JinyInViewAssist: JinyWebAssist {
    
    /// target view to which the aui component is pointed to.
    weak var toView: UIView?    // should always be weak otherwise causes memory leak due to retain cycle.
    
    /// source view of the toView for which the aui component is relatively positioned.
    weak var inView: UIView?
    
    var webRect: CGRect?
    
    /// - Parameters:
    ///   - assistDict: A dictionary value for the type AssistInfo.
    ///   - toView: target view to which the tooltip is attached.
    ///   - insideView: an optional view on which overlay is diaplayed or else takes entire window.
    public init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, toView: UIView, insideView: UIView? = nil) {
        super.init(frame: CGRect.zero)
                
        self.assistInfo = AssistInfo(withDict: assistDict)
        
        self.toView = toView
        
        inView = insideView
        
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
        
        // Overlay View to be clear by default
        
        if let colorString = self.assistInfo?.layoutInfo?.style.bgColor {
        
          self.backgroundColor = UIColor.init(hex: colorString)
        
        } else {
            
          self.backgroundColor = UIColor.clear
        }
        
        if !(self.assistInfo?.highlightAnchor ?? false) {
            
            self.backgroundColor = .clear
        }
        
        self.isHidden = true
    }
    
    /// Method to configure WebView
    func configureWebView() {
        
        self.addSubview(webView)
        
        webView.clipsToBounds = true
        webView.layer.cornerRadius = CGFloat(self.assistInfo?.layoutInfo?.style.cornerRadius ?? 0)
    }
    
    func getGlobalToViewFrame() -> CGRect {
        
        return webRect == nil ? toView!.superview!.convert(toView!.frame, to: inView) : toView!.convert(webRect!, to: inView)
    }
}
