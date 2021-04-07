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
    
    private var id = String.generateUUIDString()
    
    private var lastLocation = CGPoint.zero
        
    /// LeapBeacon's custom layer (CAReplicatorLayer) class.
    var pulsator: LeapPulsator = LeapPulsator()
    
    /// - Parameters:
    ///   - assistDict: A dictionary value for the type LeapAssistInfo.
    ///   - toView: source view to which the tooltip is attached.
    init(withDict assistDict: Dictionary<String,Any>, toView: UIView) {
        super.init(frame: CGRect.zero)
                
        self.assistInfo = LeapAssistInfo(withDict: assistDict)
        
        self.toView = toView
        
        let bgColorString = assistInfo?.layoutInfo?.style.bgColor ?? "#FF000000"
        let bgColor = UIColor(hex: bgColorString) ?? .red
        
        pulsator.bgColor = bgColor
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
        show()
    }
    
    override func show() {
        
        if webRect != nil  {
            
            if lastLocation != webRect?.origin {
            
                pulsator.placeBeacon(rect: webRect!, inWebView: toView!)
            }
            lastLocation = webRect!.origin
        
        } else {
            
            pulsator.toView = toView
            
            let frame = getGlobalToViewFrame()
            
            if lastLocation != frame.origin {
            
               pulsator.placeBeacon()
            }
            lastLocation = frame.origin
        }
    }
    
    override func performExitAnimation(animation: String, byUser: Bool, autoDismissed: Bool, byContext: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        pulsator.stopAnimation()
        self.removeFromSuperview()
    }
    
    /// sets up customised LeapBeacon's class, toView and inView.
    func setupView() {
                    
        inView = toView?.window
        
        inView?.addSubview(self)
        
        configureTransparentView()
        
        self.layer.addSublayer(pulsator)
        
        pulsator.pulsatorDelegate = self
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
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        let hitTestView = super.hitTest(point, with: event)

        let frameForToView = getGlobalToViewFrame()

        if frameForToView.contains(point) {
                        
            self.delegate?.sendAUIEvent(action: [constant_body: [constant_anchor_click: true, constant_id: id]])
            
            return hitTestView

        } else {

            return hitTestView
        }
    }
    
    func getGlobalToViewFrame() -> CGRect {
        guard let view = toView else { return .zero }
        let superview = view.superview ?? UIApplication.shared.windows.first { $0.isKeyWindow }
        guard let parent = superview else { return view.frame }
        return webRect == nil ? parent.convert(view.frame, to: inView) : view.convert(webRect!, to: inView)
    }
    
    /// Method to configure constraints for the transparent view
    func configureTransparentView() {
        
        guard let superView = self.superview else {
            
            return
        }
                        
        // Setting Constraints to self
        
        self.translatesAutoresizingMaskIntoConstraints = false

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: superView, attribute: .centerX, multiplier: 1, constant: 0))

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: superView, attribute: .centerY, multiplier: 1, constant: 0))

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: superView, attribute: .width, multiplier: 1, constant: 0))

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: superView, attribute: .height, multiplier: 1, constant: 0))
        
        // Overlay View to be clear by default
        
        self.backgroundColor = .clear
        
        self.isUserInteractionEnabled = false
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
