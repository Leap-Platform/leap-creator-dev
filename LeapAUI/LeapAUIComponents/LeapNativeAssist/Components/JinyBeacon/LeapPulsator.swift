//
//  LeapPulsator.swift
//  LeapAUI
//
//  Created by mac on 22/09/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import UIKit

enum LeapPulsePosition:String {
    case TopLeft = "top_left"
    case TopCenter = "top_center"
    case TopRight = "top_right"
    case Left = "left_center"
    case Center = "center"
    case Right = "right_center"
    case BottomLeft = "bottom_left"
    case BottomCenter = "bottom_center"
    case BottomRight = "bottom_right"
}

protocol LeapPulsatorDelegate:NSObjectProtocol {
    
    func didStartAnimation()
    
    func didStopAnimation()
    
}

class LeapPulsator: CALayer {

    let minRadius: CGFloat = 1.0
    let maxRadius: CGFloat = 8.0
    let animationDuration: TimeInterval = 2.0
    private var pos: LeapPulsePosition = .Center
    weak var toView: UIView?
    var toRect:CGRect?
    weak var inView: UIView?
    weak var pulsatorDelegate:LeapPulsatorDelegate?

    
    let bgColor:UIColor
    
    init(with bgColor: UIColor) {
        self.bgColor = bgColor
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setPosition(_ position:String) {
        pos = LeapPulsePosition(rawValue: position) ?? .Center
    }
    
    func placeBeacon() {
        let kw = UIApplication.shared.windows.first { $0.isKeyWindow }
        guard let keyWindow = kw else { fatalError() }
        keyWindow.layer.addSublayer(self)
        let toViewFrameForKw = toView?.superview?.convert(toView!.frame, to: nil)
        guard let frame = toViewFrameForKw else { fatalError() }
        bounds = CGRect(x: 0, y: 0, width: minRadius*2, height: minRadius*2)
        backgroundColor = bgColor.cgColor
        cornerRadius = minRadius
        var x: CGFloat = 0, y: CGFloat = 0
        switch pos {
        case .TopLeft:
            x = frame.minX
            y = frame.minY
        case .TopCenter:
            x = frame.midX
            y = frame.minY
        case .TopRight:
            x = frame.maxX
            y = frame.minY
        case .Left:
            x = frame.minX
            y = frame.midY
        case .Center:
            x = frame.midX
            y = frame.midY
        case .Right:
            x = frame.maxX
            y = frame.midY
        case .BottomLeft:
            x = frame.minX
            y = frame.maxY
        case .BottomCenter:
            x = frame.midX
            y = frame.maxY
        case .BottomRight:
            x = frame.maxX
            y = frame.maxY
        }
        
        self.position = CGPoint(x: x, y: y)
        startAnimation()
    }
    
    func placeBeacon(rect:CGRect, inWebView:UIView) {
        let kw = UIApplication.shared.windows.first { $0.isKeyWindow }
        guard let keyWindow = kw else { fatalError() }
        keyWindow.layer.addSublayer(self)
        let frame = inWebView.convert(rect, to: nil)
        bounds = CGRect(x: 0, y: 0, width: minRadius*2, height: minRadius*2)
        backgroundColor = bgColor.cgColor
        cornerRadius = minRadius
        var x: CGFloat = 0, y: CGFloat = 0
        switch pos {
        case .TopLeft:
            x = frame.minX
            y = frame.minY
        case .TopCenter:
            x = frame.midX
            y = frame.minY
        case .TopRight:
            x = frame.maxX
            y = frame.minY
        case .Left:
            x = frame.minX
            y = frame.midY
        case .Center:
            x = frame.midX
            y = frame.midY
        case .Right:
            x = frame.maxX
            y = frame.midY
        case .BottomLeft:
            x = frame.minX
            y = frame.maxY
        case .BottomCenter:
            x = frame.midX
            y = frame.maxY
        case .BottomRight:
            x = frame.maxX
            y = frame.maxY
        }
        
        self.position = CGPoint(x: x, y: y)
        startAnimation()
        
    }
    
    func startAnimation() {
        let opacityAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = [1.0, 0.7, 0.0]
        opacityAnimation.keyTimes = [0.0, 0.8, 1.0]
        opacityAnimation.duration = animationDuration
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
       
        let scaleAnimation: CABasicAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = NSValue(cgAffineTransform: .identity)
        scaleAnimation.toValue = NSValue(caTransform3D: CATransform3DMakeScale(maxRadius/minRadius, maxRadius/minRadius, 1))
        scaleAnimation.duration = animationDuration
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        
        let animationGroup: CAAnimationGroup = CAAnimationGroup()
        animationGroup.animations = [scaleAnimation, opacityAnimation]
        animationGroup.repeatCount = .infinity
        animationGroup.duration = animationDuration
        
        masksToBounds = false
        add(animationGroup, forKey: "pulse")
        pulsatorDelegate?.didStartAnimation()
    }
    
    func stopAnimation() {
        self.removeFromSuperlayer()
        pulsatorDelegate?.didStopAnimation()
    }
    
}
