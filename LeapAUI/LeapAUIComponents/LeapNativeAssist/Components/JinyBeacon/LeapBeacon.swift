//
//  LeapBeacon.swift
//  LeapAUI
//
//  Created by mac on 22/09/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

/// LeapBeacon - A native AUI Component class to point out a view.
class LeapBeacon: LeapNativeAssist {
    
    /// source view to which the component to pointed to.
    weak var toView: UIView?
    
    /// source view of the toView for which the component is relatively positioned.
    private weak var inView: UIView?
    
    private var webRect: CGRect?
    
    /// LeapBeacon's custom layer (CAReplicatorLayer) class.
    let pulsator = LeapPulsator()
    
    /// - Parameters:
    ///   - assistDict: A dictionary value for the type LeapAssistInfo.
    ///   - toView: source view to which the tooltip is attached.
    init(withDict assistDict: Dictionary<String,Any>, toView: UIView) {
        super.init(frame: CGRect.zero)
                
        self.assistInfo = LeapAssistInfo(withDict: assistDict)
        
        self.toView = toView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// presents beacon after setting up view, setting up alignment and when start() method called.
    func presentBeacon() {
        
        
        setupView()
                
        setAlignment()
        
        show()
    }
    
    func presentBeacon(toRect: CGRect, inView: UIView?) {
        
        webRect = toRect
        
        presentBeacon()
    }
    
    func updateRect(newRect: CGRect, inView: UIView?) {
        
        webRect = newRect
        
        setAlignment()
    }
    
    override func show() {
        
        pulsator.pulsatorDelegate = self
        
        pulsator.start()
    }
    
    override func remove(byContext:Bool, byUser:Bool, autoDismissed:Bool, panelOpen:Bool, action:Dictionary<String,Any>?) {
        
        pulsator.stop()
        
        for layer in inView?.layer.sublayers ?? [] {
            
            if let subLayer = layer as? LeapPulsator {
                
                subLayer.removeFromSuperlayer()
            }
        }
                
        super.remove(byContext: byContext, byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
    }
    
    /// sets up customised LeapBeacon's class, toView and inView.
    func setupView() {
        
        pulsator.backgroundColor = UIColor.init(hex: assistInfo?.layoutInfo?.style.bgColor ?? "#FF000000")?.cgColor
        if let radius = assistInfo?.extraProps?.props[constant_beaconRippleRadius] as? String {
           pulsator.radius = CGFloat(Int(radius) ?? 10)
        }
        pulsator.numPulse = 3
                    
        inView = toView?.window
        
        inView?.layer.addSublayer(pulsator)
    }
    
    /// Sets alignment of the component (LeapBeacon).
    func setAlignment() {
        
        let globalToViewFrame = webRect == nil ? toView!.superview!.convert(toView!.frame, to: inView) : toView!.convert(webRect!, to: inView)
                
        switch LeapAlignmentType(rawValue: (assistInfo?.layoutInfo?.layoutAlignment) ?? "top_left") ?? .topLeft {
            
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

extension LeapBeacon: LeapPulsatorDelegate {
    
    func didStartAnimation() {
        
        super.show()        
    }
    
    func didStopAnimation() {
        super.performExitAnimation(animation: "", byUser: false, autoDismissed: false, byContext: true, panelOpen: false, action: nil)
    }
}
