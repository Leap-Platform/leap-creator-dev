//
//  LeapSlideIn.swift
//  LeapAUI
//
//  Created by mac on 08/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// LeapSlideIn - A Web KeyWindowAssist AUI Component class to show a webview SlideIn over a window.
class LeapSlideIn: LeapKeyWindowAssist {
    
    /// alignment property for SlideIn - left and right
    var alignment: LeapAlignmentType = .left
        
    override init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, baseUrl: String?) {
        super.init(withDict: assistDict, iconDict: iconDict, baseUrl: baseUrl)
                                
        if let alignment = assistInfo?.layoutInfo?.layoutAlignment {
            
            self.alignment = LeapAlignmentType(rawValue: alignment) ?? .left
        
        } else {
            
            assistInfo?.layoutInfo?.layoutAlignment = "left"
        }
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeRight.direction = .right
        self.webView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeRight.direction = .left
        self.webView.addGestureRecognizer(swipeLeft)
        
        inView = UIApplication.shared.keyWindow?.rootViewController?.children.last?.view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// call the method to configure constraints for the component and to load the content to display.
    func showSlideIn() {
        
        configureWebView()
        
        show()
    }
    
    /// overrides configureWebView() method. sets enter animation and constraints
    override func configureWebView() {
        
        self.elevate(with: CGFloat(assistInfo?.layoutInfo?.style.elevation ?? 0))
        
        self.webView.isUserInteractionEnabled = true
                
        self.assistInfo?.layoutInfo?.enterAnimation = self.alignment == .left ? "slide_right" : "slide_left"
                
        if self.alignment == .left || self.alignment == .right {
        
            configureWebViewForSlideIn(alignment: self.alignment)
        
        } else {
            
           print("There is no other alignment for slideIn except left and right")
        }
        
        // To set stroke color and width
        
        if let colorString = self.assistInfo?.layoutInfo?.style.strokeColor {
                    
            self.webView.layer.borderColor = UIColor.init(hex: colorString)?.cgColor
        }
        
        if let strokeWidth = self.assistInfo?.layoutInfo?.style.strokeWidth {
                        
            self.webView.layer.borderWidth = CGFloat(strokeWidth)
        
        } else {
            
            self.webView.layer.borderWidth = 0.5
        }
    }
    
    /// This is a custom configuration of constraints for the SlideIn component.
    /// - Parameters:
    ///   - alignment: the alignment of the webview whether it is left or right.
    private func configureWebViewForSlideIn(alignment: LeapAlignmentType) {
        
        guard inView != nil else { return }
        
        inView?.addSubview(self)
                                
        // Setting Constraints to Self
        
        self.translatesAutoresizingMaskIntoConstraints = false
                        
        let attributeType: NSLayoutConstraint.Attribute = alignment == .left ? .leading : .trailing
        
        inView?.addConstraint(NSLayoutConstraint(item: self, attribute: attributeType, relatedBy: .equal, toItem: inView, attribute: attributeType, multiplier: 1, constant: 0))
        
        inView?.addConstraint(NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: inView, attribute: .bottom, multiplier: 1, constant: -((inView?.frame.height)! * 0.2)))
        
        self.addSubview(webView)
        
        // Setting Constraints to webView
        
        webView.translatesAutoresizingMaskIntoConstraints = false

        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))

        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))

        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0))

        self.addConstraint(NSLayoutConstraint(item: webView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0))
    }
    
    /// Set width and height constraint for SlideIn.
    /// - Parameters:
    ///   - height: Height of the content of the webview.
    ///   - width: Width of the content of the webview.
    private func configureSlideInDimensionConstraint(width: Float, height: Float) {
        
        guard let inViewWidth = inView?.frame.width, self.alignment == .left || self.alignment == .right else {
            
            return
        }
        
        let proportionalWidth = (((self.assistInfo?.layoutInfo?.style.maxWidth ?? 80.0) * Double(inViewWidth)) / 100)
        
        var sizeWidth = self.assistInfo?.layoutInfo?.style.maxWidth ?? 80.0
        
        if width > 0 && width < Float(proportionalWidth) {
            
            sizeWidth = (Double(width) / Double(inViewWidth)) * 100
        }
        
        inView?.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: inView, attribute: .width, multiplier: CGFloat(sizeWidth/100), constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: CGFloat(height)))
        
        assistInfo?.layoutInfo?.style.cornerRadius = Double(height / 2)
        
        super.configureWebView()
    }
    
    override func didReceive(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let body = message.body as? String else { return }
        guard let data = body.data(using: .utf8) else { return }
        guard let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<String,Any> else {return}
        guard let metaData = dict[constant_pageMetaData] as? Dictionary<String,Any> else {return}
        guard let rect = metaData[constant_rect] as? Dictionary<String,Float> else {return}
        guard let width = rect[constant_width] else { return }
        guard let height = rect[constant_height] else { return }
        configureSlideInDimensionConstraint(width: width, height: height)
    }
    
    override func performEnterAnimation(animation: String) {
        
        let xPosition = self.frame.origin.x
        
        if self.alignment == .right {
            
            self.frame.origin.x = (UIScreen.main.bounds.width)
            
            UIView.animate(withDuration: 0.2) {
                
                self.frame.origin.x = xPosition
                
                self.delegate?.didPresentAssist()
            }
        
        } else {
                        
            self.frame.origin.x = -(UIScreen.main.bounds.width)
            
            UIView.animate(withDuration: 0.2) {
                
                self.frame.origin.x = xPosition
                
                self.delegate?.didPresentAssist()
            }
        }
    }
    
    /// animates the webview according to the direction of swipe gesture.
    /// - Parameters:
    ///   - gesture: type of gesture recognizer, primarily the direction of the swipe.
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {

        if let swipeGesture = gesture as? UISwipeGestureRecognizer {

            switch (swipeGesture.direction, self.alignment) {
                
            case (.right, .right):
                                
                UIView.animate(withDuration: 0.15, animations: {
                    
                  self.webView.frame.origin.x = UIScreen.main.bounds.width
                    
                    
                }) { (success) in
                    
                    self.webView.removeFromSuperview()
                }
                
            case (.left, .left):
                
                UIView.animate(withDuration: 0.15, animations: {
                    
                  self.webView.frame.origin.x = -(UIScreen.main.bounds.width)
                    
                    
                }) { (success) in
                    
                    self.webView.removeFromSuperview()
                }
                
            default:
                break
            }
            
            self.delegate?.didDismissAssist(byContext: false, byUser: true, autoDismissed: false, panelOpen: false, action: nil)
        }
    }
}
