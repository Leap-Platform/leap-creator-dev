//
//  JinyBeacon.swift
//  AUIComponents
//
//  Created by mac on 22/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit

public class JinyBeacon: JinyInViewAssist {
    
    weak var toView: UIView?
    
    private weak var inView: UIView?
        
    public var radius: Double = 10
    
    let pulsator = JinyPulsator()
    
    public init(withDict assistDict: Dictionary<String,Any>, beaconToView: UIView) {
        super.init(frame: CGRect.zero)
                
        self.assistInfo = AssistInfo(withDict: assistDict)
        
        toView = beaconToView        
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func present() {
        
        pulsator.backgroundColor = UIColor.colorFromString(string: assistInfo?.layoutInfo?.style.bgColor ?? "black").cgColor
        pulsator.radius = CGFloat(radius)
        pulsator.numPulse = 3
        
        guard toView != nil else { fatalError("no element to point to") }
        
        if inView == nil {
            
            guard let _ = toView?.superview else { fatalError("View not in valid hierarchy or is window view") }
            
            inView = UIApplication.shared.keyWindow?.rootViewController?.children.last?.view
        }
        
        inView?.layer.addSublayer(pulsator)
                
        setAlignment()
        
        pulsator.start()
    }
    
    func setAlignment() {
        
        let globalToViewFrame = toView!.superview!.convert(toView!.frame, to: inView)
                
        switch JinyAlignmentType(rawValue: (assistInfo?.layoutInfo?.layoutAlignment) ?? "top_left") ?? .topCenter {
            
        case .topLeft:
            
            pulsator.pulse.position = CGPoint(x: globalToViewFrame.origin.x + 5, y:  globalToViewFrame.origin.y + 5)
            
        case .topCenter:
            
            pulsator.pulse.position = CGPoint(x: globalToViewFrame.origin.x + (globalToViewFrame.width)/2, y:  globalToViewFrame.origin.y + 5)
            
        case .topRight:
            
            pulsator.pulse.position = CGPoint(x: globalToViewFrame.origin.x + (globalToViewFrame.width)-5, y:  globalToViewFrame.origin.y + 5)
            
        case .bottomLeft:
            
            pulsator.pulse.position = CGPoint(x:  globalToViewFrame.origin.x + 5, y: globalToViewFrame.origin.y + (globalToViewFrame.height)-5)
            
        case .bottomCenter:
            
            pulsator.pulse.position = CGPoint(x: globalToViewFrame.origin.x + (globalToViewFrame.width)/2, y: globalToViewFrame.origin.y + (globalToViewFrame.height)-5)
            
        case .bottomRight:
            
            pulsator.pulse.position = CGPoint(x: globalToViewFrame.origin.x + (globalToViewFrame.width)-5, y: globalToViewFrame.origin.y + (globalToViewFrame.height)-5)
            
        case .leftCenter:
            
            pulsator.pulse.position = CGPoint(x:  globalToViewFrame.origin.x + 5, y: globalToViewFrame.origin.y + (globalToViewFrame.height)/2)
            
        case .rightCenter:
            
            pulsator.pulse.position = CGPoint(x: globalToViewFrame.origin.x + (globalToViewFrame.width)-5, y: globalToViewFrame.origin.y + (globalToViewFrame.height)/2)
            
        case .left:
            
            pulsator.pulse.position = CGPoint(x: globalToViewFrame.origin.x + 5, y: globalToViewFrame.origin.y + (globalToViewFrame.height)/2)
            
        case .top:
            
            pulsator.pulse.position = CGPoint(x: globalToViewFrame.origin.x + (globalToViewFrame.width)/2, y:  globalToViewFrame.origin.y + 5)
            
        case .right:
            
            pulsator.pulse.position = CGPoint(x: globalToViewFrame.origin.x + (globalToViewFrame.width)-5, y: globalToViewFrame.origin.y + (globalToViewFrame.height)/2)
            
        case .bottom:
            
            pulsator.pulse.position = CGPoint(x: globalToViewFrame.origin.x + (globalToViewFrame.width)/2, y: globalToViewFrame.origin.y + (globalToViewFrame.height)-5)
            
        case .center:
            
            pulsator.pulse.position = CGPoint(x: globalToViewFrame.origin.x + (globalToViewFrame.width)/2, y: globalToViewFrame.origin.y + (globalToViewFrame.height)/2)
        }
    }
}
