//
//  LeapTipView.swift
//  LeapAUI
//
//  Created by Ajay S on 12/01/21.
//  Copyright © 2021 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

/// enum type for Highlight
enum LeapHighlightType: String {
    
    case circle = "circle"
    case rect = "rect"
    case capsule = "capsule"
}

/// Type which controls LeapToolTip, LeapHighlight and LeapSpot.
class LeapTipView: LeapInViewAssist {
    
    /// toolTipView which carries webView.
    var toolTipView = UIView(frame: .zero)
    
    /// A view frame to highlight the source view to which tooltip is pointed to.
    var highlightType: LeapHighlightType = .rect
    
    /// spacing of the highlight area.
    var highlightSpacing = 10.0
    
    /// spacing of the highlight area after manipulation
    var manipulatedHighlightSpacing = 10.0
    
    /// corner radius for the highlight area/frame.
    var highlightCornerRadius = 5.0
    
    /// boolean to know whether a tap on toView occured
    var tappedOnToView = false
    
    /// previous rect of the component to update
    var previousFrame: CGRect?
    
    /// path to mask toView so that it is highlighted
    private var pulsePath = UIBezierPath()
        
    /// path to animate highlighted path where the outer ripple starts when the highlight is animating
    private var opacityPath = UIBezierPath()
    
    /// path to fade the outer ripple when the highlight is animating
    private var fadePath = UIBezierPath()
    
    /// to mask a layer we need an additional path, a parent path to mask
    private var supportPulsePath = UIBezierPath()
    
    /// to mask a layer we need an additional path, a parent path to mask, this path is when animating
    private var supportOpacityPath = UIBezierPath()
    
    /// layer for the inner ripple
    private let pulseLayer = CAShapeLayer()
    
    /// layer for the outer ripple
    private let opacityLayer = CAShapeLayer()
    
    /// enum type for path
    enum LeapPathType: String {
        
        case pulse = "pulse"
        case opacity = "opacity"
        case fade = "fade"
    }
    
    override init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, toView: UIView, insideView: UIView? = nil, baseUrl: String?) {
        super.init(withDict: assistDict, iconDict: iconDict, toView: toView, insideView: insideView, baseUrl: baseUrl)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func appWillEnterForeground() {
        pulseLayer.removeAllAnimations()
        opacityLayer.removeAllAnimations()
        
        animateHighlight()
    }
    
    /// method called to auto focus on the target view of the aui component.
    func setupAutoFocus() {
        
        var targetView: UIView?
        
        if let toView = self.toView as? UITextField {
            
            targetView = toView
        }
        
        if targetView == nil, let toViewParent = toView?.superview as? UITextField {
           
            targetView = toViewParent
        }
        
        if let toView = self.toView as? UITextView {
            
            targetView = toView
        }
        
        if targetView == nil, let toViewParent = toView?.superview as? UITextView {
           
            targetView = toViewParent
        }
        
        guard let focusView = targetView else {
            
            return
        }
        
        var isEditableView = false
        
        switch focusView {
        
        case is UITextField: isEditableView = true
        case is UITextView:
            if let view = toView as? UITextView {
                
                if view.isEditable {
                    
                    isEditableView = true
                }
            }
        default: isEditableView = false
        }
        
        if isEditableView && (assistInfo?.autoFocus ?? false) {
            
            focusView.becomeFirstResponder()
        }
    }
    
    override func performExitAnimation(animation: String, byUser: Bool, autoDismissed: Bool, byContext: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        super.performExitAnimation(animation: animation, byUser: byUser, autoDismissed: autoDismissed, byContext: byContext, panelOpen: panelOpen, action: action)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        tappedOnToView = false
        
        let hitTestView = super.hitTest(point, with: event)
        
        guard let viewToCheck = toView else {
            
            return hitTestView
        }
                
        let frameForToView = getGlobalToViewFrame()
        
        if frameForToView.contains(point) {
            
            tappedOnToView = true 
            
            if (assistInfo?.highlightAnchor ?? false) && (assistInfo?.highlightClickable ?? false) && (assistInfo?.layoutInfo?.dismissAction.dismissOnAnchorClick ?? false) {
                                
                performExitAnimation(animation: self.assistInfo?.layoutInfo?.exitAnimation ?? "fade_out", byUser: true, autoDismissed: false, byContext: false, panelOpen: false, action: [constant_body: [constant_anchor_click: true]])
                
                self.removeFromSuperview()
                                
                return viewToCheck
            
            } else if (assistInfo?.highlightAnchor ?? false) && (assistInfo?.highlightClickable ?? false) {
                                
                return viewToCheck
            
            } else {
                
                return hitTestView
            }
                        
        } else {
            
            return hitTestView
        }
    }
    
    /// sets type of path called for rect.
    /// - Parameters:
    ///   - origin: origin of toView.
    ///   - size: size of toView.
    ///   - pathType: path type for rect.
    private func setPathForRect(origin: CGPoint, size: CGSize, pathType: LeapPathType) {
        
        var scaleFactor = 2.0
        
        switch pathType {
        
        case .pulse:
            
            let pulsePathX = Double(origin.x) - highlightSpacing
            let pulsePathY = Double(origin.y) - highlightSpacing
            
            let pulseWidth = Double(size.width) + (highlightSpacing*2)
            let pulseHeight = Double(size.height) + (highlightSpacing*2)
        
            pulsePath = UIBezierPath(roundedRect: CGRect(x: pulsePathX, y: pulsePathY, width: pulseWidth, height: pulseHeight), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: highlightCornerRadius, height: highlightCornerRadius))
            
        case .opacity:
            
            let opacityPathX = Double(origin.x) - highlightSpacing * scaleFactor
            let opacityPathY = Double(origin.y) - highlightSpacing * scaleFactor
            
            let opacityWidth = Double(size.width) + (highlightSpacing*2) * scaleFactor
            let opacityHeight = Double(size.height) + (highlightSpacing*2) * scaleFactor
            
            opacityPath = UIBezierPath(roundedRect: CGRect(x: opacityPathX, y: opacityPathY, width: opacityWidth, height: opacityHeight), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: highlightCornerRadius, height: highlightCornerRadius))
            
        case .fade:
            
            scaleFactor = 4.0
            
            let fadePathX = Double(origin.x) - highlightSpacing * scaleFactor
            let fadePathY = Double(origin.y) - highlightSpacing * scaleFactor
            
            let fadeWidth = Double(size.width) + (highlightSpacing*2) * scaleFactor
            let fadeHeight = Double(size.height) + (highlightSpacing*2) * scaleFactor
            
            fadePath = UIBezierPath(roundedRect: CGRect(x: fadePathX, y: fadePathY, width: fadeWidth, height: fadeHeight), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: highlightCornerRadius, height: highlightCornerRadius))
        }
    }
    
    /// sets type of path called for capsule.
    /// - Parameters:
    ///   - origin: origin of toView.
    ///   - size: size of toView.
    ///   - pathType: path type for capsule.
    private func setPathForCapsule(origin: CGPoint, size: CGSize, pathType: LeapPathType) {
        
        var scaleFactor = 2.0
        
        switch pathType {
        
        case .pulse:
            
            let pulsePathX = Double(origin.x) - highlightSpacing
            let pulsePathY = Double(origin.y) - highlightSpacing
            
            let pulseWidth = Double(size.width) + (highlightSpacing*2)
            let pulseHeight = Double(size.height) + (highlightSpacing*2)
            
            pulsePath = UIBezierPath(roundedRect: CGRect(x: pulsePathX, y: pulsePathY, width: pulseWidth, height: pulseHeight), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: pulseHeight/2, height: pulseHeight/2))
            
        case .opacity:
            
            let opacityPathX = Double(origin.x) - highlightSpacing * scaleFactor
            let opacityPathY = Double(origin.y) - highlightSpacing * scaleFactor
            
            let opacityWidth = Double(size.width) + (highlightSpacing*2) * scaleFactor
            let opacityHeight = Double(size.height) + (highlightSpacing*2) * scaleFactor
                        
            opacityPath = UIBezierPath(roundedRect: CGRect(x: opacityPathX, y: opacityPathY, width: opacityWidth, height: opacityHeight), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: opacityHeight/2, height: opacityHeight/2))
            
        case .fade:
            
            scaleFactor = 4.0
            
            let fadePathX = Double(origin.x) - highlightSpacing * scaleFactor
            let fadePathY = Double(origin.y) - highlightSpacing * scaleFactor
            
            let fadeWidth = Double(size.width) + (highlightSpacing*2) * scaleFactor
            let fadeHeight = Double(size.height) + (highlightSpacing*2) * scaleFactor
            
            fadePath = UIBezierPath(roundedRect: CGRect(x: fadePathX, y: fadePathY, width: fadeWidth, height: fadeHeight), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: fadeHeight/2, height: fadeHeight/2))
        }
    }
    
    /// sets type of path called for cicle.
    /// - Parameters:
    ///   - x: x of highlight.
    ///   - y: y of highlight.
    ///   - diameter: diameter of highlight for circle.
    ///   - pathType: path type for circle.
    private func setPathForCircle(x: Double, y: Double, diameter: Double, pathType: LeapPathType) {
        
        switch pathType {
        
        case .pulse:
            
            pulsePath = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: diameter, height: diameter))
            
        case .opacity:
            
            let opacityScale = diameter*1.05
            
            let padding = opacityScale-diameter
            
            opacityPath = UIBezierPath(ovalIn: CGRect(x: x-padding, y: y-padding, width: diameter*1.1, height: diameter*1.1))
            
        case .fade:
            
            let opacityScale = diameter*1.2
            
            let padding = opacityScale-diameter

            fadePath = UIBezierPath(ovalIn: CGRect(x: x-padding, y: y-padding, width: diameter*1.4, height: diameter*1.4))
        }
    }
    
    /// Highlights the toView to which the tooltipView is pointed to.
    func highlightAnchor() {
        
        manipulatedHighlightSpacing = highlightSpacing
        
        let globalToView = getGlobalToViewFrame()

        let origin = globalToView.origin
        
        let size = globalToView.size
        
        guard let inView = self.inView else { return }
        
        if let highlightType = assistInfo?.extraProps?.props[constant_highlightType] as? String {
            
            self.highlightType = LeapHighlightType(rawValue: highlightType) ?? .rect
        }
        
        switch self.highlightType {
            
        case .rect:
            
            if let highlightCornerRadius = assistInfo?.extraProps?.props[constant_highlightCornerRadius] as? String {
                
                self.highlightCornerRadius = Double(highlightCornerRadius) ?? self.highlightCornerRadius
            }
            
            setPathForRect(origin: origin, size: size, pathType: .pulse)
            
            setPathForRect(origin: origin, size: size, pathType: .opacity)
            
            setPathForRect(origin: origin, size: size, pathType: .fade)

        case .capsule:
            
            setPathForCapsule(origin: origin, size: size, pathType: .pulse)
            
            setPathForCapsule(origin: origin, size: size, pathType: .opacity)
            
            setPathForCapsule(origin: origin, size: size, pathType: .fade)
            
        case .circle:
            
            var radius = size.width
            
            var x = Double(origin.x) - highlightSpacing
            
            var diameter = Double(radius) + (highlightSpacing*2)
            
            var totalRadius = diameter/2
            
            var y = (Double(origin.y) + Double(size.height)/2) - totalRadius
            
            manipulatedHighlightSpacing = abs(-(totalRadius) + (Double(size.height)/2))
                        
            if size.height > size.width {
                
                radius = size.height
                
                diameter = Double(radius) + (highlightSpacing*2)
                
                totalRadius = diameter/2
                
                x = (Double(origin.x) + Double(size.width)/2) - totalRadius
                
                y = Double(origin.y) - highlightSpacing
                
                manipulatedHighlightSpacing = highlightSpacing
            }
            
            setPathForCircle(x: x, y: y, diameter: diameter, pathType: .pulse)
            
            setPathForCircle(x: x, y: y, diameter: diameter, pathType: .opacity)
            
            setPathForCircle(x: x, y: y, diameter: diameter, pathType: .fade)
        }
        
        supportPulsePath = UIBezierPath(rect: inView.bounds)
        supportPulsePath.append(pulsePath)
        
        pulseLayer.frame.size = inView.bounds.size
        pulseLayer.path = supportPulsePath.cgPath
        pulseLayer.fillRule = .evenOdd
        pulseLayer.isOpaque = false
        pulseLayer.opacity = 1.0
        
        if let animate = assistInfo?.extraProps?.props[constant_animateHighlight] as? String, animate == "true" {
            supportOpacityPath = UIBezierPath(rect: inView.bounds)
            supportOpacityPath.append(opacityPath)

            opacityLayer.path = opacityPath.cgPath
            opacityLayer.fillColor = UIColor.white.cgColor
            opacityLayer.fillRule = .evenOdd
            opacityLayer.opacity = 1
            
            animateHighlight()

            self.layer.mask = pulseLayer
            self.layer.masksToBounds = true
            self.layer.addSublayer(opacityLayer)
        
        } else {
            
            self.layer.mask = pulseLayer
            self.layer.masksToBounds = true
        }
    }
    
    /// animates the highlight of toView to which the tipView is pointed to.
    private func animateHighlight() {
        
        let animationGroup1 = CAAnimationGroup()
        let animationGroup2 = CAAnimationGroup()
        
        let pulseAnimation = CABasicAnimation(keyPath: "path")
        pulseAnimation.fromValue = supportPulsePath.cgPath
        pulseAnimation.toValue = supportOpacityPath.cgPath
        pulseAnimation.duration = 0.5
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = Float.infinity
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        let pulseAnimation1 = CABasicAnimation(keyPath: "path")
        pulseAnimation1.fromValue = pulsePath.cgPath
        pulseAnimation1.toValue = fadePath.cgPath
        pulseAnimation1.duration = 1
        pulseAnimation1.autoreverses = false
        pulseAnimation1.timingFunction = CAMediaTimingFunction(name: .linear)
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1
        opacityAnimation.toValue = 0
        opacityAnimation.duration = 1
        opacityAnimation.autoreverses = false
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        animationGroup1.animations = [pulseAnimation]
        animationGroup1.repeatCount = .infinity
        animationGroup1.duration = 1
        
        animationGroup2.animations = [pulseAnimation1, opacityAnimation]
        animationGroup2.repeatCount = .infinity
        animationGroup2.duration = 1
        
        pulseLayer.add(animationGroup1, forKey: "pulse")
        opacityLayer.add(animationGroup2, forKey: "opacity")
    }
}
