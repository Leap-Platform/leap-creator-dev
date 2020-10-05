//
//  JinyLabel.swift
//  AUIComponents
//
//  Created by mac on 23/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit
import WebKit

public class JinyLabel: JinyInViewAssist {
    
    weak var toView: UIView?
    
    private weak var inView: UIView?
    
    public init(withDict assistDict: Dictionary<String,Any>, labelToView: UIView) {
        super.init(frame: CGRect.zero)
                
        self.assistInfo = AssistInfo(withDict: assistDict)
        
        toView = labelToView
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func present() {
        
        guard toView != nil else { fatalError("no element to point to") }
        
        if inView == nil {
            
            guard let _ = toView?.superview else { fatalError("View not in valid hierarchy or is window view") }
            
            inView = UIApplication.shared.keyWindow?.rootViewController?.children.last?.view
        }
        
        self.frame = CGRect.zero
        
        inView?.addSubview(self)
        
        self.addSubview(webView)
        
        show()
    }
    
    func setAlignment() {
        
        let globalToViewFrame = toView!.superview!.convert(toView!.frame, to: inView)
                
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
    
    private func configureLabel() {
        
        setAlignment()
        
        self.clipsToBounds = true
        self.layer.cornerRadius = CGFloat(self.assistInfo?.layoutInfo?.style.cornerRadius ?? 0)
        
         // To set stroke color and width
        
        if let colorString = self.assistInfo?.layoutInfo?.style.strokeColor {
                    
            self.layer.borderColor = UIColor.colorFromString(string: colorString).cgColor
        }
        
        if let strokeWidth = self.assistInfo?.layoutInfo?.style.strokeWidth {
                        
            self.layer.borderWidth = CGFloat(strokeWidth)
        
        } else {
            
            self.layer.borderWidth = 0.0
        }
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
        configureLabel()
    }
}
