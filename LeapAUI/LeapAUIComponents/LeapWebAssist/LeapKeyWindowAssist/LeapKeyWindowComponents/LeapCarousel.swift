//
//  LeapCarousel.swift
//  LeapAUI
//
//  Created by Ajay S on 17/12/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

enum LeapCarouselType: String {
    case fullScreen = "FULLSCREEN"
    case overlay = "OVERLAY"
}

/// LeapCarousel - A Web KeyWindowAssist AUI Component class to show a fullscreen or overlay assist on a window.
class LeapCarousel: LeapKeyWindowAssist {
    
    var type: LeapCarouselType = .fullScreen // default
        
    /// call the method to configure constraints for the component and to load the content to display.
    func showCarousel() {
        
        UIApplication.shared.keyWindow?.addSubview(self)
        
        configureOverlayView()
        
        configureWebView()
        
        configureCarousel()
                
        show()
    }
    
    private func configureCarousel() {
        
        // Setting Constraints to WebView
        
        webviewContainer.translatesAutoresizingMaskIntoConstraints = false
        
        webviewContainer.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        webView.leadingAnchor.constraint(equalTo: webviewContainer.leadingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: webviewContainer.topAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: webviewContainer.trailingAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: webviewContainer.bottomAnchor).isActive = true
        
        self.addConstraint(NSLayoutConstraint(item: webviewContainer, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))

        self.addConstraint(NSLayoutConstraint(item: webviewContainer, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))

        self.addConstraint(NSLayoutConstraint(item: webviewContainer, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0))
                
        if let type = self.assistInfo?.extraProps?.props[constant_carouselType] as? String {
            
            self.type = LeapCarouselType(rawValue: type) ?? .fullScreen
        }
        
        if type == .overlay {
            
            self.webView.isOpaque = false
            
            heightConstraint = NSLayoutConstraint(item: webviewContainer, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier:1 , constant: 0)
            
            NSLayoutConstraint.activate([heightConstraint!])
            
        } else {
            
            self.webView.isOpaque = true
            configureWebViewForFullScreenCarousel()
        }
    }
    
    override func configureLeapIconView(superView: UIView, toItemView: UIView, alignmentType: LeapAlignmentType, cornerDistance: CGFloat = 0) {
        
        guard let enabled = iconInfo?.isEnabled, enabled else {
            
            return
        }
                        
        superView.addSubview(leapIconView)
        
        leapIconView.htmlUrl = iconInfo?.htmlUrl ?? ""
                
        leapIconView.iconBackgroundColor = UIColor.init(hex: iconInfo?.backgroundColor ?? "") ?? .black
                
        self.leapIconView.translatesAutoresizingMaskIntoConstraints = false
        
        if type == .fullScreen {
        
        var attributeType1: NSLayoutConstraint.Attribute = .leading
        
        let attributeType2: NSLayoutConstraint.Attribute = .top
                        
        var horizontalDistance: CGFloat = self.leapIconView.iconGap
        
        let verticalDistance: CGFloat = 4*self.leapIconView.iconGap
        
        if !(iconInfo?.isLeftAligned ?? false) {
                        
            attributeType1 = .trailing
            
            horizontalDistance = -self.leapIconView.iconGap
        }
                
        superView.addConstraint(NSLayoutConstraint(item: leapIconView, attribute: attributeType1, relatedBy: .equal, toItem: toItemView, attribute: attributeType1, multiplier: 1, constant: horizontalDistance))
        
        superView.addConstraint(NSLayoutConstraint(item: leapIconView, attribute: attributeType2, relatedBy: .equal, toItem: toItemView, attribute: attributeType2, multiplier: 1, constant: verticalDistance))
            
        } else {
            
            var attributeType1: NSLayoutConstraint.Attribute = .leading
            
            let attributeType2: NSLayoutConstraint.Attribute = .top
            
            let attributeType3: NSLayoutConstraint.Attribute = .bottom
                            
            var horizontalDistance: CGFloat = self.leapIconView.iconGap
            
            let verticalDistance: CGFloat = self.leapIconView.iconGap
            
            if !(iconInfo?.isLeftAligned ?? false) {
                            
                attributeType1 = .trailing
                
                horizontalDistance = -self.leapIconView.iconGap
            }
                    
            superView.addConstraint(NSLayoutConstraint(item: leapIconView, attribute: attributeType1, relatedBy: .equal, toItem: toItemView, attribute: attributeType1, multiplier: 1, constant: horizontalDistance))
            
            superView.addConstraint(NSLayoutConstraint(item: leapIconView, attribute: attributeType2, relatedBy: .equal, toItem: toItemView, attribute: attributeType3, multiplier: 1, constant: verticalDistance))
        }
        
        leapIconView.configureIconButton()
    }
    
    /// This is a custom configuration of constraints for the Carousel type.
    private func configureWebViewForFullScreenCarousel() {
      
        self.addConstraint(NSLayoutConstraint(item: webviewContainer, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0))
    }
    
    /// This is a custom configuration of constraints for the Carousel type.
    private func configureWebViewForOverlayCarousel(height: CGFloat) {

        heightConstraint?.constant = height
    }
    
    override func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        
        if type == .fullScreen {
        
           configureLeapIconView(superView: webView, toItemView: webviewContainer, alignmentType: .top)
            
        } else {
            
           configureLeapIconView(superView: self, toItemView: webviewContainer, alignmentType: .top)
        }
    }
    
    override func didReceive(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let body = message.body as? String else { return }
        guard let data = body.data(using: .utf8) else { return }
        guard let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<String,Any> else {return}
        guard let metaData = dict[constant_pageMetaData] as? Dictionary<String,Any> else {return}
        guard let rect = metaData[constant_rect] as? Dictionary<String,Float> else {return}
        guard let height = rect[constant_height] else { return }
        DispatchQueue.main.async {
            if self.type == .overlay {
               self.configureWebViewForOverlayCarousel(height: CGFloat(height))
            }
        }
    }
    
    override func performEnterAnimation(animation: String) {
                
        self.alpha = 0
        
        leapIconView.alpha = 0
        
        self.webView.alpha = 0
        
        self.webviewContainer.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.1, animations: {
            
            self.webviewContainer.transform = CGAffineTransform.identity
            
            UIView.animate(withDuration: 0.05) {
                
               self.alpha = 1
            }
            
        }) { (_) in
            
            UIView.animate(withDuration: 0.1) {
                
                self.webView.alpha = 1
                                
                self.leapIconView.alpha = 1                
            }
        }
    }
}
