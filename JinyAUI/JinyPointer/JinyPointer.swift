//
//  JinyPointer.swift
//  JinySDK
//
//  Created by Aravind GS on 19/03/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class JinyPointer: JinyInViewAssist {
    
    var pointerLayer = CAShapeLayer()
    
    override init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, toView: UIView, insideView: UIView? = nil) {
        super.init(withDict: assistDict, iconDict: iconDict, toView: toView, insideView: insideView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addNotifiers() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    func getInnerPath() -> UIBezierPath {
        
        let innerPath = UIBezierPath()
        innerPath.move(to: CGPoint(x: 12, y: 2))
        innerPath.addCurve(to: CGPoint(x: 14, y: 4), controlPoint1: CGPoint(x: 13.13, y: 2), controlPoint2: CGPoint(x: 14, y: 2.87))
        innerPath.addLine(to: CGPoint(x: 14, y: 14.5))
        innerPath.addCurve(to: CGPoint(x: 14.78, y: 15.49), controlPoint1: CGPoint(x: 13.99, y: 14.95), controlPoint2: CGPoint(x: 14.33, y: 15.39))
        innerPath.addCurve(to: CGPoint(x: 15.91, y: 14.94), controlPoint1: CGPoint(x: 15.22, y: 15.59), controlPoint2: CGPoint(x: 15.71, y: 15.35))
        innerPath.addCurve(to: CGPoint(x: 17.5, y: 14), controlPoint1: CGPoint(x: 16.13, y: 14.48), controlPoint2: CGPoint(x: 16.96, y: 14))
        innerPath.addCurve(to: CGPoint(x: 18.48, y: 14.31), controlPoint1: CGPoint(x: 17.74, y: 14), controlPoint2: CGPoint(x: 18.19, y: 14.1))
        innerPath.addCurve(to: CGPoint(x: 19, y: 15.5), controlPoint1: CGPoint(x: 18.78, y: 14.52), controlPoint2: CGPoint(x: 19, y: 14.77))
        innerPath.addCurve(to: CGPoint(x: 19.77, y: 16.47), controlPoint1: CGPoint(x: 19, y: 15.94), controlPoint2: CGPoint(x: 19.34, y: 16.37))
        innerPath.addLine(to: CGPoint(x: 19.77, y: 16.47))
        innerPath.addCurve(to: CGPoint(x: 20.89, y: 15.95), controlPoint1: CGPoint(x: 20.22, y: 16.57), controlPoint2: CGPoint(x: 20.68, y: 16.35))
        innerPath.addCurve(to: CGPoint(x: 22.02, y: 15), controlPoint1: CGPoint(x: 21.3, y: 15.14), controlPoint2: CGPoint(x: 21.52, y: 15.01))
        innerPath.addCurve(to: CGPoint(x: 22.95, y: 15.31), controlPoint1: CGPoint(x: 22.15, y: 15), controlPoint2: CGPoint(x: 22.64, y: 15.09))
        innerPath.addCurve(to: CGPoint(x: 23.5, y: 16.5), controlPoint1: CGPoint(x: 23.27, y: 15.53), controlPoint2: CGPoint(x: 23.5, y: 15.79))
        innerPath.addCurve(to: CGPoint(x: 24.1, y: 17.42), controlPoint1: CGPoint(x: 23.5, y: 16.89), controlPoint2: CGPoint(x: 23.74, y: 17.27))
        innerPath.addCurve(to: CGPoint(x: 25.19, y: 17.23), controlPoint1: CGPoint(x: 24.46, y: 17.58), controlPoint2: CGPoint(x: 24.9, y: 17.5))
        innerPath.addCurve(to: CGPoint(x: 26.42, y: 17), controlPoint1: CGPoint(x: 25.57, y: 17.05), controlPoint2: CGPoint(x: 25.94, y: 16.99))
        innerPath.addCurve(to: CGPoint(x: 28.66, y: 19.39), controlPoint1: CGPoint(x: 27.61, y: 17.15), controlPoint2: CGPoint(x: 28.23, y: 17.9))
        innerPath.addCurve(to: CGPoint(x: 28.75, y: 25.31), controlPoint1: CGPoint(x: 29.08, y: 20.9), controlPoint2: CGPoint(x: 29.1, y: 23.05))
        innerPath.addCurve(to: CGPoint(x: 26.83, y: 31.94), controlPoint1: CGPoint(x: 28.4, y: 27.58), controlPoint2: CGPoint(x: 27.71, y: 29.95))
        innerPath.addCurve(to: CGPoint(x: 24.09, y: 36), controlPoint1: CGPoint(x: 26, y: 33.8), controlPoint2: CGPoint(x: 24.99, y: 35.25))
        innerPath.addLine(to: CGPoint(x: 11.48, y: 36))
        innerPath.addCurve(to: CGPoint(x: 2.44, y: 20.14), controlPoint1: CGPoint(x: 7.97, y: 31.86), controlPoint2: CGPoint(x: 4.62, y: 25.5))
        innerPath.addCurve(to: CGPoint(x: 2.05, y: 17.92), controlPoint1: CGPoint(x: 1.98, y: 18.97), controlPoint2: CGPoint(x: 1.94, y: 18.3))
        innerPath.addCurve(to: CGPoint(x: 4.34, y: 16.55), controlPoint1: CGPoint(x: 2.42, y: 16.95), controlPoint2: CGPoint(x: 3.45, y: 16.41))
        innerPath.addCurve(to: CGPoint(x: 6.13, y: 18.47), controlPoint1: CGPoint(x: 5.41, y: 16.95), controlPoint2: CGPoint(x: 5.67, y: 17.66))
        innerPath.addLine(to: CGPoint(x: 8.11, y: 22.45))
        innerPath.addLine(to: CGPoint(x: 8.11, y: 22.45))
        innerPath.addCurve(to: CGPoint(x: 9.23, y: 22.97), controlPoint1: CGPoint(x: 8.32, y: 22.85), controlPoint2: CGPoint(x: 8.78, y: 23.07))
        innerPath.addLine(to: CGPoint(x: 9.24, y: 22.97))
        innerPath.addCurve(to: CGPoint(x: 10, y: 21.99), controlPoint1: CGPoint(x: 9.68, y: 22.85), controlPoint2: CGPoint(x: 9.99, y: 22.45))
        innerPath.addLine(to: CGPoint(x: 10, y: 4))
        innerPath.addCurve(to: CGPoint(x: 12, y: 2), controlPoint1: CGPoint(x: 10, y: 2.87), controlPoint2: CGPoint(x: 10.88, y: 2))
        innerPath.close()
        return innerPath
    }
    
    func removeNotifiers() {
        
    }
    @objc func appWillEnterForeground () {
        startAnimation()
    }
    
    @objc func appDidEnterBackground() {
        removeAnimation()
    }
    
    func startAnimation(toRect: CGRect? = nil) {
        
    }
    
    func presentPointer() {
        
    }
    
    func presentPointer(view:UIView) {
        toView = view
        if toView?.window != UIApplication.shared.keyWindow {
            inView = toView!.window
        } else {
            inView = UIApplication.getCurrentVC()?.view
        }
        presentPointer()
    }
    
    func presentPointer(toRect:CGRect, inView:UIView?) {
        
    }
    
    func updateRect(newRect:CGRect, inView:UIView?) {
        
    }
    
    func getToViewPositionForInView() -> CGRect {
        return toView!.superview!.convert(toView!.frame, to: inView!)
    }
    
    func removeAnimation() {
        pointerLayer.removeAllAnimations()
    }
    
    func removePointer() {
        pointerLayer.removeFromSuperlayer()
    }
    
    override func remove(byContext: Bool, byUser: Bool, autoDismissed: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        super.remove(byContext: byContext, byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
    }
    
}

class JinyFingerRipplePointer:JinyPointer {
    
    var ringLayer:CAShapeLayer
    var fingerLayer:CAShapeLayer
    let pulse = CAAnimationGroup()
    let clickAnimation = CAAnimationGroup()
    
    override init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, toView: UIView, insideView: UIView? = nil) {
        
        fingerLayer = CAShapeLayer()
        ringLayer = CAShapeLayer()
        
        super.init(withDict: assistDict, iconDict: iconDict, toView: toView, insideView: insideView)
                
        let pointerPath = getInnerPath()
        
        fingerLayer.path = pointerPath.cgPath
        fingerLayer.fillColor = UIColor(red: 0.941, green: 0.663, blue: 0.122, alpha: 1.000).cgColor
        fingerLayer.fillRule = .nonZero
        fingerLayer.strokeColor = UIColor.white.cgColor
        fingerLayer.lineWidth = 2.0
        
        ringLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 1, height: 1)).cgPath
        
        ringLayer.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6).cgColor
        
        pointerLayer.addSublayer(ringLayer)
        ringLayer.frame = CGRect(x: 21, y: 20, width: 1, height: 1)
        
        pointerLayer.addSublayer(fingerLayer)
        fingerLayer.frame = CGRect(x: 9, y: 10, width: 31, height: 39)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func presentPointer() {
        inView?.layer.addSublayer(pointerLayer)
        setPosition()
        toView?.layer.addObserver(pointerLayer, forKeyPath: "position", options: [.new,.old], context: nil)
        delegate?.didPresentAssist()
        startAnimation()
        addNotifiers()
    }
    
    override func presentPointer(toRect: CGRect, inView:UIView?) {
        self.inView = inView
        let toViewFrame = toRect
        let y = toViewFrame.midY - 15
        let x = toViewFrame.midX - 21
        pointerLayer.frame = CGRect(x: x, y: y, width: 42, height: 54)
        inView?.layer.addSublayer(pointerLayer)
        pointerLayer.zPosition = 10
        delegate?.didPresentAssist()
        startAnimation()
    }
    
    override func updateRect(newRect: CGRect, inView: UIView?) {
        self.inView = inView
        let toViewFrame = newRect
        let y = toViewFrame.midY - 15
        let x = toViewFrame.midX - 21
        pointerLayer.frame = CGRect(x: x, y: y, width: 42, height: 54)
    }
    
    override func presentPointer(view: UIView) {
        toView = view
        inView = findEligibleInView(view: toView!)
        presentPointer()
    }
    
    func findEligibleInView(view:UIView) -> UIView{
        let eligibleView = view
        if canCompletelyHoldPointer(eligibleView) { return eligibleView }
        guard let superView = eligibleView.superview else { return eligibleView }
        if eligibleView.clipsToBounds == false && eligibleView.layer.masksToBounds == false {
            if canCompletelyHoldPointer(superView) { return eligibleView }
            else { return findEligibleInView(view: superView) }
        } else {
            return findEligibleInView(view: superView)
        }
    }
    
    func canCompletelyHoldPointer(_ view:UIView) -> Bool {
        return (view.bounds.height > 80 && view.bounds.width > 80)
    }
    
    func setPosition() {
        let toViewFrame = getToViewPositionForInView()
        let y = toViewFrame.midY - 15
        let x = toViewFrame.midX - 21
        pointerLayer.frame = CGRect(x: x, y: y, width: 42, height: 54)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "position" {
            setPosition()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    override func startAnimation(toRect: CGRect? = nil) {
        let fingerAnimation = CABasicAnimation(keyPath: "transform.scale")
        fingerAnimation.fromValue = NSValue(caTransform3D: CATransform3DIdentity)
        fingerAnimation.toValue = NSValue(caTransform3D: CATransform3DMakeScale(0.5, 0.5, 1))
        fingerAnimation.duration = 0.5
        fingerAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        fingerAnimation.autoreverses = true
        
        clickAnimation.animations = [fingerAnimation]
        clickAnimation.repeatCount = .infinity
        clickAnimation.duration = 1.3
        clickAnimation.beginTime = CACurrentMediaTime()
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = NSValue(caTransform3D: CATransform3DIdentity)
        scaleAnimation.toValue = NSValue(caTransform3D: CATransform3DMakeScale(40, 40, 1))
        scaleAnimation.duration = 0.5
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.0
        opacityAnimation.duration = 0.5
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        pulse.animations = [scaleAnimation, opacityAnimation]
        pulse.repeatCount = .infinity
        pulse.duration = 1.3
        pulse.beginTime = CACurrentMediaTime() + 0.5
        
        fingerLayer.masksToBounds = false
        ringLayer.masksToBounds = false
        pointerLayer.masksToBounds = false
        
        fingerLayer.add(clickAnimation, forKey: constant_click)
        ringLayer.add(pulse, forKey: "pulse")
        
    }
    
    override func removeAnimation() {
        ringLayer.removeAllAnimations()
    }
    
    override func removePointer() {
        if let _ = toView?.layer.observationInfo { toView?.layer.removeObserver(pointerLayer, forKeyPath: "position") }
        super.removePointer()
    }
    
    override func remove(byContext: Bool, byUser: Bool, autoDismissed: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        removePointer()
        super.remove(byContext: byContext, byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
    }
}

enum JinySwipePointerType: String {
    case swipeLeft = "SWIPE_LEFT"
    case swipeRight = "SWIPE_RIGHT"
    case swipeUp = "SWIPE_UP"
    case swipeDown = "SWIPE_DOWN"
}

class JinySwipePointer: JinyPointer {
    
    var type: JinySwipePointerType = .swipeDown // Default
    
    var ringLayer: CAShapeLayer
    var fingerLayer: CAShapeLayer
    
    let swipeAnimation = CAAnimationGroup()
    
    private var screenWidth = UIScreen.main.bounds.width
    
    override init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, toView: UIView, insideView: UIView? = nil) {
        
        fingerLayer = CAShapeLayer()
        ringLayer = CAShapeLayer()
        
        super.init(withDict: assistDict, iconDict: iconDict, toView: toView, insideView: insideView)
        
        let pointerPath = getInnerPath()
        
        fingerLayer.path = pointerPath.cgPath
        fingerLayer.fillColor = UIColor(red: 0.941, green: 0.663, blue: 0.122, alpha: 1.000).cgColor
        fingerLayer.fillRule = .nonZero
        fingerLayer.strokeColor = UIColor.white.cgColor
        fingerLayer.lineWidth = 2.0
        
        ringLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 20, height: 20)).cgPath
        
        ringLayer.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0).cgColor
        ringLayer.strokeColor = UIColor.white.cgColor
        ringLayer.lineWidth = 5.0
        
        pointerLayer.addSublayer(ringLayer)
        ringLayer.frame = CGRect(x: 11, y: 4, width: 20, height: 20)
        
        pointerLayer.addSublayer(fingerLayer)
        fingerLayer.frame = CGRect(x: 9, y: 10, width: 31, height: 39)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func presentPointer() {
        inView?.layer.addSublayer(pointerLayer)
        setPosition()
        toView?.layer.addObserver(pointerLayer, forKeyPath: "position", options: [.new,.old], context: nil)
        delegate?.didPresentAssist()
        startAnimation()
        addNotifiers()
    }
    
    override func presentPointer(toRect: CGRect, inView:UIView?) {
        pointerLayer.frame.size = CGSize(width: 42, height: 54)
        self.inView = inView
        let toViewFrame = toRect
        var y = toViewFrame.midY - 15
        var x = (toViewFrame.midX - pointerLayer.frame.size.width/2) - (1/4*screenWidth)
        switch type {
        case .swipeLeft:
            y = toViewFrame.midY - 15
            x = (toViewFrame.midX - pointerLayer.frame.size.width/2) + (1/4*screenWidth)
        case .swipeRight:
            y = toViewFrame.midY - 15
            x = (toViewFrame.midX - pointerLayer.frame.size.width/2) - (1/4*screenWidth)
        case .swipeUp:
            y = (toViewFrame.midY - pointerLayer.frame.size.height/2) + (1/4*screenWidth)
            x = toViewFrame.midX - 21
        case .swipeDown:
            y = (toViewFrame.midY - pointerLayer.frame.size.height/2) - (1/4*screenWidth)
            x = toViewFrame.midX - 21
        }
        pointerLayer.frame = CGRect(x: x, y: y, width: 42, height: 54)
        inView?.layer.addSublayer(pointerLayer)
        pointerLayer.zPosition = 10
        toView?.layer.addObserver(pointerLayer, forKeyPath: "position", options: [.new,.old], context: nil)
        delegate?.didPresentAssist()
        startAnimation(toRect: toRect)
    }
    
    override func updateRect(newRect: CGRect, inView: UIView?) {
        self.inView = inView
        pointerLayer.frame.size = CGSize(width: 42, height: 54)
        let toViewFrame = newRect
        var y = toViewFrame.midY - 15
        var x = (toViewFrame.midX - pointerLayer.frame.size.width/2) - (1/4*screenWidth)
        switch type {
        case .swipeLeft:
            y = toViewFrame.midY - 15
            x = (toViewFrame.midX - pointerLayer.frame.size.width/2) + (1/4*screenWidth)
        case .swipeRight:
            y = toViewFrame.midY - 15
            x = (toViewFrame.midX - pointerLayer.frame.size.width/2) - (1/4*screenWidth)
        case .swipeUp:
            y = (toViewFrame.midY - pointerLayer.frame.size.height/2) + (1/4*screenWidth)
            x = toViewFrame.midX - 21
        case .swipeDown:
            y = (toViewFrame.midY - pointerLayer.frame.size.height/2) - (1/4*screenWidth)
            x = toViewFrame.midX - 21
        }
        pointerLayer.frame = CGRect(x: x, y: y, width: 42, height: 54)
    }
    
    override func presentPointer(view: UIView) {
        toView = view
        inView = findEligibleInView(view: toView!)
        presentPointer()
    }
    
    func findEligibleInView(view:UIView) -> UIView{
        let eligibleView = view
        if canCompletelyHoldPointer(eligibleView) { return eligibleView }
        guard let superView = eligibleView.superview else { return eligibleView }
        if eligibleView.clipsToBounds == false && eligibleView.layer.masksToBounds == false {
            if canCompletelyHoldPointer(superView) { return eligibleView }
            else { return findEligibleInView(view: superView) }
        } else {
            return findEligibleInView(view: superView)
        }
    }
    
    func canCompletelyHoldPointer(_ view:UIView) -> Bool {
        return (view.bounds.height > 80 && view.bounds.width > 80)
    }
    
    func setPosition() {
        let toViewFrame = getToViewPositionForInView()
        pointerLayer.frame.size = CGSize(width: 42, height: 54)
        var y = toViewFrame.midY - 15
        var x = (toViewFrame.midX - pointerLayer.frame.size.width/2) - (1/4*screenWidth)
        switch type {
        case .swipeLeft:
            y = toViewFrame.midY - 15
            x = (toViewFrame.midX - pointerLayer.frame.size.width/2) + (1/4*screenWidth)
        case .swipeRight:
            y = toViewFrame.midY - 15
            x = (toViewFrame.midX - pointerLayer.frame.size.width/2) - (1/4*screenWidth)
        case .swipeUp:
            y = (toViewFrame.midY - pointerLayer.frame.size.height/2) + (1/4*screenWidth)
            x = toViewFrame.midX - 21
        case .swipeDown:
            y = (toViewFrame.midY - pointerLayer.frame.size.height/2) - (1/4*screenWidth)
            x = toViewFrame.midX - 21
        }
        pointerLayer.frame = CGRect(x: x, y: y, width: 42, height: 54)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "position" {
            setPosition()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    override func startAnimation(toRect: CGRect? = nil) {
                
        let fingerAnimation = CABasicAnimation()
        fingerAnimation.beginTime = 0.2
        fingerAnimation.duration = 1.4
        fingerAnimation.fillMode = .forwards
        fingerAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.beginTime = 1.2
        fadeAnimation.fromValue = 1
        fadeAnimation.toValue = 0
        fadeAnimation.duration = 0.2
        fingerAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        let toViewFrame = toRect ?? getToViewPositionForInView()
        
        switch type {
        
        case .swipeLeft:
            
            fingerAnimation.keyPath = "position.x"
            
            fingerAnimation.fromValue = pointerLayer.position.x
            fingerAnimation.toValue = (toViewFrame.midX - (pointerLayer.frame.size.width/2)) - (1/4*screenWidth)
                        
        case .swipeRight:
            
            fingerAnimation.keyPath = "position.x"
            
            fingerAnimation.fromValue = pointerLayer.position.x
            fingerAnimation.toValue = toViewFrame.midX + (1/4*screenWidth)
                    
        case .swipeUp:
            
            fingerAnimation.keyPath = "position.y"
            
            fingerAnimation.fromValue = pointerLayer.position.y
            fingerAnimation.toValue = (toViewFrame.midY - (pointerLayer.frame.size.height/2)) - (1/4*screenWidth)
                        
        case .swipeDown:
            
            fingerAnimation.keyPath = "position.y"
        
            fingerAnimation.fromValue = pointerLayer.position.y
            fingerAnimation.toValue = toViewFrame.midY + (1/4*screenWidth)
        }
        
        let group = CAAnimationGroup()
        group.duration = 1.4
        group.animations = [fingerAnimation, fadeAnimation]
        group.repeatCount = .infinity
        
        pointerLayer.add(group, forKey: "slideFade")
    }
    
    override func removeAnimation() {
        ringLayer.removeAllAnimations()
    }
    
    override func removePointer() {
        if let _ = toView?.layer.observationInfo { toView?.layer.removeObserver(pointerLayer, forKeyPath: "position")  }
        super.removePointer()
    }
    
    override func remove(byContext: Bool, byUser: Bool, autoDismissed: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        removePointer()
        super.remove(byContext: byContext, byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
    }
}
