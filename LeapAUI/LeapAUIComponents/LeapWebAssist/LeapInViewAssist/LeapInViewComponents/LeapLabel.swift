//
//  LeapLabel.swift
//  LeapAUI
//
//  Created by mac on 23/09/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// LeapLabel - A Web InViewAssist AUI Component class to show label on a view.
class LeapLabel: LeapInViewAssist {
    
    /// presents label after setting up view, when show() webview content is called and the delegate is called back.
    func presentLabel() {
        
        setupView()
        
        show()
    }
    
    func presentLabel(toRect: CGRect, inView: UIView?) {
        
        webRect = toRect
                
        presentLabel()
    }
    
    /// sets up toView, inView and webView.
    func setupView() {
        
        inView = toView?.window
        
        self.frame = CGRect.zero
        
        inView?.addSubview(self)
        
        configureWebView()
    }
    
    func updateRect(newRect: CGRect, inView: UIView?) {
        
        webRect = newRect
        
        setAlignment()
    }
    
    /// sets alignment of the LeapLabel.
    func setAlignment() {
        
        guard toView?.superview != nil || webRect != nil else {
            
            return
        }
        
        let globalToViewFrame = getGlobalToViewFrame()
                
        switch LeapAlignmentType(rawValue: (assistInfo?.layoutInfo?.layoutAlignment) ?? "top_left") ?? .topLeft {
            
        case .topLeft:
            
            self.frame.origin = CGPoint(x: globalToViewFrame.origin.x - self.frame.width/2, y:  globalToViewFrame.origin.y - self.frame.height/2)
            
        case .topCenter:
            
            self.frame.origin = CGPoint(x: globalToViewFrame.origin.x + (globalToViewFrame.width)/2 - self.frame.width/2, y:  globalToViewFrame.origin.y - self.frame.height/2)
            
        case .topRight:
            
            self.frame.origin = CGPoint(x: globalToViewFrame.origin.x + (globalToViewFrame.width) - self.frame.width/2, y:  globalToViewFrame.origin.y - self.frame.height/2)
            
        case .bottomLeft:
            
            self.frame.origin = CGPoint(x:  globalToViewFrame.origin.x - self.frame.width/2, y: globalToViewFrame.origin.y + (globalToViewFrame.height) - self.frame.height/2)
            
        case .bottomCenter:
            
            self.frame.origin = CGPoint(x: globalToViewFrame.origin.x + (globalToViewFrame.width)/2 - self.frame.width/2, y: globalToViewFrame.origin.y + (globalToViewFrame.height) - self.frame.height/2)
            
        case .bottomRight:
            
            self.frame.origin = CGPoint(x: globalToViewFrame.origin.x + (globalToViewFrame.width) - self.frame.width/2, y: globalToViewFrame.origin.y + (globalToViewFrame.height) - self.frame.height/2)
            
        case .leftCenter:
            
            self.frame.origin = CGPoint(x:  globalToViewFrame.origin.x - self.frame.width/2, y: globalToViewFrame.origin.y + (globalToViewFrame.height)/2 - self.frame.height/2)
            
        case .rightCenter:
            
            self.frame.origin = CGPoint(x: globalToViewFrame.origin.x + (globalToViewFrame.width) - self.frame.width/2, y: globalToViewFrame.origin.y + (globalToViewFrame.height)/2 - self.frame.height/2)
            
        case .left:
            
            self.frame.origin = CGPoint(x: globalToViewFrame.origin.x - self.frame.width/2, y: globalToViewFrame.origin.y + (globalToViewFrame.height)/2 - self.frame.height/2)
            
        case .top:
            
            self.frame.origin = CGPoint(x: globalToViewFrame.origin.x + (globalToViewFrame.width)/2 - self.frame.width/2, y:  globalToViewFrame.origin.y - self.frame.height/2)
            
        case .right:
            
            self.frame.origin = CGPoint(x: globalToViewFrame.origin.x + (globalToViewFrame.width) - self.frame.width/2, y: globalToViewFrame.origin.y + (globalToViewFrame.height)/2 - self.frame.height/2)
            
        case .bottom:
            
            self.frame.origin = CGPoint(x: globalToViewFrame.origin.x + (globalToViewFrame.width)/2 - self.frame.width/2, y: globalToViewFrame.origin.y + (globalToViewFrame.height) - self.frame.height/2)
            
        case .center:
            
            self.frame.origin = CGPoint(x: globalToViewFrame.origin.x - self.frame.width/2 + (globalToViewFrame.width)/2, y: globalToViewFrame.origin.y + (globalToViewFrame.height)/2 - self.frame.height/2)
        }
    }
    
    /// configures label when webview delegate is called, configures based on the callback.
    private func configureLabel() {
        
        setAlignment()
        
         // To set stroke color and width
        
        if let colorString = self.assistInfo?.layoutInfo?.style.strokeColor {
                    
            self.webView.layer.borderColor = UIColor.init(hex: colorString)?.cgColor
        }
        
        if let strokeWidth = self.assistInfo?.layoutInfo?.style.strokeWidth {
                        
            self.webView.layer.borderWidth = CGFloat(strokeWidth)
        
        } else {
            
            self.webView.layer.borderWidth = 0.0
        }
        
        self.webView.layer.masksToBounds = true
        
        self.elevate(with: CGFloat(assistInfo?.layoutInfo?.style.elevation ?? 0))
    }
    
    override func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        
        configureLabel()
    }
    
    override func didReceive(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let body = message.body as? String else { return }
        guard let data = body.data(using: .utf8) else { return }
        guard let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<String,Any> else {return}
        guard let metaData = dict[constant_pageMetaData] as? Dictionary<String,Any> else {return}
        guard let rect = metaData[constant_rect] as? Dictionary<String,Float> else {return}
        guard let width = rect[constant_width] else { return }
        guard let height = rect[constant_height] else { return }
        webviewContainer.frame.size = CGSize(width: CGFloat(width), height: CGFloat(height))
        self.frame.size = CGSize(width: CGFloat(width), height: CGFloat(height))
    }
    
    override func performEnterAnimation(animation: String) {
        
        self.webviewContainer.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        UIView.animate(withDuration: 0.04) {
            
            self.webviewContainer.transform = CGAffineTransform.identity
        }
    }
}
