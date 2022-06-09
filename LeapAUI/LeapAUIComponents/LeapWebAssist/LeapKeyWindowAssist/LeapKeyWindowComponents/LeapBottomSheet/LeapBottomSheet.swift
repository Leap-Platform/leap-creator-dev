//
//  LeapBottomSheet.swift
//  LeapAUI
//
//  Created by mac on 11/09/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// LeapBottomSheet - A Web KeyWindowAssist AUI Component class to show a bottomSheet over a window.
class LeapBottomSheet: LeapKeyWindowAssist {
            
    override init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, baseUrl: String?) {
        super.init(withDict: assistDict, iconDict: iconDict, baseUrl: baseUrl)
                        
        var layoutInfo = assistDict[constant_layoutInfo] as? Dictionary<String, Any> ?? [:]
            
        layoutInfo[constant_alignment] = "bottom"
                        
        self.assistInfo?.layoutInfo = LeapLayoutInfo(withDict: layoutInfo)
        
        // comment this if you want value from config
        assistInfo?.layoutInfo?.style.elevation = 8 // hardcoded value
        
        // comment this if you want value from config
        assistInfo?.layoutInfo?.style.cornerRadius = 14 // hardcoded value
        
        setAnimationType()
    }
    
    private func setAnimationType() {
        
        assistInfo?.layoutInfo?.enterAnimation = "slide_up"
        assistInfo?.layoutInfo?.exitAnimation = "slide_down"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// call the method to configure constraints for the component and to load the content to display.
    func showBottomSheet() {
        
        UIApplication.shared.keyWindow?.addSubview(self)
        
        configureOverlayView()
        
        configureWebView()
        
        configureWebViewForBottomSheet()
        
        show()
    }
    
    /// This is a custom configuration of constraints for the BottomSheet component.
    func configureWebViewForBottomSheet() {
      
        // Setting Constraints to WebView
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        webView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        webView.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidthSupported).isActive = true
        
        widthConstraint?.isActive = false
        heightConstraint?.isActive = false
        
        widthConstraint = NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        
        widthConstraint?.priority = .defaultLow
        
        let maxHeight = 0.8 * self.frame.height
        
        heightConstraint = NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: maxHeight)
        
        NSLayoutConstraint.activate([heightConstraint!, widthConstraint!])
    }
    
    /// Set height constraint for the bottomSheet.
    /// - Parameters:
    ///   - height: Height of the content of the webview.
    private func configureHeightConstraint(height: CGFloat) {
        
        let proportionalHeight = (((CGFloat((self.assistInfo?.layoutInfo?.style.maxHeight ?? 0.8))*100) * self.frame.height) / 100)
        
        var sizeHeight: CGFloat = 0
        
        if height <= 0 || height > proportionalHeight {
            
            sizeHeight = proportionalHeight
        
        } else if height <= proportionalHeight {
            
            sizeHeight = height
        }
        
        heightConstraint?.constant = sizeHeight
    }
    
    func configureWidthConstraint() {
        
        if UIApplication.shared.statusBarOrientation.isLandscape {
            
            widthConstraint?.constant = self.frame.height
        
        } else {
            
            widthConstraint?.constant = self.frame.width
        }
    }
    
    override func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        
        if flowType == .multiFlow {
            initFlowMenu()
        }
        
        self.configureLeapIconView(superView: self, toItemView: self.webView, alignmentType: .top, cornerDistance: leapIconView.iconGap)
    }
    
    override func didReceive(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? String else { return }
        guard let data = body.data(using: .utf8) else { return }
        guard let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<String,Any> else { return }
        guard let metaData = dict[constant_pageMetaData] as? Dictionary<String,Any> else {return}
        guard let rect = metaData[constant_rect] as? Dictionary<String,Float> else {return}
        guard let height = rect[constant_height] else { return }
        self.configureHeightConstraint(height: CGFloat(height))
        self.configureWidthConstraint()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.webView.evaluateJavaScript("getPageMetaData()") { res, err in
                guard let metaData:[String:[String:CGFloat]] = res as? [String:[String:CGFloat]] else { return }
                guard let rect = metaData[constant_rect] else { return }
                guard let height = rect[constant_height] else { return }
                self.configureHeightConstraint(height: height)
            }
        }
    }
}
