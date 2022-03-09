//
//  LeapNotification.swift
//  LeapAUI
//
//  Created by mac on 07/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// LeapNotification - A Web KeyWindowAssist AUI Component class to show a webview Notification over a window.
class LeapNotification: LeapKeyWindowAssist {
    
    /// alignment property for Notification - top and bottom
    var alignment: LeapAlignmentType = .top
        
    override init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, baseUrl: String?) {
        super.init(withDict: assistDict, iconDict: iconDict, baseUrl: baseUrl)
                                
        if let alignment = assistInfo?.layoutInfo?.layoutAlignment {
            
            self.alignment = LeapAlignmentType(rawValue: alignment) ?? .top
        }
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeRight.direction = .right
        self.webView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeRight.direction = .left
        self.webView.addGestureRecognizer(swipeLeft)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeDown.direction = .down
        self.webView.addGestureRecognizer(swipeDown)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeUp.direction = .up
        self.webView.addGestureRecognizer(swipeUp)
        
        inView = UIApplication.shared.keyWindow
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// call the method to configure constraints for the component and to load the content to display.
    func showNotification() {
        
        configureWebView()
        
        show()
    }
    
    /// overrides configureWebView() method. sets enter animation and constraints
    override func configureWebView() {
        
        self.webView.isUserInteractionEnabled = true
                
        self.assistInfo?.layoutInfo?.enterAnimation = self.alignment == .top ? "slide_down" : "slide_up"
                
        if self.alignment == .top || self.alignment == .bottom {
        
            configureWebViewForNotification(alignment: self.alignment)
        
        } else {
            
           print("There is no other alignment for notification except top and bottom")
        }
        
        self.backgroundColor = .clear
        
        // comment this if you want value from config
        assistInfo?.layoutInfo?.style.elevation = 8 // hardcoded value
        
        self.elevate(with: CGFloat(assistInfo?.layoutInfo?.style.elevation ?? 8))
                
        // comment this if you want value from config
        assistInfo?.layoutInfo?.style.cornerRadius = 8 // hardcoded value
        
        self.webView.clipsToBounds = true
        
        self.webView.layer.cornerRadius = CGFloat(assistInfo?.layoutInfo?.style.cornerRadius ?? 8)
    }
    
    /// This is a custom configuration of constraints for the Notification component.
    /// - Parameters:
    ///   - alignment: the alignment of the webview whether it is top or bottom.
    private func configureWebViewForNotification(alignment: LeapAlignmentType) {
        
        guard self.alignment == .top || self.alignment == .bottom else {
            
            return
        }
        
        inView?.addSubview(self)
        
        // Setting Constraints to Self
        
        self.translatesAutoresizingMaskIntoConstraints = false
                        
        let attributeType: NSLayoutConstraint.Attribute = alignment == .top ? .top : .bottom
        
        var constant:CGFloat = alignment == .top ? 50.0 : -50.0
        
        if #available(iOS 11.0, *) {
            constant = alignment == .top ? (UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 50) : -(UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 50)
        }
        
        inView?.addConstraint(NSLayoutConstraint(item: self, attribute: attributeType, relatedBy: .equal, toItem: inView, attribute: attributeType, multiplier: 1, constant: CGFloat(constant)))
        
        inView?.addConstraint(NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: inView, attribute: .trailing, multiplier: 1, constant: -24))
        
        inView?.addConstraint(NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: inView, attribute: .leading, multiplier: 1, constant: 24))
        
        heightConstraint?.isActive = false
        
        heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier:1 , constant: 0)
        
        NSLayoutConstraint.activate([heightConstraint!])
        
        self.addSubview(webView)
                                
        // Setting Constraints to WebView
        
        webView.translatesAutoresizingMaskIntoConstraints = false
                        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0))
    }
    
    /// Set height constraint for the Notification.
    /// - Parameters:
    ///   - height: Height of the content of the webview.
    private func configureHeightConstraint(height: CGFloat) {
        
        heightConstraint?.constant = height
    }
    
    override func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
                
        guard self.alignment == .top || self.alignment == .bottom else {
                    
            return
        }
        
        guard self.inView != nil else { return }
                                                
        if self.alignment == .top {
                    
            self.configureLeapIconView(superView: self.inView!, toItemView: webView, alignmentType: .bottom)
                
        } else {
                    
            self.configureLeapIconView(superView: self.inView!, toItemView: webView, alignmentType: .top)
        }
    }
    
    override func didReceive(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let body = message.body as? String else { return }
        print(body)
        guard let data = body.data(using: .utf8) else { return }
        guard let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<String,Any> else {return}
        guard let metaData = dict[constant_pageMetaData] as? Dictionary<String,Any> else {return}
        guard let rect = metaData[constant_rect] as? Dictionary<String,Float> else {return}
        guard let height = rect[constant_height] else { return }
        self.configureHeightConstraint(height: CGFloat(height))
    }
    
    /// animates the webview according to the direction of swipe gesture.
    /// - Parameters:
    ///   - gesture: type of gesture recognizer, primarily the direction of the swipe.
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {

        if let swipeGesture = gesture as? UISwipeGestureRecognizer {

            switch (swipeGesture.direction, self.alignment) {
                
            case (.right, .top), (.right, .bottom):
                                
                UIView.animate(withDuration: 0.15, animations: {
                    
                  self.leapIconView.alpha = 0
                    
                  self.frame.origin.x = UIScreen.main.bounds.width
                    
                }) { (success) in
                    
                    self.removeFromSuperview()
                }
                
            case (.down, .bottom):
                
                UIView.animate(withDuration: 0.15, animations: {
                    
                  self.leapIconView.alpha = 0
                    
                  self.frame.origin.y = UIScreen.main.bounds.height
                    
                }) { (success) in
                    
                    self.removeFromSuperview()
                }
                
            case (.left, .top), (.left, .bottom):
                
                UIView.animate(withDuration: 0.15, animations: {
                    
                  self.leapIconView.alpha = 0
                    
                  self.frame.origin.x = -(UIScreen.main.bounds.width)
                    
                }) { (success) in
                    
                    self.removeFromSuperview()
                }
                
            case (.up, .top):
                
                UIView.animate(withDuration: 0.15, animations: {
                    
                  self.leapIconView.alpha = 0
                    
                  self.frame.origin.y = -(UIScreen.main.bounds.height)
                    
                }) { (success) in
                    
                    self.removeFromSuperview()
                }
                
            default:
                break
            }
            
            self.delegate?.didDismissAssist(byContext: false, byUser: true, autoDismissed: false, panelOpen: false, action: nil)
        }
    }
}
