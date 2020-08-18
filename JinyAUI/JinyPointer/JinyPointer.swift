//
//  JinyPointer.swift
//  JinySDK
//
//  Created by Aravind GS on 19/03/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

protocol JinyPointerDelegate {
    func pointerPresented()
    func nextClicked()
    func pointerRemoved()
}

class JinyPointer: CAShapeLayer {
    
    weak var toView:UIView?
    weak var inView:UIView?
    var pointerDelegate:JinyPointerDelegate?
    
    override init() {
        super.init()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addNotifiers() {
//        let nc = NotificationCenter.default
//        nc.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
//        nc.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
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
    
    func startAnimation() {
        
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
        removeAllAnimations()
    }
    
    func removePointer() {
        self.removeFromSuperlayer()
    }
    
}

class JinyFingerRipplePointer:JinyPointer {
    
    var ringLayer:CAShapeLayer
    var fingerLayer:CAShapeLayer
    let pulse = CAAnimationGroup()
    let clickAnimation = CAAnimationGroup()
    
    override init() {
        fingerLayer = CAShapeLayer()
        ringLayer = CAShapeLayer()
        super.init()
        let pointerPath = getInnerPath()
        
        fingerLayer.path = pointerPath.cgPath
        fingerLayer.fillColor = UIColor(red: 0.941, green: 0.663, blue: 0.122, alpha: 1.000).cgColor
        fingerLayer.fillRule = .nonZero
        fingerLayer.strokeColor = UIColor.white.cgColor
        fingerLayer.lineWidth = 2.0
        
        ringLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 1, height: 1)).cgPath
        
        ringLayer.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6).cgColor
        
        self.addSublayer(ringLayer)
        ringLayer.frame = CGRect(x: 21, y: 20, width: 1, height: 1)
        
        self.addSublayer(fingerLayer)
        fingerLayer.frame = CGRect(x: 9, y: 10, width: 31, height: 39)
        
    }
    
    override init(layer: Any) {
        fingerLayer = CAShapeLayer()
        ringLayer = CAShapeLayer()
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    override func presentPointer() {
        inView?.layer.addSublayer(self)
        setPosition()
        toView?.layer.addObserver(self, forKeyPath: "position", options: [.new,.old], context: nil)

        startAnimation()
        addNotifiers()
        self.pointerDelegate?.pointerPresented()
    }
    
    override func presentPointer(toRect: CGRect, inView:UIView?) {
        self.inView = inView
        let toViewFrame = toRect
        let y = toViewFrame.midY - 15
        let x = toViewFrame.midX - 21
        self.frame = CGRect(x: x, y: y, width: 42, height: 54)
        inView?.layer.addSublayer(self)
        self.zPosition = 10
        startAnimation()
        self.pointerDelegate?.pointerPresented()
    }
    
    override func updateRect(newRect: CGRect, inView: UIView?) {
        self.inView = inView
        let toViewFrame = newRect
        let y = toViewFrame.midY - 15
        let x = toViewFrame.midX - 21
        self.frame = CGRect(x: x, y: y, width: 42, height: 54)
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
        self.frame = CGRect(x: x, y: y, width: 42, height: 54)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "position" {
            setPosition()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    override func startAnimation() {
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
        self.masksToBounds = false
        
        fingerLayer.add(clickAnimation, forKey: "click")
        ringLayer.add(pulse, forKey: "pulse")
        
    }
    
    override func removeAnimation() {
        ringLayer.removeAllAnimations()
    }
    
    
    override func removePointer() {
        
        toView?.layer.removeObserver(self, forKeyPath: "position")
        super.removePointer()
    }
}

class JinyHighlightPointer:JinyPointer {
    
    
    override init() {
        super.init()
        inView = UIApplication.shared.keyWindow
    }
    
    override init(layer: Any) {
        super.init()
        inView = UIApplication.shared.keyWindow
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getBackdrop() -> UIBezierPath{
        let backdrop = UIBezierPath(rect: CGRect(x: 0, y: 0, width: inView!.frame.size.width, height: inView!.frame.size.height))
        return backdrop
    }
    
    override func presentPointer() {
        
        createPointer()
        toView?.layer.addObserver(self, forKeyPath: "position", options: .new, context: nil)
        self.pointerDelegate?.pointerPresented()
    }
    
    override func presentPointer(view: UIView) {
        toView = view
        if toView?.window != UIApplication.shared.keyWindow {
            inView = toView!.window
        } else {
            inView = UIApplication.getCurrentVC()?.view
        }
        presentPointer()
    }
    
    override func presentPointer(toRect: CGRect, inView:UIView?) {
        
    }
    
    func createPointer() {
        let backdrop = getBackdrop()
        let selectedFrame = getToViewPositionForInView()
        let selected = UIBezierPath(rect: CGRect(x: selectedFrame.origin.x - 5, y: selectedFrame.origin.y - 5, width: selectedFrame.size.width+10, height: selectedFrame.size.height+10))
        backdrop.append(selected)
        backdrop.usesEvenOddFillRule = true
        
        self.path = backdrop.cgPath
        self.fillRule = .evenOdd
        self.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor
        inView?.layer.addSublayer(self)
        toView?.becomeFirstResponder()
    }
    
    func updateFrame() {
//        self.removeFromSuperlayer()
//        createPointer()
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "position" {
            updateFrame()
        }
    }
}

class JinyHighlightManualSequencePointer:JinyHighlightPointer {
    
    var nextButton:UIButton
    var fingerRipple:JinyFingerRipplePointer
    
    let clickAnimation = CAAnimationGroup()
    
    override init() {
        nextButton = UIButton()
        fingerRipple = JinyFingerRipplePointer()
        super.init()
    }
    
    override init(layer: Any) {
        self.nextButton = UIButton()
        fingerRipple = JinyFingerRipplePointer()
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func createPointer() {
        super.createPointer()
        
        nextButton.setTitle("→", for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.backgroundColor = UIColor(red: 0.941, green: 0.663, blue: 0.122, alpha: 1.000)
        nextButton.layer.cornerRadius = 4.0
        nextButton.layer.masksToBounds = true
        nextButton.addTarget(self, action: #selector(nextClicked), for: .touchUpInside)
        inView?.addSubview(nextButton)
        let toViewFrame = getToViewPositionForInView()
        nextButton.frame = CGRect(x: inView!.frame.size.width - 160, y: toViewFrame.origin.y-40, width: 100, height: 30)
    }
    
    
    
    override func presentPointer() {
        createPointer()
        toView?.layer.addObserver(self, forKeyPath: "position", options: .new, context: nil)
        pointerDelegate?.pointerPresented()
        fingerRipple.presentPointer(view: nextButton)
    }
    
    override func presentPointer(view: UIView) {
        toView = view
        if toView?.window != UIApplication.shared.keyWindow {
            inView = toView!.window
        } else {
            inView = UIApplication.getCurrentVC()?.view
        }
        presentPointer()
    }
    
    override func presentPointer(toRect: CGRect, inView:UIView?) {
        
    }
    
    override func updateFrame() {
        nextButton.removeFromSuperview()
        createPointer()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "position" {
            updateFrame()
        }
    }
    
    
    @objc func nextClicked() {
        pointerDelegate?.nextClicked()
    }
    override func removePointer() {
        fingerRipple.removePointer()
        nextButton.removeFromSuperview()
        toView?.layer.removeObserver(self, forKeyPath: "position")
        super.removePointer()
    }
}
