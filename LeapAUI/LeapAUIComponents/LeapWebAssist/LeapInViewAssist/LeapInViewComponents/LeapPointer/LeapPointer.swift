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
    
    override init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, toView: UIView, insideView: UIView? = nil, baseUrl: String?, projectParametersInfo: [String : Any]? = nil) {
        super.init(withDict: assistDict, iconDict: iconDict, toView: toView, insideView: insideView, baseUrl: baseUrl, projectParametersInfo: projectParametersInfo)
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
        self.removeFromSuperview()
    }
    
    override func performExitAnimation(animation: String, byUser: Bool, autoDismissed: Bool, byContext: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        super.performExitAnimation(animation: animation, byUser: byUser, autoDismissed: autoDismissed, byContext: byContext, panelOpen: panelOpen, action: action)
    }
    
    override func hide() {
        self.pointerLayer.isHidden = true
        self.isHidden = true
    }
    
    override func unhide() {
        self.pointerLayer.isHidden = false
        self.isHidden = false
    }
}

class LeapFingerPointer: LeapPointer {
    
    var ringLayer: CAShapeLayer
    var fingerLayer: CALayer
    let pulse = CAAnimationGroup()
    let clickAnimation = CAAnimationGroup()
    
    /// random unique id generated to send certain events only once if tap is recognized twice by the system
    private var id = String.generateUUIDString()
        
    override init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, toView: UIView, insideView: UIView? = nil, baseUrl: String?, projectParametersInfo: [String : Any]? = nil) {
        
        fingerLayer = CALayer()
        ringLayer = CAShapeLayer()
        
        super.init(withDict: assistDict, iconDict: iconDict, toView: toView, insideView: insideView, baseUrl: baseUrl, projectParametersInfo: projectParametersInfo)
                        
        fingerLayer.contents = getFingerPointerImage()?.cgImage
        
        ringLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 1, height: 1)).cgPath
        
        ringLayer.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6).cgColor
        
        pointerLayer.addSublayer(ringLayer)
        ringLayer.frame = CGRect(x: 50, y: 50, width: 1, height: 1)
        
        pointerLayer.addSublayer(fingerLayer)
        fingerLayer.frame = CGRect(x: 34.5, y: 50, width: 41, height: 50)
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
        let y = webRect!.midY - 50
        let x = webRect!.midX - 50
        pointerLayer.frame = CGRect(x: x, y: y, width: 100, height: 100)
        self.inView?.addSubview(self)
        configureOverlayView()
        self.layer.addSublayer(pointerLayer)
        pointerLayer.zPosition = 10
        delegate?.didPresentAssist()
        startAnimation()
        addNotifiers()
    }
    
    override func updateRect(newRect: CGRect, inView: UIView?) {
        self.inView = inView
        webRect = newRect
        let y = webRect!.midY - 50
        let x = webRect!.midX - 50
        pointerLayer.frame = CGRect(x: x, y: y, width: 100, height: 100)
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
        let y = toViewFrame.midY - 50
        let x = toViewFrame.midX - 50
        pointerLayer.frame = CGRect(x: x, y: y, width: 100, height: 100)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "position" {
            setPosition()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    override func appWillEnterForeground() {
        fingerLayer.removeAllAnimations()
        ringLayer.removeAllAnimations()
        
        startAnimation()
    }
    
    override func startAnimation(toRect: CGRect? = nil) {
        let fingerAnimation = CABasicAnimation(keyPath: "transform.scale")
        fingerAnimation.fromValue = NSValue(caTransform3D: CATransform3DIdentity)
        fingerAnimation.toValue = NSValue(caTransform3D: CATransform3DMakeScale(0.667, 0.667, 1))
        fingerAnimation.beginTime = 0.2
        fingerAnimation.duration = 0.3
        fingerAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let anchorAnimation1 = CABasicAnimation(keyPath: "anchorPoint")
        anchorAnimation1.fromValue = CGPoint(x: 0.5, y: 0.5)
        anchorAnimation1.toValue = CGPoint(x: 0.56, y: 0.75)
        anchorAnimation1.beginTime = 0.2
        anchorAnimation1.duration = 0.3
        anchorAnimation1.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let reverseFingerAnimation = CABasicAnimation(keyPath: "transform.scale")
        reverseFingerAnimation.fromValue = fingerAnimation.toValue
        reverseFingerAnimation.toValue = fingerAnimation.fromValue
        reverseFingerAnimation.beginTime = 0.5
        reverseFingerAnimation.duration = 0.3
        reverseFingerAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let anchorAnimation2 = CABasicAnimation(keyPath: "anchorPoint")
        anchorAnimation2.fromValue = anchorAnimation1.toValue
        anchorAnimation2.toValue = anchorAnimation1.fromValue
        anchorAnimation2.beginTime = 0.5
        anchorAnimation2.duration = 0.3
        anchorAnimation2.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = NSValue(caTransform3D: CATransform3DIdentity)
        scaleAnimation.toValue = NSValue(caTransform3D: CATransform3DMakeScale(70, 70, 1))
        scaleAnimation.beginTime = 0.5
        scaleAnimation.duration = 0.9
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.0
        opacityAnimation.beginTime = 0.65
        opacityAnimation.duration = 0.75
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        clickAnimation.animations = [fingerAnimation, reverseFingerAnimation, anchorAnimation1, anchorAnimation2]
        clickAnimation.beginTime = 0
        clickAnimation.duration = 1.4
        clickAnimation.repeatCount = .infinity

        pulse.animations = [scaleAnimation, opacityAnimation]
        pulse.duration = 1.4
        pulse.beginTime = CACurrentMediaTime()
        pulse.repeatCount = .infinity
        
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
    
    override func performExitAnimation(animation: String, byUser: Bool, autoDismissed: Bool, byContext: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        super.performExitAnimation(animation: animation, byUser: byUser, autoDismissed: autoDismissed, byContext: byContext, panelOpen: panelOpen, action: action)
        removePointer()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
                
        let hitTestView = super.hitTest(point, with: event)
        
        let frameForToView = getGlobalToViewFrame()
        
        guard let viewToCheck = toView else {
            
            return hitTestView
        }
        
        if frameForToView.contains(point) {
            
            if (assistInfo?.layoutInfo?.dismissAction.dismissOnAnchorClick ?? false) {
                
                var action: [String : Any] = [:]
                
                if (assistInfo?.highlightClickable ?? false) {
                    
                    action = [constant_body: [constant_anchorClick: true]]
                }
                                
                performExitAnimation(animation: self.assistInfo?.layoutInfo?.exitAnimation ?? "fade_out", byUser: true, autoDismissed: false, byContext: false, panelOpen: false, action: action)
                
                self.removeFromSuperview()
                                
                return viewToCheck
            
            } else if (assistInfo?.highlightClickable ?? false) {
                
                self.delegate?.sendAUIEvent(action: [constant_body: [constant_anchorClick: true, constant_id: id]])
                
                return nil
            
            } else {
                
                return hitTestView
            }
        
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
    
    var toRect: CGRect?
    
    private var screenWidth = UIScreen.main.bounds.width
    
    override init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, toView: UIView, insideView: UIView? = nil, baseUrl:String?, projectParametersInfo: [String : Any]? = nil) {
        
        fingerLayer = CALayer()
        ringLayer = CAShapeLayer()
        
        super.init(withDict: assistDict, iconDict: iconDict, toView: toView, insideView: insideView, baseUrl: baseUrl, projectParametersInfo: projectParametersInfo)
                
        fingerLayer.contents = getFingerPointerImage()?.cgImage
        
        ringLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 20, height: 20)).cgPath
        
        ringLayer.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0).cgColor
        ringLayer.strokeColor = UIColor.white.cgColor
        ringLayer.lineWidth = 1.0
        
        pointerLayer.addSublayer(ringLayer)
        ringLayer.frame = CGRect(x: 40, y: 40, width: 20, height: 20)
        
        pointerLayer.addSublayer(fingerLayer)
        fingerLayer.frame = CGRect(x: 34.5, y: 48, width: 41, height: 50)
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
        pointerLayer.frame.size = CGSize(width: 100, height: 100)
        self.inView = inView
        let toViewFrame = toRect
        var y = toViewFrame.midY - 50
        var x = (toViewFrame.midX - pointerLayer.frame.size.width/2) - (1/4*screenWidth)
        switch type {
        case .swipeLeft:
            y = toViewFrame.midY - 50
            x = (toViewFrame.midX - pointerLayer.frame.size.width/2) + (1/4*screenWidth)
        case .swipeRight:
            y = toViewFrame.midY - 50
            x = (toViewFrame.midX - pointerLayer.frame.size.width/2) - (1/4*screenWidth)
        case .swipeUp:
            y = (toViewFrame.midY - pointerLayer.frame.size.height/2) + (1/4*screenWidth)
            x = toViewFrame.midX - 50
        case .swipeDown:
            y = (toViewFrame.midY - pointerLayer.frame.size.height/2) - (1/4*screenWidth)
            x = toViewFrame.midX - 50
        }
        pointerLayer.frame = CGRect(x: x, y: y, width: 100, height: 100)
        inView?.layer.addSublayer(pointerLayer)
        pointerLayer.zPosition = 10
        toView?.layer.addObserver(pointerLayer, forKeyPath: "position", options: [.new,.old], context: nil)
        delegate?.didPresentAssist()
        self.toRect = toRect
        startAnimation(toRect: toRect)
        addNotifiers()
    }
    
    override func updateRect(newRect: CGRect, inView: UIView?) {
        
        if toRect == newRect { return }
        
        self.inView = inView
        pointerLayer.frame.size = CGSize(width: 100, height: 100)
        let toViewFrame = newRect
        var y = toViewFrame.midY - 50
        var x = (toViewFrame.midX - pointerLayer.frame.size.width/2) - (1/4*screenWidth)
        switch type {
        case .swipeLeft:
            y = toViewFrame.midY - 50
            x = (toViewFrame.midX - pointerLayer.frame.size.width/2) + (1/4*screenWidth)
        case .swipeRight:
            y = toViewFrame.midY - 50
            x = (toViewFrame.midX - pointerLayer.frame.size.width/2) - (1/4*screenWidth)
        case .swipeUp:
            y = (toViewFrame.midY - pointerLayer.frame.size.height/2) + (1/4*screenWidth)
            x = toViewFrame.midX - 50
        case .swipeDown:
            y = (toViewFrame.midY - pointerLayer.frame.size.height/2) - (1/4*screenWidth)
            x = toViewFrame.midX - 50
        }
        pointerLayer.frame = CGRect(x: x, y: y, width: 100, height: 100)
        
        toRect = newRect
        
        resetAnimation()
    }
    
    override func presentPointer(view: UIView) {
        toView = view
        inView = toView?.window
        presentPointer()
    }
    
    func setPosition() {
        guard let toViewFrame = getToViewPositionForInView() else { return }
        pointerLayer.frame.size = CGSize(width: 100, height: 100)
        var y = toViewFrame.midY - 50
        var x = (toViewFrame.midX - pointerLayer.frame.size.width/2) - (1/4*screenWidth)
        switch type {
        case .swipeLeft:
            y = toViewFrame.midY - 50
            x = (toViewFrame.midX - pointerLayer.frame.size.width/2) + (1/4*screenWidth)
        case .swipeRight:
            y = toViewFrame.midY - 50
            x = (toViewFrame.midX - pointerLayer.frame.size.width/2) - (1/4*screenWidth)
        case .swipeUp:
            y = (toViewFrame.midY - pointerLayer.frame.size.height/2) + (1/4*screenWidth)
            x = toViewFrame.midX - 50
        case .swipeDown:
            y = (toViewFrame.midY - pointerLayer.frame.size.height/2) - (1/4*screenWidth)
            x = toViewFrame.midX - 50
        }
        pointerLayer.frame = CGRect(x: x, y: y, width: 100, height: 100)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "position" {
            setPosition()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    override func appWillEnterForeground() {
        resetAnimation()
    }
    
    func resetAnimation() {
        pointerLayer.removeAllAnimations()
        
        startAnimation(toRect: toRect)
    }
    
    override func startAnimation(toRect: CGRect? = nil) {
        
        //Zero opacity animation
        let zeroOpacityAnimation = CABasicAnimation(keyPath: "opacity")
        zeroOpacityAnimation.beginTime = 0
        zeroOpacityAnimation.fromValue = 0
        zeroOpacityAnimation.toValue = 0
        zeroOpacityAnimation.duration = 0.3
        zeroOpacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // FadeIn Animation
        let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
        fadeInAnimation.beginTime = 0.3
        fadeInAnimation.fromValue = 0
        fadeInAnimation.toValue = 1
        fadeInAnimation.duration = 0.3
        fadeInAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // Finger Animation
        let fingerAnimation = CABasicAnimation()
        fingerAnimation.beginTime = 0.6
        fingerAnimation.duration = 1
        fingerAnimation.fillMode = .forwards
        fingerAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        // FadeOut Animation
        let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
        fadeOutAnimation.beginTime = 1.45
        fadeOutAnimation.fromValue = 1
        fadeOutAnimation.toValue = 0
        fadeOutAnimation.duration = 0.15
        fadeOutAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
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
        group.duration = 1.6
        group.animations = [zeroOpacityAnimation, fadeInAnimation, fingerAnimation, fadeOutAnimation]
        group.repeatCount = .infinity
        
        pointerLayer.add(group, forKey: "slideFade")
    }
    
    override func removeAnimation() {
        pointerLayer.removeAllAnimations()
    }
    
    override func removePointer() {
        if let _ = toView?.layer.observationInfo { toView?.layer.removeObserver(pointerLayer, forKeyPath: "position")  }
        super.removePointer()
    }
    
    override func performExitAnimation(animation: String, byUser: Bool, autoDismissed: Bool, byContext: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        super.performExitAnimation(animation: animation, byUser: byUser, autoDismissed: autoDismissed, byContext: byContext, panelOpen: panelOpen, action: action)
        removePointer()
    }
}
