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
    lazy var pulsator: LeapPulsator = {
        let bgColorString = assistInfo?.layoutInfo?.style.bgColor ?? "#FF000000"
        let bgColor = UIColor(hex: bgColorString) ?? .red
        return LeapPulsator(with: bgColor)
    }()
    
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
        pulsator.toRect = toRect
        presentBeacon()
    }
    
    func updateRect(newRect: CGRect, inView: UIView?) {
        
        webRect = newRect
        pulsator.toRect = newRect
        setAlignment()
    }
    
    override func show() {
        
        pulsator.pulsatorDelegate = self
        
        if webRect != nil  { pulsator.placeBeacon(rect: webRect!, inWebView: toView!) }
        else {
            pulsator.toView = toView
            pulsator.placeBeacon()
        }
    }
    
    override func remove(byContext:Bool, byUser:Bool, autoDismissed:Bool, panelOpen:Bool, action:Dictionary<String,Any>?) {
        
        pulsator.stopAnimation()
    
        super.remove(byContext: byContext, byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
    }
    
    /// sets up customised LeapBeacon's class, toView and inView.
    func setupView() {
                    
        inView = toView?.window
        
        inView?.layer.addSublayer(pulsator)
    }
    
    /// Sets alignment of the component (LeapBeacon).
    func setAlignment() {
        let pos = assistInfo?.layoutInfo?.layoutAlignment ?? "top_left"
        pulsator.setPosition(pos)
    }
    
    override func hide() {
        self.pulsator.isHidden = true
    }
    
    override func unhide() {
        self.pulsator.isHidden = false
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
