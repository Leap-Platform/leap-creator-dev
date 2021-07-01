//
//  LeapInViewAssist.swift
//  LeapAUI
//
//  Created by mac on 02/09/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

class LeapInViewAssist: LeapWebAssist {
    
    /// target view to which the aui component is pointed to.
    weak var toView: UIView?    // should always be weak otherwise causes memory leak due to retain cycle.
    
    /// source view of the toView for which the aui component is relatively positioned.
    weak var inView: UIView?
    
    var webRect: CGRect?
    
    /// - Parameters:
    ///   - assistDict: A dictionary value for the type LeapAssistInfo.
    ///   - toView: target view to which the tooltip is attached.
    ///   - insideView: an optional view on which overlay is diaplayed or else takes entire window.
    init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, toView: UIView, insideView: UIView? = nil, baseUrl:String?) {
        super.init(frame: CGRect.zero, baseUrl: baseUrl)
                
        self.assistInfo = LeapAssistInfo(withDict: assistDict)
        
        self.toView = toView
        
        inView = insideView
        
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
        
        webviewContainer.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        webView.leadingAnchor.constraint(equalTo: webviewContainer.leadingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: webviewContainer.topAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: webviewContainer.trailingAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: webviewContainer.bottomAnchor).isActive = true
        self.addSubview(webviewContainer)
        
        webView.clipsToBounds = true
        webView.layer.cornerRadius = CGFloat(self.assistInfo?.layoutInfo?.style.cornerRadius ?? 0)
    }
    
    func getGlobalToViewFrame() -> CGRect {
        guard let view = toView else { return .zero }
        let superview = view.superview ?? UIApplication.shared.windows.first { $0.isKeyWindow }
        guard let parent = superview else { return view.frame }
        return webRect == nil ? parent.convert(view.frame, to: inView) : view.convert(webRect!, to: inView)
    }
}
