//
//  LeapPointer.swift
//  LeapAUI
//
//  Created by Aravind GS on 19/03/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import UIKit

class LeapPointer: LeapInViewAssist {
    
    var pointerLayer = CAShapeLayer()
    
    override init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, toView: UIView, insideView: UIView? = nil, baseUrl: String?) {
        super.init(withDict: assistDict, iconDict: iconDict, toView: toView, insideView: insideView, baseUrl: baseUrl)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addNotifiers() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    func getFingerPointerImage() -> UIImage? {
        return UIImage.getImageFromBundle("fingerPointer")
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
    
    func presentPointer(view: UIView) {
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
    
    func getToViewPositionForInView() -> CGRect? {
        guard toView != nil, inView != nil else { return nil }
        return toView?.superview?.convert(toView!.frame, to: inView!)
    }
    
    func removeAnimation() {
        pointerLayer.removeAllAnimations()
    }
    
    func removePointer() {
        pointerLayer.removeFromSuperlayer()
    }
    
    override func performExitAnimation(animation: String, byUser: Bool, autoDismissed: Bool, byContext: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        super.performExitAnimation(animation: self.assistInfo?.layoutInfo?.exitAnimation ?? "", byUser: byUser, autoDismissed: autoDismissed, byContext: byContext, panelOpen: panelOpen, action: action)
    }
    
    override func hide() {
        self.pointerLayer.isHidden = true
    }
    
    override func unhide() {
        self.pointerLayer.isHidden = false
    }
}

class LeapFingerPointer: LeapPointer {
    
    var ringLayer: CAShapeLayer
    var fingerLayer: CALayer
    let pulse = CAAnimationGroup()
    let clickAnimation = CAAnimationGroup()
    
    private var id = String.generateUUIDString()
        
    override init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, toView: UIView, insideView: UIView? = nil, baseUrl: String?) {
        
        fingerLayer = CALayer()
        ringLayer = CAShapeLayer()
        
        super.init(withDict: assistDict, iconDict: iconDict, toView: toView, insideView: insideView, baseUrl: baseUrl)
                        
        fingerLayer.contents = getFingerPointerImage()?.cgImage
        
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
        self.layer.addSublayer(pointerLayer)
        setPosition()
        inView?.layer.addObserver(pointerLayer, forKeyPath: "position", options: [.new,.old], context: nil)
        delegate?.didPresentAssist()
        startAnimation()
        addNotifiers()
    }
    
    override func presentPointer(toRect: CGRect, inView:UIView?) {
        self.inView = inView
        webRect = toRect
        let y = webRect!.midY - 15
        let x = webRect!.midX - 21
        pointerLayer.frame = CGRect(x: x, y: y, width: 42, height: 54)
        self.inView?.addSubview(self)
        configureOverlayView()
        self.layer.addSublayer(pointerLayer)
        pointerLayer.zPosition = 10
        delegate?.didPresentAssist()
        startAnimation()
    }
    
    override func updateRect(newRect: CGRect, inView: UIView?) {
        self.inView = inView
        webRect = newRect
        let y = webRect!.midY - 15
        let x = webRect!.midX - 21
        pointerLayer.frame = CGRect(x: x, y: y, width: 42, height: 54)
    }
    
    override func presentPointer(view: UIView) {
        toView = view
        inView = toView?.window
        inView?.addSubview(self)
        configureOverlayView()
        presentPointer()
    }
    
    override func configureOverlayView() {
        
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
    
    func setPosition() {
        guard let toViewFrame = getToViewPositionForInView() else { return }
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
        self.removeFromSuperview()
        super.removePointer()
    }
    
    override func performExitAnimation(animation: String, byUser: Bool, autoDismissed: Bool, byContext: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        removePointer()
        super.performExitAnimation(animation: self.assistInfo?.layoutInfo?.exitAnimation ?? "", byUser: byUser, autoDismissed: autoDismissed, byContext: byContext, panelOpen: panelOpen, action: action)
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
}

enum LeapSwipePointerType: String {
    case swipeLeft = "SWIPE_LEFT"
    case swipeRight = "SWIPE_RIGHT"
    case swipeUp = "SWIPE_UP"
    case swipeDown = "SWIPE_DOWN"
}

class LeapSwipePointer: LeapPointer {
    
    var type: LeapSwipePointerType = .swipeDown // Default
    
    var ringLayer: CAShapeLayer
    var fingerLayer: CALayer
    
    let swipeAnimation = CAAnimationGroup()
    
    private var screenWidth = UIScreen.main.bounds.width
    
    override init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, toView: UIView, insideView: UIView? = nil, baseUrl:String?) {
        
        fingerLayer = CALayer()
        ringLayer = CAShapeLayer()
        
        super.init(withDict: assistDict, iconDict: iconDict, toView: toView, insideView: insideView, baseUrl: baseUrl)
                
        fingerLayer.contents = getFingerPointerImage()?.cgImage
        
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
        inView = toView?.window
        presentPointer()
    }
    
    func setPosition() {
        guard let toViewFrame = getToViewPositionForInView() else { return }
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
        
        guard let toViewFrame = toRect ?? getToViewPositionForInView() else { return }
        
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
    
    override func performExitAnimation(animation: String, byUser: Bool, autoDismissed: Bool, byContext: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        removePointer()
        super.performExitAnimation(animation: self.assistInfo?.layoutInfo?.exitAnimation ?? "", byUser: byUser, autoDismissed: autoDismissed, byContext: byContext, panelOpen: panelOpen, action: action)
    }
}
