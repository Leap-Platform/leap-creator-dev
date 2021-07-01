//
//  LeapSpot.swift
//  LeapAUI
//
//  Created by mac on 09/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// LeapSpot - A Web InViewAssist AUI Component class to show a tip on the screen over a circular spot and highlights the source view.
class LeapSpot: LeapTipView {
    
    /// circleView to surround highlighted view with tooltip.
    private var circleView = UIView(frame: .zero)
      
    /// maskLayer for the tooltip.
    private var maskLayer = CAShapeLayer()
    
    /// cornerRadius of the toolTip.
    private var cornerRadius: CGFloat = 6.0
    
    /// minimal spacing for the tooltip.
    private let minimalSpacing: CGFloat = 12.0
    
    /// half width for the arrow.
    private let halfWidthForArrow: CGFloat = 10
    
    /// the bridge line between highlight and tooltip which is of the type ConnectorType
    var connectorType: LeapHighlightConnectorType = .none
    
    /// the length of the connector that connects from highlighted view to the tooltip.
    var connectorLength = 40.0
    
    /// the color of the connector.
    var connectorColor: UIColor = .red
    
    /// radius of the circle at the connector end.
    var connectorCircleRadius: CGFloat = 5.0
    
    /// presents pointer after setup, configure and show() webview content method is called and when the delegate is called for the webView.
    func presentSpot() {
        
        setupView()
        
        configureTooltipView()
        
        setupAutoFocus()
        
        show()
    }
    
    func presentSpot(toRect: CGRect, inView: UIView?) {
        
        webRect = toRect
                
        presentSpot()
    }
    
    func updateSpot() {
        
        guard let previousFrame = previousFrame else { return }
        
        if previousFrame.origin == getGlobalToViewFrame().origin { return }
        
        if assistInfo?.highlightAnchor ?? true {
            
           highlightAnchor()
        }
        
        placePointer()
    }
    
    func updateSpot(toRect: CGRect, inView: UIView?) {
        
        webRect = toRect
        
        guard let previousFrame = previousFrame else { return }
        
        if previousFrame.origin == getGlobalToViewFrame().origin { return }
        
        if assistInfo?.highlightAnchor ?? true {
            
           highlightAnchor()
        }
        
        placePointer()
    }
        
    /// setup toView, inView, toolTipView and webView.
    func setupView() {
        
        inView = toView?.window
        
        inView?.addSubview(self)
           
        configureOverlayView()
        
        self.backgroundColor = .clear
        
        self.addSubview(circleView)
                   
        self.addSubview(toolTipView)
    
        webviewContainer.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        webView.leadingAnchor.constraint(equalTo: webviewContainer.leadingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: webviewContainer.topAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: webviewContainer.trailingAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: webviewContainer.bottomAnchor).isActive = true
        toolTipView.addSubview(webviewContainer)
    }
    
    /// configures webView, toolTipView and highlights anchor method called.
    func configureTooltipView() {
                                
       maskLayer.bounds = self.webView.bounds
    
       cornerRadius = CGFloat((self.assistInfo?.layoutInfo?.style.cornerRadius) ?? 6.0)

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
    }
    
    /// configures circular view.
    func configureCircularView() {
        
        let toViewFrame = getGlobalToViewFrame()
        
        let toViewOrigin = toViewFrame.origin
        
        let toViewSize = toViewFrame.size
        
        var xSpacing = highlightSpacing
        
        var ySpacing = manipulatedHighlightSpacing
        
        if toViewSize.height > toViewSize.width {
            
            ySpacing = highlightSpacing
            
            xSpacing = manipulatedHighlightSpacing
        }
        
        let totalYSpacing = CGFloat(2*ySpacing)
        
        var circleViewX: CGFloat = 0
        
        var circleViewY: CGFloat = 0
                
        let totalHeight: CGFloat = toolTipView.frame.height + CGFloat(connectorLength) + totalYSpacing + toViewSize.height
        
        var totalWidth: CGFloat = 0
        
        if (toViewOrigin.x + toViewSize.width + (2 * CGFloat(xSpacing))) >= (toolTipView.frame.origin.x + toolTipView.frame.size.width) {
            
            circleViewX = toViewOrigin.x - CGFloat(xSpacing)
            
            if toolTipView.frame.origin.x < (toViewOrigin.x - CGFloat(xSpacing)) {
                
                totalWidth = (toViewOrigin.x - CGFloat(xSpacing)) - toolTipView.frame.origin.x
                
                circleViewX = toolTipView.frame.origin.x
            }
            
           totalWidth = totalWidth + toViewSize.width + (2 * CGFloat(xSpacing))
        
        } else {
            
            circleViewX = toolTipView.frame.origin.x
            
           if toolTipView.frame.origin.x > (toViewOrigin.x - CGFloat(xSpacing)) {
                
                totalWidth = toolTipView.frame.origin.x - (toViewOrigin.x - CGFloat(xSpacing))
            
                circleViewX = toViewOrigin.x - CGFloat(xSpacing)
            }
            
           totalWidth =  totalWidth + toolTipView.frame.size.width
        }
        
        let hypotenuseRadius = sqrt((totalHeight*totalHeight) + (totalWidth*totalWidth))
        
        if toolTipView.frame.origin.y < toViewOrigin.y {
            
            circleViewY = toolTipView.frame.origin.y - hypotenuseRadius
        
        } else {
            
            circleViewY = toViewOrigin.y - CGFloat(ySpacing) - hypotenuseRadius/2
        }
                
        circleViewX = circleViewX - hypotenuseRadius
                        
        circleView.frame = CGRect(x: circleViewX, y: circleViewY, width: 2*hypotenuseRadius, height: 2*hypotenuseRadius)
        
        circleView.layer.cornerRadius = hypotenuseRadius
        circleView.clipsToBounds = true
        
        if let colorString = self.assistInfo?.layoutInfo?.style.bgColor {
        
          circleView.backgroundColor = UIColor.init(hex: colorString)
        
        } else {
            
          circleView.backgroundColor = UIColor.black
        }
                
        toolTipView.backgroundColor = .clear
        webView.backgroundColor = .clear
    }
      
    /// sets the pointer direction, origin and path for the toolTipView layer.
    func placePointer() {
        
       previousFrame = getGlobalToViewFrame()
        
       configureConnector()
    
       let arrowDirection = getArrowDirection()
            
       guard let direction = arrowDirection, inView != nil else {
                
         return
       }
        
       configureLeapIconViewForSpot(direction: direction)
            
       setOriginForDirection(direction: direction)
        
       drawMaskLayerFor(direction)
        
       configureCircularView()
    }
    
    func configureLeapIconViewForSpot(direction: LeapTooltipArrowDirection) {
        
        self.removeConstraints(self.constraints)
        
        toolTipView.removeConstraints(toolTipView.constraints)
        
        if direction == .top {
            
            configureLeapIconView(superView: self, toItemView: toolTipView, alignmentType: .bottom, cornerDistance: minimalSpacing)
        
        } else {
            
            configureLeapIconView(superView: self, toItemView: toolTipView, alignmentType: .top, cornerDistance: minimalSpacing)
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
                
        if assistInfo?.highlightAnchor ?? true {
            
            toViewTopSpacing = toViewTopSpacing - CGFloat(manipulatedHighlightSpacing)
        }
        
        var iconSpacing: CGFloat = 0
        
        if iconInfo?.isEnabled ?? false {
            
            iconSpacing = self.leapIconView.iconSize + self.leapIconView.iconGap
        }
        
        let calculatedY = (toViewTopSpacing - CGFloat(connectorLength) - toolTipView.frame.size.height) - iconSpacing
        
        if calculatedY >= inViewFrame.origin.y {
            
            return .bottom
        
        } else {
            
            return .top
        }
    }
        
    /// sets the origin for arrow direction.
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
    
    // if spot highlight requires animation, just remove the below method. The super class method takes care of the animation.
    /// Highlights the toView to which the tooltipView is pointed to.
    override func highlightAnchor() {
        
        manipulatedHighlightSpacing = highlightSpacing
        
        let globalToView = getGlobalToViewFrame()

        let origin = globalToView.origin
        
        let size = globalToView.size
        
        guard let inView = self.inView else { return }
        
        let path = UIBezierPath(rect: inView.bounds)
                
        var transparentPath = UIBezierPath()
        
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
            
            transparentPath = UIBezierPath(roundedRect: CGRect(x: Double(origin.x) - highlightSpacing, y: Double(origin.y) - highlightSpacing, width: Double(size.width) + (highlightSpacing*2), height: Double(size.height) + (highlightSpacing*2)), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: (Double(size.height) + (highlightSpacing*2))/2, height: (Double(size.height) + (highlightSpacing*2))/2))
            
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
            
        self.webviewContainer.frame.size = CGSize(width: CGFloat(sizeWidth ?? Double(width)), height: CGFloat(height))
            
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
        
        circleView.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
        
        self.webView.alpha = 0
        
        self.leapIconView.alpha = 0
        
        UIView.animate(withDuration: 0.2, animations: {
            
            self.circleView.transform = CGAffineTransform.identity
            
        }) { (_) in
            
            UIView.animate(withDuration: 0.08) {
                
                self.webView.alpha = 1
                
                self.leapIconView.alpha = 1                
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if (assistInfo?.layoutInfo?.dismissAction.outsideDismiss ?? false) && !tappedOnToView {
           performExitAnimation(animation: self.assistInfo?.layoutInfo?.exitAnimation ?? "fade_out", byUser: true, autoDismissed: false, byContext: false, panelOpen: false, action: [constant_body: [constant_close: true]])
        }
    }
}
