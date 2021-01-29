//
//  JinyPing.swift
//  JinyAUI
//
//  Created by Ajay S on 21/01/21.
//  Copyright © 2021 Jiny Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// JinyPing - A Web KeyWindowAssist AUI Component class to show ping on tap of Jiny Discovery Icon.
public class JinyPing: JinyKeyWindowAssist {
    
    private var closeButton = UIButton(type: .custom)
    
    private var bottomConstraint: NSLayoutConstraint?
        
    private let animateConstraintConstant: CGFloat = 71
    
    /// width constraint to increase the constant when html resizes
    var widthConstraint: NSLayoutConstraint?
        
    /// call the method to configure constraints for the component and to load the content to display.
    public func showPing() {
        
        UIApplication.shared.keyWindow?.addSubview(self)
        
        // comment this if you want value from config
        assistInfo?.layoutInfo?.style.elevation = 8 // hardcoded value
        
        // comment this if you want value from config
        assistInfo?.layoutInfo?.style.cornerRadius = 14 // hardcoded value
        
        configureOverlayView()
        
        configureWebView()
        
        configureJinyIconView(superView: self, toItemView: self.webView, alignmentType: .bottom)
        
        configureWebViewForPing()
                    
        show()
    }
    
    /// This is a custom configuration of constraints for the ping component.
    private func configureWebViewForPing() {
        
        // Setting Constraints to WebView
                
        var attribute1: NSLayoutConstraint.Attribute = .leading
        
        var distance = 45
                
        if !(iconInfo?.isLeftAligned ?? false) {
            
            attribute1 = .trailing
            
            distance = -45
        }
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: jinyIconView, attribute: .top, multiplier: 1, constant: -jinyIconView.iconGap))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: attribute1, relatedBy: .equal, toItem: self, attribute: attribute1, multiplier: 1, constant: CGFloat(distance)))
        
        widthConstraint = NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1 , constant: 0)
        
        heightConstraint = NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1 , constant: 0)
        
        NSLayoutConstraint.activate([widthConstraint!, heightConstraint!])
    }
    
    override func configureJinyIconView(superView: UIView, toItemView: UIView, alignmentType: JinyAlignmentType) {
        
        guard let enabled = iconInfo?.isEnabled, enabled else {
            
            return
        }
                        
        superView.addSubview(jinyIconView)
        
        jinyIconView.htmlUrl = iconInfo?.htmlUrl
        
        jinyIconView.tapGestureRecognizer.addTarget(self, action: #selector(jinyIconButtonTapped))
        
        jinyIconView.iconBackgroundColor = UIColor.init(hex: iconInfo?.backgroundColor ?? "") ?? .black
        
        jinyIconView.iconSize = mainIconSize
                
        self.jinyIconView.translatesAutoresizingMaskIntoConstraints = false
        
        var attributeType1: NSLayoutConstraint.Attribute = .leading
                        
        if !(iconInfo?.isLeftAligned ?? false) {
                        
            attributeType1 = .trailing
        }
                
        superView.addConstraint(NSLayoutConstraint(item: jinyIconView, attribute: attributeType1, relatedBy: .equal, toItem: toItemView, attribute: attributeType1, multiplier: 1, constant: 0))
        
        bottomConstraint = NSLayoutConstraint(item: jinyIconView, attribute: .bottom, relatedBy: .equal, toItem: superView, attribute: .bottom, multiplier: 1, constant: -mainIconConstraintConstant)
        
        NSLayoutConstraint.activate([bottomConstraint!])
        
        jinyIconView.configureIconButon()
    }
    
    private func configurePingClose(superView: UIView, toItemView: UIView) {
                        
        superView.addSubview(closeButton)
        
        closeButton.isOpaque = false
                                                
        closeButton.addTarget(self, action: #selector(closePing), for: .touchUpInside)
        
        closeButton.setBackgroundImage(UIImage.getImageFromBundle("jiny_ping_close"), for: .normal)
                                
        self.closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        var attributeType1: NSLayoutConstraint.Attribute = .leading
        
        let attributeType2: NSLayoutConstraint.Attribute = .bottom
        
        let verticalDistance: CGFloat = -self.jinyIconView.iconGap
                
        if !(iconInfo?.isLeftAligned ?? false) {
                        
            attributeType1 = .trailing
        }
                
        superView.addConstraint(NSLayoutConstraint(item: closeButton, attribute: attributeType1, relatedBy: .equal, toItem: toItemView, attribute: attributeType1, multiplier: 1, constant: 0))
        
        superView.addConstraint(NSLayoutConstraint(item: closeButton, attribute: attributeType2, relatedBy: .equal, toItem: toItemView, attribute: .top, multiplier: 1, constant: verticalDistance))
        
        // set width and height constraints to closeButton
        closeButton.addConstraint(NSLayoutConstraint(item: closeButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30))
        
        closeButton.addConstraint(NSLayoutConstraint(item: closeButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30))
    }
    
    @objc func closePing() {
        
        performExitAnimation(animation: assistInfo?.layoutInfo?.exitAnimation ?? "fade_out")
    }
    
    /// Set height constraint for ping.
    /// - Parameters:
    ///   - height: Height of the content of the webview.
    private func configureHeightConstraint(height: CGFloat) {
        
        heightConstraint?.constant = height
    }
    
    /// Set width constraint for ping.
    /// - Parameters:
    ///   - width: Height of the content of the webview.
    private func configureWidthConstraint(width: CGFloat) {
        
        let proportionalWidth: CGFloat = (((CGFloat((self.assistInfo?.layoutInfo?.style.maxWidth ?? 0.8))*100) * self.frame.width) / 100)
        
        var sizeWidth: CGFloat?
        
        if width <= 0 || width > proportionalWidth {
            
            sizeWidth = proportionalWidth
        
        } else if width < proportionalWidth {
            
            sizeWidth = width
        }
                                    
        widthConstraint?.constant = sizeWidth ?? width
    }
    
    public override func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
                
        self.configurePingClose(superView: self, toItemView: self.webView)
    }
    
    override func didReceive(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let body = message.body as? String else { return }
        guard let data = body.data(using: .utf8) else { return }
        guard let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<String,Any> else {return}
        guard let metaData = dict[constant_pageMetaData] as? Dictionary<String,Any> else {return}
        guard let rect = metaData[constant_rect] as? Dictionary<String,Float> else {return}
        guard let width = rect[constant_width] else { return }
        guard let height = rect[constant_height] else { return }
        self.configureWidthConstraint(width: CGFloat(width))
        self.configureHeightConstraint(height: CGFloat(height))
    }
    
    public override func performEnterAnimation(animation: String) {
                                
            let closeButtonAlpha = self.closeButton.alpha
            
            self.layoutIfNeeded()
        
           UIView.animate(withDuration: 0.16, delay: 0, options: .curveEaseInOut) {
            
              UIView.animate(withDuration: 0.08) {
                
                 self.closeButton.alpha = closeButtonAlpha
              
                 self.bottomConstraint?.constant = -self.animateConstraintConstant
                                      
                 self.layoutIfNeeded()
              }
           } completion: { (_) in
            
              self.delegate?.didPresentAssist()
           }
    }
    
    public override func performExitAnimation(animation: String) {
        
        self.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.16, delay: 0, options: .curveEaseInOut) {
                            
            self.bottomConstraint?.constant = -mainIconConstraintConstant
                                        
            self.layoutIfNeeded()
            
        } completion: { (_) in
            
            self.delegate?.didExitAnimation()
            
            self.remove()
        }
    }
}
