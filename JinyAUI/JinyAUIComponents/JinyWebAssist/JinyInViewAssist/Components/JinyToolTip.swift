//
//  JinyToolTip.swift
//  AUIComponents
//
//  Created by mac on 15/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit
import WebKit

enum JinyTooltipArrowDirection {
    case top
    case bottom
//    case Left
//    case Right
}

public class JinyToolTip: JinyInViewAssist {
    
    weak var toView: UIView?
    
    weak var inView: UIView?
    
    var toolTipView = UIView(frame: .zero)
    
    var highlightView: UIView?
    
    var maskLayer = CAShapeLayer()
    
    var preferredArrrowDirection:JinyTooltipArrowDirection = .top
    var cornerRadius: CGFloat = 6.0
    let minimalSpacing: CGFloat = 12.0
    let halfWidthForArrow: CGFloat = 10
    
    private var toViewOriginalInteraction: Bool?
    
    var highlightSpacing = 10.0
    
    var highlightCornerRadius = 5.0
    
    public init(withDict assistDict: Dictionary<String,Any>, tooltipToView: UIView, insideView: UIView?) {
        super.init(frame: CGRect.zero)
                
        self.assistInfo = AssistInfo(withDict: assistDict)
        
        toView = tooltipToView
        inView = insideView
        
        toViewOriginalInteraction = toView?.isUserInteractionEnabled
        
        maskLayer = CAShapeLayer()
        
        maskLayer.bounds = self.webView.bounds
        
        cornerRadius = CGFloat((self.assistInfo?.layoutInfo?.style.cornerRadius) ?? 6.0)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func presentPointer() {
                        
        guard toView != nil else { fatalError("no element to point to") }
            
        if inView == nil {
        
            guard let _ = toView?.superview else { fatalError("View not in valid hierarchy or is window view") }
        
            inView = UIApplication.shared.keyWindow
        }
     
        inView?.addSubview(self)
        
        configureOverlayView()
                
        self.addSubview(toolTipView)
        
        setupView()

        if assistInfo?.highlightAnchor ?? false {
            
           highlightAnchor()
            
        } else {
            
           self.backgroundColor = .clear
        }
        
        show()
    }
        
    func setupView() {

        toolTipView.layer.cornerRadius = cornerRadius
        
        toolTipView.layer.masksToBounds = true
        
        self.webView.scrollView.isScrollEnabled = false
          
        toolTipView.addSubview(webView)
    }
        
    func placePointer() {
    
       let dir = getArrowDirection()
            
       guard let direction = dir else {
                
         return
       }
            
       setOriginForDirection(dir: direction)
        
       drawMaskLayerFor(direction)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            
        if keyPath == "position" {
                
           placePointer()
        }
    }
        
    func getArrowDirection() -> JinyTooltipArrowDirection? {
    
        let globalToViewFrame = toView!.superview!.convert(toView!.frame, to: inView)

        let toViewTop = globalToViewFrame.origin.y
        
        let toViewBottom = toViewTop + globalToViewFrame.size.height
        
//        let toViewLeft = globalToViewFrame.origin.x
        
//        let toViewRight = toViewLeft + globalToViewFrame.size.width
//
        let inViewFrame = (inView != nil ? inView!.frame : UIScreen.main.bounds)
        
        if (toViewBottom + toolTipView.frame.size.height) <= inViewFrame.size.height {
            
            return .top
        
        } else {
            
            return .bottom
        }
                        
//        if toViewBottom + toolTipView.frame.size.height < inViewFrame.size.height && toViewLeft < (inViewFrame.size.width - toolTipView.frame.size.width/2) && toViewRight > toolTipView.frame.size.width/2  {
//
//            if (toViewRight > cornerRadius + minimalSpacing) && (toViewLeft+cornerRadius+minimalSpacing < inViewFrame.size.width) {
//
//               return .top
//            }
//        }
        
//        if (toViewTop > toolTipView.frame.size.height) && toViewLeft < (inViewFrame.size.width - toolTipView.frame.size.width/2) && toViewRight > toolTipView.frame.size.width/2 {
//
//            if (toViewRight > cornerRadius + minimalSpacing) && (toViewLeft+cornerRadius+minimalSpacing < inViewFrame.size.width) {
//
//                return .bottom
//            }
//        }
            
//        if toViewRight > cornerRadius + minimalSpacing && toViewRight > toolTipView.frame.size.width/2 {
//
//            return .Right
//
//        } else if toViewLeft+cornerRadius+minimalSpacing < inViewFrame.size.width {
//
//            return .Left
//        }
    }
        
    func setOriginForDirection(dir: JinyTooltipArrowDirection) {
            
        let globalToViewFrame = toView!.superview!.convert(toView!.frame, to:inView)
        
        let inViewFrame = (inView != nil ? inView!.frame : UIScreen.main.bounds)
        
        var x:CGFloat = 0, y:CGFloat = 0
        
        switch dir {
        
        case .top:
            
            x = globalToViewFrame.midX - (toolTipView.frame.size.width/2)
            
            if (x + toolTipView.frame.size.width) > inViewFrame.size.width {
                
                x = x - ((x + toolTipView.frame.size.width) - inViewFrame.size.width)
            }
            
            if x < 0 {
                
               x = 0
            }
            
//            if globalToViewFrame.midX > (toolTipView.frame.size.width/2) && globalToViewFrame.midX + (toolTipView.frame.size.width/2) < inView!.frame.width {
//
//                    x = globalToViewFrame.midX - (toolTipView.frame.size.width/2)
//
//            } else if globalToViewFrame.midX < (toolTipView.frame.size.width/2) {
//
//                    x = 0
//
//            } else {
//
//                x = (inView!.frame.width - toolTipView.frame.size.width)
//            }
            
            y = globalToViewFrame.origin.y + globalToViewFrame.size.height
            
            if assistInfo?.highlightAnchor ?? false {
                
                y = y + CGFloat(highlightSpacing)
            }
            
        case .bottom:
            
            x = globalToViewFrame.midX - (toolTipView.frame.size.width/2)
            
            if (x + toolTipView.frame.size.width) > inViewFrame.size.width {
                
                x = x - ((x + toolTipView.frame.size.width) - inViewFrame.size.width)
            }
            
            if x < 0 {
                
               x = 0
            }
        
//            if globalToViewFrame.midX > (toolTipView.frame.size.width/2) && (globalToViewFrame.midX + (toolTipView.frame.size.width/2) < inView!.frame.width) {
//                
//                    x = globalToViewFrame.midX - (toolTipView.frame.size.width/2)
//            
//            } else if globalToViewFrame.midX < (toolTipView.frame.size.width/2) {
//            
//                x = 0
//                
//            } else {
//            
//                x = (inView!.frame.width - toolTipView.frame.size.width)
//            }
            
            y = (globalToViewFrame.origin.y - toolTipView.frame.size.height)
            
            if assistInfo?.highlightAnchor ?? false {
                
                y = y - CGFloat(highlightSpacing)
            }
            
//        case .Right:
//
//            x = globalToViewFrame.origin.x - toolTipView.frame.size.width
//
//            if globalToViewFrame.midY > (toolTipView.frame.size.height/2) && (globalToViewFrame.midY + (toolTipView.frame.size.height/2) < inView!.frame.size.height) {
//
//                y = globalToViewFrame.midY - (toolTipView.frame.size.height/2)
//
//            } else if globalToViewFrame.midY > toolTipView.frame.size.height/2 {
//
//                y = 0
//
//            } else {
//
//                y = inView!.frame.height - toolTipView.frame.size.height
//            }
//
//            break
//
//        case .Left:
//
//            x = globalToViewFrame.origin.x + globalToViewFrame.size.width
//
//            if globalToViewFrame.midY > (toolTipView.frame.size.height/2) && (globalToViewFrame.midY + (toolTipView.frame.size.height/2) < inView!.frame.size.height) {
//
//                y = globalToViewFrame.midY - (toolTipView.frame.size.height/2)
//
//            } else if globalToViewFrame.midY > toolTipView.frame.size.height/2 {
//
//                y = globalToViewFrame.midY - toolTipView.frame.size.height
//
//            } else {
//
//                y = inView!.frame.height - toolTipView.frame.size.height
//            }
//
//            break
        }
        
        toolTipView.frame.origin = CGPoint(x: x, y: y)
    }
        
    func drawMaskLayerFor(_ direction:JinyTooltipArrowDirection) {
    
        var path:UIBezierPath?

        switch direction {
        
        case .top:
        
            path = drawPathForTopTooltip()
        
        case .bottom:
            
            path = drawPathForBottomTooltip()
            
//        case .Left:
//
//            path = drawPathForLeftTooltip()
//
//        case .Right:
//
//            path = drawPathForRightTooltip()
        }
            
        let contentPath = UIBezierPath(rect: self.webView.bounds)
        
        contentPath.append(path!)
        
        maskLayer.fillRule = .evenOdd
        
        maskLayer.path = contentPath.cgPath
        
        self.webView.layer.mask = maskLayer
       
        // To set stroke color and width
        
        let borderLayer = CAShapeLayer()
        
        borderLayer.path = maskLayer.path
        
        borderLayer.fillColor = UIColor.clear.cgColor
        
        borderLayer.frame = webView.bounds
        
        if let colorString = self.assistInfo?.layoutInfo?.style.strokeColor {
        
            borderLayer.strokeColor = UIColor.colorFromString(string: colorString).cgColor
        }
        
        if let strokeWidth = self.assistInfo?.layoutInfo?.style.strokeWidth {
            
            borderLayer.lineWidth = CGFloat(strokeWidth)
        
        } else {
            
            borderLayer.lineWidth = 0.0
        }
            
        self.webView.layer.addSublayer(borderLayer)
    }
        
    func drawPathForTopTooltip() -> UIBezierPath {
    
        let path = UIBezierPath()

        path.move(to: CGPoint(x: 0, y: cornerRadius+minimalSpacing))
        
        path.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius+minimalSpacing), radius: cornerRadius, startAngle: .pi, endAngle: 3 * .pi/2, clockwise: true)
            
        let globalToView = toView?.superview?.convert(toView!.frame, to: inView)
        
        let arrowMidX: CGFloat = globalToView!.midX - toolTipView.frame.origin.x
                    
        path.addLine(to: CGPoint(x: arrowMidX-halfWidthForArrow, y: minimalSpacing))
        
        path.addLine(to: CGPoint(x: arrowMidX, y: 1))
        
        path.addLine(to: CGPoint(x: arrowMidX+halfWidthForArrow, y: minimalSpacing))
        
        path.addLine(to: CGPoint(x: self.webView.frame.size.width-cornerRadius, y: minimalSpacing))
        
        path.addArc(withCenter: CGPoint(x: self.webView.frame.size.width-cornerRadius, y: cornerRadius+minimalSpacing), radius: cornerRadius, startAngle: 3 * .pi/2, endAngle: 0, clockwise: true)
            
        path.addLine(to: CGPoint(x: self.webView.frame.size.width, y: 0))
        
        path.addLine(to: CGPoint(x: 0, y: 0))
        
        path.close()
        
        return path
    }
        
    func drawPathForBottomTooltip() -> UIBezierPath {
    
        let contentSize = self.webView.frame.size

        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: 0, y: contentSize.height))
        
        path.addLine(to: CGPoint(x: contentSize.width, y: contentSize.height))
        
        path.addLine(to: CGPoint(x: contentSize.width, y: contentSize.height-minimalSpacing-cornerRadius))
        
        path.addArc(withCenter: CGPoint(x: contentSize.width-cornerRadius, y: contentSize.height-minimalSpacing-cornerRadius), radius: cornerRadius, startAngle: 0, endAngle: .pi/2, clockwise: true)
            
        let globalToView = toView?.superview?.convert(toView!.frame, to: inView)
        
        let arrowMidX: CGFloat = globalToView!.midX - toolTipView.frame.origin.x
                
        path.addLine(to: CGPoint(x: arrowMidX+halfWidthForArrow, y: contentSize.height-minimalSpacing))
        
        path.addLine(to: CGPoint(x: arrowMidX, y: contentSize.height-1))
        
        path.addLine(to: CGPoint(x: arrowMidX-halfWidthForArrow, y: contentSize.height-minimalSpacing))
        
        path.addLine(to: CGPoint(x: cornerRadius, y: contentSize.height-minimalSpacing))
        
        path.addArc(withCenter: CGPoint(x: cornerRadius, y: contentSize.height-minimalSpacing-cornerRadius), radius: cornerRadius, startAngle: .pi/2, endAngle: .pi, clockwise: true)
        
        path.close()
            
        return path
    }
        
//    func drawPathForLeftTooltip() -> UIBezierPath {
//
//        let contentSize = self.webView.frame.size
//
//        let path = UIBezierPath()
//
//        path.move(to: CGPoint(x: 0, y: 0))
//
//        path.addLine(to: CGPoint(x: 0, y: contentSize.height))
//
//        path.addLine(to: CGPoint(x: minimalSpacing + cornerRadius, y: contentSize.height))
//
//        path.addArc(withCenter: CGPoint(x:minimalSpacing + cornerRadius, y: contentSize.height-cornerRadius), radius: cornerRadius, startAngle: .pi/2, endAngle: .pi, clockwise: true)
//
//        let globalToView = toView?.superview?.convert(toView!.frame, to: inView)
//
//        var arrowMidY:CGFloat = toolTipView.frame.height / 2
//
//        if globalToView!.midY > toolTipView.frame.size.height/2 {
//
//            arrowMidY = toolTipView.frame.size.height - 20
//        }
//
//        if globalToView!.midY > (toolTipView.frame.size.height/2) && (globalToView!.midY + (toolTipView.frame.size.height/2) < inView!.frame.size.height) {
//
//            arrowMidY = toolTipView.frame.height / 2
//
//        } else if globalToView!.midY > toolTipView.frame.size.height/2 {
//
//            arrowMidY = toolTipView.frame.size.height - 20
//
//        } else {
//
//            arrowMidY = toolTipView.frame.height / 2
//        }
//
//        path.addLine(to: CGPoint(x: minimalSpacing, y: arrowMidY+halfWidthForArrow))
//
//        path.addLine(to: CGPoint(x: 1, y: arrowMidY))
//
//        path.addLine(to: CGPoint(x: minimalSpacing, y: arrowMidY - halfWidthForArrow))
//
//        path.addLine(to: CGPoint(x: minimalSpacing, y: minimalSpacing))
//
//        path.addArc(withCenter: CGPoint(x: minimalSpacing+cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: .pi, endAngle:  3 * .pi/2, clockwise: true)
//
//        path.close()
//
//        return path
//    }
//
//    func drawPathForRightTooltip() -> UIBezierPath {
//
//        let contentSize = self.webView.frame.size
//
//        let path = UIBezierPath()
//
//        path.move(to: CGPoint(x: contentSize.width, y: contentSize.height))
//
//        path.addLine(to: CGPoint(x: contentSize.width, y: 0))
//
//        path.addLine(to: CGPoint(x: contentSize.width - minimalSpacing - cornerRadius, y: 0))
//
//        path.addArc(withCenter: CGPoint(x:contentSize.width - minimalSpacing - cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: 3 * .pi/2, endAngle: 0, clockwise: true)
//
//        let globalToView = toView?.superview?.convert(toView!.frame, to: inView)
//
//        var arrowMidY:CGFloat = toolTipView.frame.height / 2
//
//        if globalToView!.midX > self.webView.frame.origin.y + self.webView.frame.size.width {
//
//            arrowMidY = toolTipView.frame.height / 2
//        }
//
//        path.addLine(to: CGPoint(x: contentSize.width - minimalSpacing, y: arrowMidY-halfWidthForArrow))
//
//        path.addLine(to: CGPoint(x: contentSize.width - 1, y: arrowMidY))
//
//        path.addLine(to: CGPoint(x: contentSize.width - minimalSpacing, y: arrowMidY + halfWidthForArrow))
//
//        path.addLine(to: CGPoint(x: contentSize.width - minimalSpacing, y: contentSize.height - cornerRadius))
//
//        path.addArc(withCenter: CGPoint(x: contentSize.width - minimalSpacing - cornerRadius, y: contentSize.height - cornerRadius), radius: cornerRadius, startAngle: 0, endAngle: .pi/2, clockwise: true)
//
//        path.close()
//
//        return path
//    }
        
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
    
        return (view.bounds.height > 120 && view.bounds.width > 260)
    }
    
    private func highlightAnchor() {
        
        let globalToView = toView?.superview?.convert(toView!.frame, to: nil)

        let origin = globalToView!.origin
        
        let size = globalToView!.size
        
        let path = UIBezierPath(rect: inView!.bounds)
                
        let transparentPath = UIBezierPath(roundedRect: CGRect(x: Double(origin.x) - highlightSpacing, y: Double(origin.y) - highlightSpacing, width: Double(size.width) + (highlightSpacing*2), height: Double(size.height) + (highlightSpacing*2)), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: highlightCornerRadius, height: highlightCornerRadius))
        
        path.append(transparentPath)
        path.usesEvenOddFillRule = true

        let fillLayer = CAShapeLayer()
        fillLayer.path = path.cgPath
        fillLayer.fillRule = .evenOdd
        fillLayer.opacity = 1.0
        self.layer.mask = fillLayer
        
        if assistInfo?.anchorClickable ?? false {
            
            toView?.isUserInteractionEnabled = true
        
        } else {
            
            toView?.isUserInteractionEnabled = false
        }
    }
    
    private func setToolTipDimensions(width: Float, height: Float) {
        
       let proportionalWidth = (((self.assistInfo?.layoutInfo?.style.maxWidth ?? 80.0) * Double(self.frame.width)) / 100)
        
        if width > 0 && width > Float(proportionalWidth) {
            
           self.assistInfo?.layoutInfo?.style.maxWidth = proportionalWidth
        
        } else {
            
           self.assistInfo?.layoutInfo?.style.maxWidth = Double(width)
        }
        
        self.webView.frame.size = CGSize(width: CGFloat(self.assistInfo?.layoutInfo?.style.maxWidth ?? Double(width)), height: CGFloat(height))
        
        toolTipView.frame.size = CGSize(width: CGFloat(self.assistInfo?.layoutInfo?.style.maxWidth ?? Double(width)), height: CGFloat(height))
    }
    
    override func didReceive(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let body = message.body as? String else { return }
        guard let data = body.data(using: .utf8) else { return }
        guard let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<String,Any> else {return}
        guard let metaData = dict["pageMetaData"] as? Dictionary<String,Any> else {return}
        guard let rect = metaData["rect"] as? Dictionary<String,Float> else {return}
        guard let width = rect["width"] else { return }
        guard let height = rect["height"] else { return }
        setToolTipDimensions(width: width, height: height)
        placePointer()
        //toView?.layer.addObserver(toolTipView, forKeyPath: "position", options: .new, context: nil)
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        if let viewToCheck = toView {
            
            guard let frameForKw = viewToCheck.superview?.convert(viewToCheck.frame, to: nil) else {
                
                return self
            }
            
            if frameForKw.contains(point) { return nil } else { return self }
        }
        
        return self
    }
    
    func simulateTap(atPoint:CGPoint, onWebview:UIView, withEvent:UIEvent) {
                
         onWebview.hitTest(atPoint, with: withEvent)
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if assistInfo?.layoutInfo?.outsideDismiss ?? false {
            
            performExitAnimation(animation: assistInfo?.layoutInfo?.exitAnimation ?? "")
            
            guard let userInteraction = toViewOriginalInteraction else {
                
               return
            }
            
            toView?.isUserInteractionEnabled = userInteraction
        }
    }
}
