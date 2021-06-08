//
//  LeapToolTip.swift
//  LeapAUI
//
//  Created by mac on 15/09/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// LeapTooltip's Arrow Direction
enum LeapTooltipArrowDirection {
    case top
    case bottom
}

/// LeapToolTip - A Web InViewAssist AUI Component class to show a tip on a view.
class LeapToolTip: LeapTipView {
      
    /// maskLayer for the tooltip.
    private var maskLayer = CAShapeLayer()
    
    /// cornerRadius of the toolTip.
    private var cornerRadius: CGFloat = 6.0
    
    /// minimal spacing for the tooltip.
    private let minimalSpacing: CGFloat = 12.0
    
    /// half width for the arrow.
    private let halfWidthForArrow: CGFloat = 10
    
    /// presents pointer after setup, configure and show() webview content method is called and when the delegate is called for the webView.
    func presentPointer() {
        
        setupView()
        
        configureTooltipView()
        
        setupAutoFocus()
        
        show()
    }
    
    func presentPointer(toRect: CGRect, inView: UIView?) {
        
        webRect = toRect
                
        presentPointer()
    }
    
    func updatePointer() {
        
        guard let previousFrame = previousFrame else { return }
                
        if previousFrame.origin == getGlobalToViewFrame().origin { return }
                
        if assistInfo?.highlightAnchor ?? true {
            
           highlightAnchor()
        }
        
        placePointer()
    }
    
    func updatePointer(toRect: CGRect, inView: UIView?) {
        
        webRect = toRect
        
        guard let previousFrame = previousFrame else { return }
        
        if previousFrame.origin == getGlobalToViewFrame().origin { return }
        
        if assistInfo?.highlightAnchor ?? true {
            
           highlightAnchor()
        }
        
        placePointer()
    }
        
    /// setup toView, inView, toolTipView and webView
    func setupView() {
        
        inView = toView?.window
        
        inView?.addSubview(self)
           
        configureOverlayView()
                   
        self.addSubview(toolTipView)
    
        toolTipView.addSubview(webView)
    }
    
    /// configures webView, toolTipView and highlights anchor method called.
    func configureTooltipView() {
        
       // comment this if you want value from config
       assistInfo?.layoutInfo?.style.elevation = 8 // Hardcoded value
        
       // comment this if you want value from config
       assistInfo?.layoutInfo?.style.cornerRadius = 8 // Hardcoded value
        
       self.toolTipView.elevate(with: CGFloat(assistInfo?.layoutInfo?.style.elevation ?? 0))
                
       maskLayer.bounds = self.webView.bounds
        
       // set webView to max width of the screen
       let maxWidth = CGFloat(assistInfo?.layoutInfo?.style.maxWidth ?? 0.8)
        
       webView.frame.size.width =  maxWidth * UIScreen.main.bounds.width
    
       cornerRadius = CGFloat((self.assistInfo?.layoutInfo?.style.cornerRadius) ?? 8.0)

       webView.layer.cornerRadius = cornerRadius
    
       webView.layer.masksToBounds = true
        
       if assistInfo?.highlightAnchor ?? false {
           
          highlightAnchor()
       }
    }
      
    /// sets the pointer direction, origin and path for the toolTipView layer.
    func placePointer() {
        
       previousFrame = getGlobalToViewFrame()
    
       let arrowDirection = getArrowDirection()
            
       guard let direction = arrowDirection, inView != nil else {
                
         return
       }
        
       configureLeapIconViewForTooltip(direction: direction)
            
       setOriginForDirection(direction: direction)
        
       drawMaskLayerFor(direction)
    }
    
    func configureLeapIconViewForTooltip(direction: LeapTooltipArrowDirection) {
        
        self.removeConstraints(self.constraints)
        
        toolTipView.removeConstraints(toolTipView.constraints)
        
        if direction == .top {
            
            configureLeapIconView(superView: self, toItemView: toolTipView, alignmentType: .bottom, cornerDistance: halfWidthForArrow)
        
        } else {
            
            configureLeapIconView(superView: self, toItemView: toolTipView, alignmentType: .top, cornerDistance: halfWidthForArrow)
        }
    }
    
    /// Observes the toolTipView's Origin, gets called when there is a change in position.
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            
        if keyPath == "position" {
                
           placePointer()
        }
    }
        
    /// gets the arrow direction - top or bottom.
    func getArrowDirection() -> LeapTooltipArrowDirection? {
        
        guard toView?.superview != nil || webRect != nil else {
            
            return .none
        }
    
        let globalToViewFrame = getGlobalToViewFrame()
        
        let inViewFrame = (inView != nil ? inView!.frame : UIScreen.main.bounds)

        var toViewTopSpacing = globalToViewFrame.origin.y
        
        if assistInfo?.highlightAnchor ?? false {
            
            toViewTopSpacing = toViewTopSpacing - CGFloat(manipulatedHighlightSpacing)
        }
                
        var iconSpacing: CGFloat = 0
        
        if iconInfo?.isEnabled ?? false {
            
            iconSpacing = self.leapIconView.iconSize + self.leapIconView.iconGap
        }
        
        let calculatedY = (toViewTopSpacing - toolTipView.frame.size.height) - iconSpacing
        
        if calculatedY >= inViewFrame.origin.y {
            
            return .bottom
        
        } else {
            
            return .top
        }
    }
        
    /// sets the origin for arrow direction
    /// - Parameters:
    ///   - direction: ToolTip arrow direction.
    func setOriginForDirection(direction: LeapTooltipArrowDirection) {
            
        let globalToViewFrame = getGlobalToViewFrame()
        
        let inViewFrame = (inView != nil ? inView!.frame : UIScreen.main.bounds)
        
        var x:CGFloat = 0, y:CGFloat = 0
        
        switch direction {
        
        case .top:
            
            x = globalToViewFrame.midX - (toolTipView.frame.size.width/2)
            
            if (x + toolTipView.frame.size.width) > inViewFrame.size.width {
                
                x = x - ((x + toolTipView.frame.size.width) - inViewFrame.size.width)
            }
            
            if x < 0 {
                
               x = 0
            }
            
            y = globalToViewFrame.origin.y + globalToViewFrame.size.height
            
            if assistInfo?.highlightAnchor ?? false {
                
                y = y + CGFloat(manipulatedHighlightSpacing)
            }
            
        case .bottom:
            
            x = globalToViewFrame.midX - (toolTipView.frame.size.width/2)
            
            if (x + toolTipView.frame.size.width) > inViewFrame.size.width {
                
                x = x - ((x + toolTipView.frame.size.width) - inViewFrame.size.width)
            }
            
            if x < 0 {
                
               x = 0
            }
            
            y = (globalToViewFrame.origin.y - toolTipView.frame.size.height)
            
            if assistInfo?.highlightAnchor ?? false {
                
                y = y - CGFloat(manipulatedHighlightSpacing)
            }
        }
        
        toolTipView.frame.origin = CGPoint(x: x, y: y)
    }
        
    /// draws mask layer based on direction.
    /// - Parameters:
    ///   - direction: ToolTip arrow direction.
    func drawMaskLayerFor(_ direction:LeapTooltipArrowDirection) {
    
        var path: UIBezierPath

        switch direction {
        
        case .top:
        
            path = drawPathForTopTooltip()
        
        case .bottom:
            
            path = drawPathForBottomTooltip()
        }
            
        let contentPath = UIBezierPath(rect: self.webView.bounds)
        
        contentPath.append(path)
        
        maskLayer.fillRule = .evenOdd
        
        maskLayer.path = contentPath.cgPath
        
        self.webView.layer.mask = maskLayer
       
        // To set stroke color and width
        
        let borderLayer = CAShapeLayer()
        
        borderLayer.path = maskLayer.path
        
        borderLayer.fillColor = UIColor.clear.cgColor
        
        borderLayer.frame = webView.bounds
        
        if let colorString = self.assistInfo?.layoutInfo?.style.strokeColor {
        
            borderLayer.strokeColor = UIColor.init(hex: colorString)?.cgColor
        }
        
        if let strokeWidth = self.assistInfo?.layoutInfo?.style.strokeWidth {
            
            borderLayer.lineWidth = CGFloat(strokeWidth)
        
        } else {
            
            borderLayer.lineWidth = 0.0
        }
            
        self.webView.layer.addSublayer(borderLayer)
    }
        
    /// draws mask layer path for top arrow direction.
    func drawPathForTopTooltip() -> UIBezierPath {
    
        let path = UIBezierPath()
        let contentSize = self.webView.frame.size
        
        // Start path from top left corner of html and travel to top point of arrow
        path.move(to: CGPoint(x: 0, y: 0))
        let arrowMidX: CGFloat = getXForArrow()
        
        // Arrow points
        let arrowTopPoint = CGPoint(x: arrowMidX, y: 1)
        let arrowLeftPoint = CGPoint(x: arrowMidX-halfWidthForArrow, y: minimalSpacing)
        let arrowRightPoint = CGPoint(x: arrowMidX+halfWidthForArrow, y: minimalSpacing)
        
        // Top Left Corner points
        let tlCornerTopPoint = CGPoint(x: minimalSpacing + cornerRadius, y: minimalSpacing)
        let tlCornerBottomPoint = CGPoint(x: minimalSpacing, y: minimalSpacing+cornerRadius)
        let tlCornerControlPoint = CGPoint(x: minimalSpacing, y: minimalSpacing)
        
        // Bottom Left Corner Points
        let blCornerTopPoint = CGPoint(x: minimalSpacing, y: contentSize.height - (minimalSpacing+cornerRadius))
        let blCornerBottomPoint = CGPoint(x: (minimalSpacing + cornerRadius), y: contentSize.height - minimalSpacing)
        let blCornerControlPoint = CGPoint(x: minimalSpacing, y: contentSize.height - minimalSpacing)
        
        // Bottom Right Corner Points
        let brCornerBottomPoint = CGPoint(x: contentSize.width - (minimalSpacing + cornerRadius), y: contentSize.height - minimalSpacing)
        let brCornerTopPoint = CGPoint(x: contentSize.width - minimalSpacing, y: contentSize.height - (minimalSpacing + cornerRadius))
        let brCornerControlPoint = CGPoint(x: contentSize.width - minimalSpacing, y: contentSize.height - minimalSpacing)
        
        // Top Right Corner Points
        let trCornerBottomPoint = CGPoint(x: contentSize.width - minimalSpacing, y: minimalSpacing + cornerRadius )
        let trCornerTopPoint = CGPoint(x: contentSize.width - (minimalSpacing + cornerRadius), y: minimalSpacing )
        let trCornerControlPoint = CGPoint(x: contentSize.width - minimalSpacing, y: minimalSpacing)
        
        // Draw path to clip
        path.addLine(to: CGPoint(x: arrowMidX, y: 0))
        path.addLine(to: arrowTopPoint)
        path.addLine(to: arrowLeftPoint)
        path.addLine(to: tlCornerTopPoint)
        path.addQuadCurve(to: tlCornerBottomPoint, controlPoint: tlCornerControlPoint)
        path.addLine(to: blCornerTopPoint)
        path.addQuadCurve(to: blCornerBottomPoint, controlPoint: blCornerControlPoint)
        path.addLine(to: brCornerBottomPoint)
        path.addQuadCurve(to: brCornerTopPoint, controlPoint: brCornerControlPoint)
        path.addLine(to: trCornerBottomPoint)
        path.addQuadCurve(to: trCornerTopPoint, controlPoint: trCornerControlPoint)
        path.addLine(to: arrowRightPoint)
        path.addLine(to: arrowTopPoint)
        path.addLine(to: CGPoint(x: arrowMidX, y: 0))
        path.addLine(to: CGPoint(x: contentSize.width, y: 0))
        path.addLine(to: CGPoint(x: contentSize.width, y: contentSize.height))
        path.addLine(to: CGPoint(x: 0, y: contentSize.height))
        path.close()
        return path
    }
    
    /// draws mask layer path for bottom arrow direction.
    func drawPathForBottomTooltip() -> UIBezierPath {
    
        let path = UIBezierPath()
        let contentSize = self.webView.frame.size
        
        // Start path from top left corner of html and travel to top point of arrow
        path.move(to: CGPoint(x: 0, y: contentSize.height))
        let arrowMidX: CGFloat = getXForArrow()
        
        // Arrow points
        let arrowBottomPoint = CGPoint(x: arrowMidX, y: contentSize.height - 1)
        let arrowLeftPoint = CGPoint(x: arrowMidX-halfWidthForArrow, y: contentSize.height - minimalSpacing)
        let arrowRightPoint = CGPoint(x: arrowMidX+halfWidthForArrow, y: contentSize.height - minimalSpacing)
        
        // Top Left Corner points
        let tlCornerTopPoint = CGPoint(x: minimalSpacing + cornerRadius, y: minimalSpacing)
        let tlCornerBottomPoint = CGPoint(x: minimalSpacing, y: minimalSpacing+cornerRadius)
        let tlCornerControlPoint = CGPoint(x: minimalSpacing, y: minimalSpacing)
        
        // Bottom Left Corner Points
        let blCornerTopPoint = CGPoint(x: minimalSpacing, y: contentSize.height - (minimalSpacing+cornerRadius))
        let blCornerBottomPoint = CGPoint(x: (minimalSpacing + cornerRadius), y: contentSize.height - minimalSpacing)
        let blCornerControlPoint = CGPoint(x: minimalSpacing, y: contentSize.height - minimalSpacing)
        
        // Bottom Right Corner Points
        let brCornerBottomPoint = CGPoint(x: contentSize.width - (minimalSpacing + cornerRadius), y: contentSize.height - minimalSpacing)
        let brCornerTopPoint = CGPoint(x: contentSize.width - minimalSpacing, y: contentSize.height - (minimalSpacing + cornerRadius))
        let brCornerControlPoint = CGPoint(x: contentSize.width - minimalSpacing, y: contentSize.height - minimalSpacing)
        
        // Top Right Corner Points
        let trCornerBottomPoint = CGPoint(x: contentSize.width - minimalSpacing, y: minimalSpacing + cornerRadius )
        let trCornerTopPoint = CGPoint(x: contentSize.width - (minimalSpacing + cornerRadius), y: minimalSpacing )
        let trCornerControlPoint = CGPoint(x: contentSize.width - minimalSpacing, y: minimalSpacing)
        
        // Draw path to clip
        path.addLine(to: CGPoint(x: arrowMidX, y: contentSize.height))
        path.addLine(to: arrowBottomPoint)
        path.addLine(to: arrowLeftPoint)
        path.addLine(to: blCornerBottomPoint)
        path.addQuadCurve(to: blCornerTopPoint, controlPoint: blCornerControlPoint)
        path.addLine(to: tlCornerBottomPoint)
        path.addQuadCurve(to: tlCornerTopPoint, controlPoint: tlCornerControlPoint)
        path.addLine(to: trCornerTopPoint)
        path.addQuadCurve(to: trCornerBottomPoint, controlPoint: trCornerControlPoint)
        path.addLine(to: brCornerTopPoint)
        path.addQuadCurve(to: brCornerBottomPoint, controlPoint: brCornerControlPoint)
        path.addLine(to: arrowRightPoint)
        path.addLine(to: arrowBottomPoint)
        path.addLine(to: CGPoint(x: arrowMidX, y: contentSize.height))
        path.addLine(to: CGPoint(x: contentSize.width, y: contentSize.height))
        path.addLine(to: CGPoint(x: contentSize.width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.close()
        return path
    }
    
    func getXForArrow() -> CGFloat {
        let globalToView = getGlobalToViewFrame()
        var arrowMidX: CGFloat = globalToView.midX - toolTipView.frame.origin.x
                
        // edge case for left side tooltip
        if (globalToView.midX-minimalSpacing) <= minimalSpacing {
            toolTipView.frame.origin.x -= minimalSpacing
        }
                
        // edge case for right side tooltip
        if (UIScreen.main.bounds.size.width - (globalToView.midX+minimalSpacing)) <= minimalSpacing {
            toolTipView.frame.origin.x += minimalSpacing
        }
        
        arrowMidX = globalToView.midX - toolTipView.frame.origin.x
        
        return arrowMidX
    }
        
    /// finds eligible parent view.
    /// - Parameters:
    ///   - view: Takes a non-optional view to check for eligible view or it's parent view.
    func findEligibleInView(view: UIView) -> UIView{
    
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
        
    /// checks whether a view's size is greater than the tooltipView's size.
    /// - Parameters:
    ///   - view: A non-optional to check it's size against the tooltipView's size.
    func canCompletelyHoldPointer(_ view: UIView) -> Bool {
    
        return (view.bounds.height > 120 && view.bounds.width > 260)
    }
    
    /// sets toolTip size based on the webview's callback.
    /// - Parameters:
    ///   - width: width to set for the tooltip's webview.
    ///   - height: height to set for the tooltip's webview.
    private func setToolTipDimensions(width: Float, height: Float) {
        
        let proportionalWidth = ((((self.assistInfo?.layoutInfo?.style.maxWidth ?? 0.8)*100) * Double(self.frame.width)) / 100)
        
        var sizeWidth: Double?
        
        if width <= 0 || width > Float(proportionalWidth) {
            
            sizeWidth = proportionalWidth
        
        } else if width < Float(proportionalWidth) {
            
            sizeWidth = Double(width)
        }
                            
        self.webView.frame.size = CGSize(width: CGFloat(sizeWidth ?? Double(width)), height: CGFloat(height))
            
        self.toolTipView.frame.size = CGSize(width: CGFloat(sizeWidth ?? Double(width)), height: CGFloat(height))
    }
    
    override func didReceive(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let body = message.body as? String else { return }
        guard let data = body.data(using: .utf8) else { return }
        guard let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Dictionary<String,Any> else {return}
        guard let metaData = dict[constant_pageMetaData] as? Dictionary<String,Any> else {return}
        guard let rect = metaData[constant_rect] as? Dictionary<String,Float> else {return}
        guard let width = rect[constant_width] else { return }
        guard let height = rect[constant_height] else { return }
        setToolTipDimensions(width: width, height: height)
        if dict["type"] as? String == "resize" { DispatchQueue.main.async {
            
            self.placePointer()
        } }
    }
    
    override func performEnterAnimation(animation: String) {
        
        let arrowDirection = getArrowDirection()
        guard let direction = arrowDirection else { return }
        
        self.alpha = 0
        UIView.animate(withDuration: 0.12) {
            self.alpha = 1
        }
        
        self.toolTipView.alpha = 0
        UIView.animate(withDuration: 0.04, delay: 0.08, options: .beginFromCurrentState, animations: {
            self.toolTipView.alpha = 1
        }, completion: nil)
        
        let yPosition = toolTipView.frame.origin.y
        
        if direction == .top { toolTipView.frame.origin.y = toolTipView.frame.origin.y + 20 }
        else { toolTipView.frame.origin.y = toolTipView.frame.origin.y - 20 }
        
        UIView.animate(withDuration: 0.16) {
            self.toolTipView.frame.origin.y = yPosition
        }
        
        self.leapIconView.alpha = 0
        UIView.animate(withDuration: 0.08, delay: 0.24, options: .beginFromCurrentState, animations: {
            self.leapIconView.alpha = 1
        }, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if (assistInfo?.layoutInfo?.dismissAction.outsideDismiss ?? false) && !tappedOnToView {
            performExitAnimation(animation: self.assistInfo?.layoutInfo?.exitAnimation ?? "fade_out", byUser: true, autoDismissed: false, byContext: false, panelOpen: false, action: [constant_body: [constant_close: true]])
        }
    }
}
