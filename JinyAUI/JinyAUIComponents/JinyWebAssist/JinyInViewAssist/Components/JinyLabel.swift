//
//  JinyLabel.swift
//  JinyDemo
//
//  Created by mac on 23/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// JinyLabel - A Web InViewAssist AUI Component class to show label on a view.
public class JinyLabel: JinyInViewAssist {
    
    /// presents label after setting up view, when show() webview content is called and the delegate is called back.
    func presentLabel() {
        
        setupView()
        
        show()
    }
    
    /// sets up toView, inView and webView.
    func setupView() {
        
        if toView?.window != UIApplication.shared.keyWindow {
            
            inView = toView!.window
            
        } else {
            
            inView = UIApplication.getCurrentVC()?.view
        }
        
        self.frame = CGRect.zero
        
        inView?.addSubview(self)
        
        configureWebView()
    }
    
    /// sets alignment of the JinyLabel.
    func setAlignment() {
        
        guard let toViewSuperView = toView?.superview else {
            
            return
        }
        
        let globalToViewFrame = toViewSuperView.convert(toView!.frame, to: inView)
                
        switch JinyAlignmentType(rawValue: (assistInfo?.layoutInfo?.layoutAlignment) ?? "top_left") ?? .topCenter {
            
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
                    
            self.layer.borderColor = UIColor.colorFromString(string: colorString).cgColor
        }
        
        if let strokeWidth = self.assistInfo?.layoutInfo?.style.strokeWidth {
                        
            self.layer.borderWidth = CGFloat(strokeWidth)
        
        } else {
            
            self.layer.borderWidth = 0.0
        }
        
        self.elevate(with: CGFloat(assistInfo?.layoutInfo?.style.elevation ?? 0))
    }
    
    override func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        configureLabel()
    }
    
    override func didReceive(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let body = message.body as? String else { return }
        guard let data = body.data(using: .utf8) else { return }
        guard let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<String,Any> else {return}
        guard let metaData = dict["pageMetaData"] as? Dictionary<String,Any> else {return}
        guard let rect = metaData["rect"] as? Dictionary<String,Float> else {return}
        guard let width = rect["width"] else { return }
        guard let height = rect["height"] else { return }
        webView.frame.size = CGSize(width: CGFloat(width), height: CGFloat(height))
        self.frame.size = CGSize(width: CGFloat(width), height: CGFloat(height))
    }
    
    public override func performEnterAnimation(animation: String) {
        
        self.webView.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        UIView.animate(withDuration: 0.04) {
            
            self.webView.transform = CGAffineTransform.identity
            
            self.delegate?.didPresentAssist()
        }
    }
}
