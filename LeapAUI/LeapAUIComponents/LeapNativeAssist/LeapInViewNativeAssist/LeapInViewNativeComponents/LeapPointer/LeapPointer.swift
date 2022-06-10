//
//  LeapPointer.swift
//  LeapAUI
//
//  Created by Aravind GS on 19/03/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import UIKit

class LeapPointer: LeapInViewNativeAssist {
    
    var pointerLayer = CAShapeLayer()
    
    override init(withDict assistDict: Dictionary<String, Any>, toView: UIView) {
        super.init(withDict: assistDict, toView: toView)
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
    
    func startAnimation() {
        
    }
    
    func presentPointer() {
        inView?.addSubview(self)
        self.configureOverlayView()
        self.layer.addSublayer(pointerLayer)
        setPosition()
        delegate?.didPresentAssist()
        startAnimation()
        addNotifiers()
    }
    
    func presentPointer(view: UIView) {
        toView = view
        inView = toView?.window
        presentPointer()
    }
    
    func presentPointer(toRect: CGRect, inView: UIView?) {
        self.inView = inView
        webRect = toRect
        presentPointer()
    }
    
    func updateRect(newRect: CGRect, inView: UIView?) {
        
        self.inView = inView
        
        webRect = newRect
        
        // Do the same check in the overridden method, if you're overriding this method.
        guard let previousFrame = self.previousFrame, previousFrame.origin != getGlobalToViewFrame().origin else { return }
        
        setPosition()
        
        resetAnimation()
    }
    
    func updatePosition() {
        
        guard let previousFrame = self.previousFrame, previousFrame.origin != getGlobalToViewFrame().origin else { return }
                        
        setPosition()
        
        resetAnimation()
    }
    
    func removeAnimation() {
        pointerLayer.removeAllAnimations()
    }
    
    func resetAnimation() {
        pointerLayer.removeAllAnimations()
        startAnimation()
    }
    
    func removePointer() {
        pointerLayer.removeFromSuperlayer()
        self.removeFromSuperview()
    }
    
    func setPosition() {
        self.previousFrame = getGlobalToViewFrame()
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
        
    override init(withDict assistDict: Dictionary<String, Any>, toView: UIView) {
        
        fingerLayer = CALayer()
        ringLayer = CAShapeLayer()
        
        super.init(withDict: assistDict, toView: toView)
                        
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
    
    override func setPosition() {
        super.setPosition()
        let toViewFrame = getGlobalToViewFrame()
        let y = toViewFrame.midY - 50
        let x = toViewFrame.midX - 50
        pointerLayer.frame = CGRect(x: x, y: y, width: 100, height: 100)
    }
    
    override func appWillEnterForeground() {
        fingerLayer.removeAllAnimations()
        ringLayer.removeAllAnimations()
        
        startAnimation()
    }
    
    override func startAnimation() {
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
            
    private var screenWidth = UIDevice.current.userInterfaceIdiom == .pad ? swipePointerMaxLengthSupported : UIScreen.main.bounds.width
    
    private var screenHeight = UIDevice.current.userInterfaceIdiom == .pad ? swipePointerMaxLengthSupported : UIScreen.main.bounds.height
    
    override init(withDict assistDict: Dictionary<String, Any>, toView: UIView) {
        
        fingerLayer = CALayer()
        ringLayer = CAShapeLayer()
        
        super.init(withDict: assistDict, toView: toView)
                
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
    
    override func setPosition() {
        super.setPosition()
        let toViewFrame = getGlobalToViewFrame()
        pointerLayer.frame.size = CGSize(width: 100, height: 100)
        
        let screenLength = UIDevice.current.orientation == .landscapeLeft ? screenHeight : screenWidth
        
        var y = toViewFrame.midY - 50
        var x = (toViewFrame.midX - pointerLayer.frame.size.width/2) - (1/4*screenLength)
        switch type {
        case .swipeLeft:
            y = toViewFrame.midY - 50
            x = (toViewFrame.midX - pointerLayer.frame.size.width/2) + (1/4*screenLength)
        case .swipeRight:
            y = toViewFrame.midY - 50
            x = (toViewFrame.midX - pointerLayer.frame.size.width/2) - (1/4*screenLength)
        case .swipeUp:
            y = (toViewFrame.midY - pointerLayer.frame.size.height/2) + (1/4*screenLength)
            x = toViewFrame.midX - 50
        case .swipeDown:
            y = (toViewFrame.midY - pointerLayer.frame.size.height/2) - (1/4*screenLength)
            x = toViewFrame.midX - 50
        }
        pointerLayer.frame = CGRect(x: x, y: y, width: 100, height: 100)
    }
    
    override func appWillEnterForeground() {
        resetAnimation()
    }
    
    override func startAnimation() {
        
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
        
        let toViewFrame = getGlobalToViewFrame()
        
        let screenLength = UIDevice.current.orientation == .landscapeLeft ? screenHeight : screenWidth
        
        switch type {
        
        case .swipeLeft:
            
            fingerAnimation.keyPath = "position.x"
            
            fingerAnimation.fromValue = pointerLayer.position.x
            fingerAnimation.toValue = (toViewFrame.midX - (pointerLayer.frame.size.width/2)) - (1/4*screenLength)
                        
        case .swipeRight:
            
            fingerAnimation.keyPath = "position.x"
            
            fingerAnimation.fromValue = pointerLayer.position.x
            fingerAnimation.toValue = toViewFrame.midX + (1/4*screenLength)
                    
        case .swipeUp:
            
            fingerAnimation.keyPath = "position.y"
            
            fingerAnimation.fromValue = pointerLayer.position.y
            fingerAnimation.toValue = (toViewFrame.midY - (pointerLayer.frame.size.height/2)) - (1/4*screenLength)
                        
        case .swipeDown:
            
            fingerAnimation.keyPath = "position.y"
        
            fingerAnimation.fromValue = pointerLayer.position.y
            fingerAnimation.toValue = toViewFrame.midY + (1/4*screenLength)
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
    
    override func performExitAnimation(animation: String, byUser: Bool, autoDismissed: Bool, byContext: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        super.performExitAnimation(animation: animation, byUser: byUser, autoDismissed: autoDismissed, byContext: byContext, panelOpen: panelOpen, action: action)
        removePointer()
    }
}
