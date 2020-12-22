//
//  JinyBeacon.swift
//  JinyDemo
//
//  Created by mac on 22/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit

/// JinyBeacon - A native AUI Component class to point out a view.
public class JinyBeacon: JinyNativeAssist {
    
    /// source view to which the component to pointed to.
    weak var toView: UIView?
    
    /// source view of the toView for which the component is relatively positioned.
    private weak var inView: UIView?
     
    /// Radius of the beacon's pulse, range of pulsating.
    public var radius: Double = 10
    
    /// JinyBeacon's custom layer (CAReplicatorLayer) class.
    let pulsator = JinyPulsator()
    
    /// - Parameters:
    ///   - assistDict: A dictionary value for the type AssistInfo.
    ///   - toView: source view to which the tooltip is attached.
    public init(withDict assistDict: Dictionary<String,Any>, toView: UIView) {
        super.init(frame: CGRect.zero)
                
        self.assistInfo = AssistInfo(withDict: assistDict)
        
        self.toView = toView
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// presents beacon after setting up view, setting up alignment and when start() method called.
    func presentBeacon() {
        
        delegate?.willPresentAssist()
        
        setupView()
                
        setAlignment()
        
        show()
    }
    
    public override func show() {
        
        pulsator.pulsatorDelegate = self
        
        pulsator.start()
    }
    
    public override func remove() {
        
        pulsator.stop()
        
        inView?.layer.sublayers?.removeAll()
        
        super.remove()
    }
    
    /// sets up customised JinyBeacon's class, toView and inView.
    func setupView() {
        
       pulsator.backgroundColor = UIColor.colorFromString(string: assistInfo?.layoutInfo?.style.bgColor ?? "black").cgColor
        pulsator.radius = CGFloat(radius)
        pulsator.numPulse = 3
        
        if toView?.window != UIApplication.shared.keyWindow {
            
            inView = toView!.window
            
        } else {
            
            inView = UIApplication.getCurrentVC()?.view
        }
        
        inView?.layer.addSublayer(pulsator)
    }
    
    /// Sets alignment of the component (JinyBeacon).
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

extension JinyBeacon: JinyPulsatorDelegate {
    
    func didStartAnimation() {
        
        super.show()        
    }
    
    func didStopAnimation() {
        
        super.performExitAnimation(animation: "")
    }
}
