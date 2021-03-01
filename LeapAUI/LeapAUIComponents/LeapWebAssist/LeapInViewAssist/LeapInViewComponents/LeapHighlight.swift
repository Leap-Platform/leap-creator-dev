//
//  LeapHighlight.swift
//  LeapAUI
//
//  Created by mac on 05/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// enum type for connector
enum LeapHighlightConnectorType: String {
    
    case solid = "solid"
    case solidWithCircle = "solid_with_circle"
    case dashGap = "dash_gap"
    case dashGapWithCircle = "dash_gap_with_circle"
    case none = "none"
}

/// enum type for Highlight
enum LeapHighlightType: String {
    
    case circle = "circle"
    case rect = "rect"
    case capsule = "capsule"
}

/// LeapHighlight - A Web InViewAssist AUI Component class to show a tip with a connector on the screen and highlights the source view.
class LeapHighlight: LeapTipView {
      
    /// maskLayer for the tooltip.
    private var maskLayer = CAShapeLayer()
    
    /// cornerRadius of the toolTip.
    private var cornerRadius: CGFloat = 6.0
    
    /// minimal spacing for the tooltip.
    private let minimalSpacing: CGFloat = 12.0
    
    /// half width for the arrow.
    private let halfWidthForArrow: CGFloat = 10
    
    /// spacing of the highlight area.
    var highlightSpacing = 10.0
    
    /// spacing of the highlight area after manipulation
    private var manipulatedHighlightSpacing = 10.0
    
    /// corner radius for the highlight area/frame.
    var highlightCornerRadius = 5.0
    
    /// the bridge line between highlight and tooltip which is of the type ConnectorType.
    var connectorType: LeapHighlightConnectorType = .solidWithCircle
    
    /// A view frame to highlight the source view to which tooltip is pointed to.
    var highlightType: LeapHighlightType = .circle
    
    /// the length of the connector that connects from highlighted view to the tooltip.
    var connectorLength = 40.0
    
    /// the color of the connector.
    var connectorColor: UIColor = .red
    
    /// radius of the circle at the connector end.
    var connectorCircleRadius: CGFloat = 5.0
    
    /// presents pointer after setup, configure and show() webview content method is called and when the delegate is called for the webView.
    func presentHighlight() {
        
        setupView()
        
        configureTooltipView()
        
        setupAutoFocus()
        
        show()
    }
    
    func presentHighlight(toRect: CGRect, inView: UIView?) {
        
        webRect = toRect
                
        presentHighlight()
    }
    
    func updateHighlight() {
        
        if assistInfo?.highlightAnchor ?? true {
            
           highlightAnchor()
        }
        
        placePointer()
    }
    
    func updateHighlight(toRect: CGRect, inView: UIView?) {
        
        webRect = toRect
        
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
                
       toViewOriginalInteraction = self.toView?.isUserInteractionEnabled
                
       maskLayer.bounds = self.webView.bounds
    
       cornerRadius = CGFloat((self.assistInfo?.layoutInfo?.style.cornerRadius) ?? 8.0)

       webView.layer.cornerRadius = cornerRadius
    
       webView.layer.masksToBounds = true
        
       if assistInfo?.highlightAnchor ?? true {
           
          highlightAnchor()
       }
        
        if assistInfo?.layoutInfo?.style.isContentTransparent ?? false {
            
            self.webView.isOpaque = false
        
        } else {
            
            self.webView.isOpaque = true
        }
    }
    
    /// configures connector.
    func configureConnector() {
        
        if let connectorLength = assistInfo?.extraProps?.props[constant_highlightConnectorLength] as? String {
            
            self.connectorLength = Double(connectorLength) ?? self.connectorLength
        }
        
        if let connectorColor = assistInfo?.extraProps?.props[constant_highlightConnectorColor] as? String {
            
            self.connectorColor = UIColor.init(hex: connectorColor) ?? .black
        }
        
        if let connectorType = assistInfo?.extraProps?.props[constant_highlightConnectorType] as? String {
            
            self.connectorType = LeapHighlightConnectorType(rawValue: connectorType) ?? .solid
        }
        
        let arrowDirection = getArrowDirection()
             
        guard let direction = arrowDirection else {
                 
          return
        }
        
        let globalToView = getGlobalToViewFrame()
        
        let midX: CGFloat = globalToView.midX
        
        var midY: CGFloat = 0.0
        
        var toMidY: CGFloat = 0.0
        
        switch direction {
            
        case .top:
            
            midY = (globalToView.origin.y) + (globalToView.size.height)
            
            if assistInfo?.highlightAnchor ?? true {
                
                midY = midY + CGFloat(manipulatedHighlightSpacing)
            }
            
            toMidY = midY + CGFloat(connectorLength)
            
        case .bottom:
            
            midY = (globalToView.origin.y)
            
            if assistInfo?.highlightAnchor ?? true {
                
                midY = midY - CGFloat(manipulatedHighlightSpacing)
            }
            
            toMidY = midY - CGFloat(connectorLength)
        }
        
        for layer in (self.layer.sublayers ?? []) {
            
            if let jLayer = layer as? LeapLayer {
            
                jLayer.removeFromSuperlayer()
            }
        }
        
        let leapLayer = LeapLayer()
                
        switch connectorType {
            
        case .solid:
            
            leapLayer.addSolidLine(fromPoint: CGPoint(x: midX, y: midY), toPoint: CGPoint(x: midX, y: toMidY), withColor: connectorColor.cgColor)
            
            self.layer.addSublayer(leapLayer)
            
        case .solidWithCircle:
                        
            leapLayer.addSolidLineWithCircle(fromPoint: CGPoint(x: midX, y: midY), toPoint: CGPoint(x: midX, y: toMidY), withColor: connectorColor.cgColor, withCircleRadius: connectorCircleRadius)
            
            self.layer.addSublayer(leapLayer)
            
        case .dashGap:
            
            leapLayer.addDashedLine(fromPoint: CGPoint(x: midX, y: midY), toPoint: CGPoint(x: midX, y: toMidY), withColor: connectorColor.cgColor)
            
            self.layer.addSublayer(leapLayer)
            
        case .dashGapWithCircle:
            
            leapLayer.addDashedLineWithCircle(fromPoint: CGPoint(x: midX, y: midY), toPoint: CGPoint(x: midX, y: toMidY), withColor: connectorColor.cgColor, withCircleRadius: connectorCircleRadius)
            
            self.layer.addSublayer(leapLayer)
            
        case .none:
            
            print("No Connector")
        }
    }
      
    /// sets the pointer direction, origin and path for the toolTipView layer.
    func placePointer() {
        
       configureConnector()
    
       let arrowDirection = getArrowDirection()
            
       guard let direction = arrowDirection else {
                
         return
       }
        
       if direction == .top {
            
            configureLeapIconView(superView: inView!, toItemView: toolTipView, alignmentType: .bottom)
        
        } else {
            
            configureLeapIconView(superView: inView!, toItemView: toolTipView, alignmentType: .top)
        }
            
       setOriginForDirection(direction: direction)
        
       drawMaskLayerFor(direction)
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

        let toViewTop = globalToViewFrame.origin.y
        
        var toViewBottom = toViewTop + globalToViewFrame.size.height
        
        if assistInfo?.highlightAnchor ?? true {
            
            toViewBottom = toViewBottom + CGFloat(manipulatedHighlightSpacing)
        }

        let inViewFrame = (inView != nil ? inView!.frame : UIScreen.main.bounds)
        
        var iconSpacing: CGFloat = 0
        
        if iconInfo?.isEnabled ?? false {
            
            iconSpacing = self.leapIconView.iconSize + self.leapIconView.iconGap
        }
        
        if (toViewBottom + CGFloat(connectorLength) + toolTipView.frame.size.height) + iconSpacing <= inViewFrame.size.height {
            
            return .top
        
        } else {
            
            return .bottom
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
            
            if assistInfo?.highlightAnchor ?? true {
                
                y = y + CGFloat(manipulatedHighlightSpacing)
            }
            
            y = y + (CGFloat(connectorLength))
            
        case .bottom:
            
            x = globalToViewFrame.midX - (toolTipView.frame.size.width/2)
            
            if (x + toolTipView.frame.size.width) > inViewFrame.size.width {
                
                x = x - ((x + toolTipView.frame.size.width) - inViewFrame.size.width)
            }
            
            if x < 0 {
                
               x = 0
            }
            
            y = (globalToViewFrame.origin.y - toolTipView.frame.size.height)
            
            if assistInfo?.highlightAnchor ?? true {
                
                y = y - CGFloat(manipulatedHighlightSpacing)
            }
            
            y = y - (CGFloat(connectorLength))
        }
        
        if (self.assistInfo?.layoutInfo?.style.maxWidth ?? 0.8) >= 1 {
            
            x = x - 12
        }
        
        toolTipView.frame.origin = CGPoint(x: x, y: y)
    }
        
    /// draws mask layer based on direction.
    /// - Parameters:
    ///   - direction: ToolTip arrow direction.
    func drawMaskLayerFor(_ direction:LeapTooltipArrowDirection) {
    
        var path:UIBezierPath?

        switch direction {
        
        case .top:
        
            path = drawPathForTopTooltip()
        
        case .bottom:
            
            path = drawPathForBottomTooltip()
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
        
        // comment this if you want value from config
        assistInfo?.layoutInfo?.style.strokeColor = "#00000000" // hardcoded value
        
        // comment this if you want value from config
        assistInfo?.layoutInfo?.style.strokeWidth = 0 // hardcoded value
        
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

        path.move(to: CGPoint(x: 0, y: 0))
        
        path.addArc(withCenter: CGPoint(x: 0, y: 0), radius: cornerRadius, startAngle: .pi, endAngle: 3 * .pi/2, clockwise: true)
                    
        path.addLine(to: CGPoint(x: self.webView.frame.size.width-cornerRadius, y: 0))
        
        path.addArc(withCenter: CGPoint(x: self.webView.frame.size.width-cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: 3 * .pi/2, endAngle: 0, clockwise: true)
            
        path.addLine(to: CGPoint(x: self.webView.frame.size.width, y: 0))
        
        path.addLine(to: CGPoint(x: 0, y: 0))
        
        path.close()
        
        return path
    }
    
    /// draws mask layer path for bottom arrow direction.
    func drawPathForBottomTooltip() -> UIBezierPath {
    
        let contentSize = self.webView.frame.size

        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: 0, y: contentSize.height))
        
        path.addLine(to: CGPoint(x: contentSize.width, y: contentSize.height))
        
        path.addLine(to: CGPoint(x: contentSize.width, y: contentSize.height-cornerRadius))
        
        path.addArc(withCenter: CGPoint(x: contentSize.width-cornerRadius, y: contentSize.height-cornerRadius), radius: cornerRadius, startAngle: 0, endAngle: .pi/2, clockwise: true)
                    
        path.addLine(to: CGPoint(x: cornerRadius, y: contentSize.height))
        
        path.addArc(withCenter: CGPoint(x: cornerRadius, y: contentSize.height-cornerRadius), radius: cornerRadius, startAngle: .pi/2, endAngle: .pi, clockwise: true)
        
        path.close()
            
        return path
    }
        
    /// finds eligible parent view.
    /// - Parameters:
    ///   - view: Takes a non-optional view to check for eligible view or it's parent view.
    func findEligibleInView(view: UIView) -> UIView {
    
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
    
    /// Highlights the toView to which the tooltipView is pointed to.
    private func highlightAnchor() {
        
        manipulatedHighlightSpacing = highlightSpacing
        
        let globalToView = getGlobalToViewFrame()

        let origin = globalToView.origin
        
        let size = globalToView.size
        
        let path = UIBezierPath(rect: inView!.bounds)
                
        var transparentPath = UIBezierPath(roundedRect: CGRect(x: Double(origin.x) - highlightSpacing, y: Double(origin.y) - highlightSpacing, width: Double(size.width) + (highlightSpacing*2), height: Double(size.height) + (highlightSpacing*2)), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: highlightCornerRadius, height: highlightCornerRadius))
        
        if let highlightType = assistInfo?.extraProps?.props[constant_highlightType] as? String {
            
            self.highlightType = LeapHighlightType(rawValue: highlightType) ?? .rect
        }
        
        switch self.highlightType {
            
        case .rect:
            
            if let highlightCornerRadius = assistInfo?.extraProps?.props[constant_highlightCornerRadius] as? String {
                
                self.highlightCornerRadius = Double(highlightCornerRadius) ?? self.highlightCornerRadius
            }
        
            transparentPath = UIBezierPath(roundedRect: CGRect(x: Double(origin.x) - highlightSpacing, y: Double(origin.y) - highlightSpacing, width: Double(size.width) + (highlightSpacing*2), height: Double(size.height) + (highlightSpacing*2)), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: highlightCornerRadius, height: highlightCornerRadius))

        case .capsule:
            
            transparentPath = UIBezierPath(roundedRect: CGRect(x: Double(origin.x) - highlightSpacing, y: Double(origin.y) - highlightSpacing, width: Double(size.width) + (highlightSpacing*2), height: Double(size.height) + (highlightSpacing*2)), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: transparentPath.bounds.width/2, height: transparentPath.bounds.width/2))
            
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
            
            transparentPath = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: diameter, height: diameter))
        }
        
        path.append(transparentPath)
        path.usesEvenOddFillRule = true

        let fillLayer = CAShapeLayer()
        fillLayer.path = path.cgPath
        fillLayer.fillRule = .evenOdd
        fillLayer.opacity = 1.0
        self.layer.mask = fillLayer
        
        if (assistInfo?.highlightAnchor ?? false) && assistInfo?.highlightClickable ?? false {
            
            toView?.isUserInteractionEnabled = true
        
        } else {
            
            toView?.isUserInteractionEnabled = false
        }
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
        
        if (self.assistInfo?.layoutInfo?.style.maxWidth ?? 0.8) >= 1 {
            
            sizeWidth = sizeWidth ?? Double(width) - 24
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
        DispatchQueue.main.async {
           self.placePointer()
        }
        //toView?.layer.addObserver(toolTipView, forKeyPath: "position", options: .new, context: nil)
    }
    
    override func performEnterAnimation(animation: String) {
        
        let alpha = self.alpha
        
        self.alpha = 0
        
        self.webView.alpha = 0
        
        self.leapIconView.alpha = 0
        
        UIView.animate(withDuration: 0.12, animations: {
            
            self.alpha = alpha
            
        }) { (_) in
            
            UIView.animate(withDuration: 0.08) {
                
                self.webView.alpha = 1
                
                self.leapIconView.alpha = 1
                
                self.delegate?.didPresentAssist()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if assistInfo?.layoutInfo?.dismissAction.outsideDismiss ?? false {
            
            remove(byContext: false, byUser: true, autoDismissed: false, panelOpen: false, action: nil)
        }
    }
}
