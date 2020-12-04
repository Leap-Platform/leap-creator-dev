//
//  JinySpot.swift
//  JinyDemo
//
//  Created by mac on 09/10/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// JinySpot - A Web InViewAssist AUI Component class to show a tip on the screen over a circular spot and highlights the source view.
public class JinySpot: JinyInViewAssist {
    
    /// circleView to surround highlighted view with tooltip.
    private var circleView = UIView(frame: .zero)
    
    /// toolTipView which carries webView.
    private var toolTipView = UIView(frame: .zero)
      
    /// maskLayer for the tooltip.
    private var maskLayer = CAShapeLayer()
    
    /// cornerRadius of the toolTip.
    private var cornerRadius: CGFloat = 6.0
    
    /// minimal spacing for the tooltip.
    private let minimalSpacing: CGFloat = 12.0
    
    /// half width for the arrow.
    private let halfWidthForArrow: CGFloat = 10
    
    /// original isUserInteractionEnabled boolean value of the toView.
    private var toViewOriginalInteraction: Bool?
    
    /// spacing of the highlight area.
    public var highlightSpacing = 10.0
    
    /// spacing of the highlight area after manipulation
    private var manipulatedHighlightSpacing = 10.0
    
    /// corner radius for the highlight area/frame.
    public var highlightCornerRadius = 5.0
    
    /// the bridge line between highlight and tooltip which is of the type ConnectorType
    public var connectorType: ConnectorType = .none
    
    /// A view frame to highlight the source view to which tooltip is pointed to
    public var highlightType: HighlightType = .circle
    
    /// the length of the connector that connects from highlighted view to the tooltip.
    public var connectorLength = 40.0
    
    /// the color of the connector.
    public var connectorColor: UIColor = .red
    
    /// presents pointer after setup, configure and show() webview content method is called and when the delegate is called for the webView.
    func showSpot() {
        
        setupView()
        
        configureTooltipView()
        
        show()
    }
        
    /// setup toView, inView, toolTipView and webView.
    func setupView() {
        
        if toView?.window != UIApplication.shared.keyWindow {
            
            inView = toView!.window
            
        } else {
            
            inView = UIApplication.getCurrentVC()?.view
        }
        
        inView?.addSubview(self)
           
        configureOverlayView()
        
        self.backgroundColor = .clear
        
        self.addSubview(circleView)
                   
        self.addSubview(toolTipView)
    
        toolTipView.addSubview(webView)
    }
    
    /// configures webView, toolTipView and highlights anchor method called.
    func configureTooltipView() {
        
       self.webView.scrollView.isScrollEnabled = false
        
       toViewOriginalInteraction = self.toView?.isUserInteractionEnabled
                
       maskLayer.bounds = self.webView.bounds
    
       cornerRadius = CGFloat((self.assistInfo?.layoutInfo?.style.cornerRadius) ?? 6.0)

       toolTipView.layer.cornerRadius = cornerRadius
    
       toolTipView.layer.masksToBounds = true
        
       if assistInfo?.highlightAnchor ?? true {
           
          highlightAnchor()
           
       } else {
           
          self.backgroundColor = .clear
       }
        
        if assistInfo?.layoutInfo?.style.isContentTransparent ?? false {
            
            self.webView.backgroundColor = .clear
        }
    }
    
    /// configures connector.
    func configureConnector() {
        
        if let connectorLength = assistInfo?.extraProps?.props["connectorLength"] as? Double {
            
            self.connectorLength = connectorLength
        }
        
        if let connectorColor = assistInfo?.extraProps?.props["connectorColor"] as? String {
            
            self.connectorColor = UIColor.colorFromString(string: connectorColor)
        }
                    
        self.connectorType = .none
        
        let arrowDirection = getArrowDirection()
             
        guard let direction = arrowDirection else {
                 
          return
        }
        
        let globalToView = toView?.superview?.convert(toView!.frame, to: inView)
        
        let midX: CGFloat = globalToView!.midX
        
        var midY: CGFloat = 0.0
        
        var toMidY: CGFloat = 0.0
        
        switch direction {
            
        case .top:
            
            midY = (globalToView?.origin.y)! + (globalToView?.size.height)!
            
            if assistInfo?.highlightAnchor ?? true {
                
                midY = midY + CGFloat(manipulatedHighlightSpacing) - CGFloat(manipulatedHighlightSpacing/2)
            }
            
            toMidY = midY + CGFloat(connectorLength) + CGFloat(manipulatedHighlightSpacing/2)
            
        case .bottom:
            
            midY = (globalToView?.origin.y)!
            
            if assistInfo?.highlightAnchor ?? true {
                
                midY = midY - CGFloat(manipulatedHighlightSpacing)
            }
            
            toMidY = midY - CGFloat(connectorLength)
        }
                
        switch connectorType {
            
        case .solid:
            
            self.layer.addSolidLine(fromPoint: CGPoint(x: midX, y: midY), toPoint: CGPoint(x: midX, y: toMidY), withColor: connectorColor.cgColor)
            
        case .solidWithCircle:
            
            self.layer.addSolidLineWithCircle(fromPoint: CGPoint(x: midX, y: midY), toPoint: CGPoint(x: midX, y: toMidY), withColor: connectorColor.cgColor)
            
        case .dashGap:
            
            self.layer.addDashedLine(fromPoint: CGPoint(x: midX, y: midY), toPoint: CGPoint(x: midX, y: toMidY), withColor: connectorColor.cgColor)
            
        case .dashGapWithCircle:
            
            self.layer.addDashedLineWithCircle(fromPoint: CGPoint(x: midX, y: midY), toPoint: CGPoint(x: midX, y: toMidY), withColor: connectorColor.cgColor)
            
        case .none:
            
            print("JinySpot")
        }
    }
    
    /// configures circular view.
    func configureCircularView() {
        
        let toViewFrame = toView?.superview?.convert(toView!.frame, to: nil)
        
        let toViewOrigin = toViewFrame!.origin
        
        let toViewSize = toViewFrame!.size
        
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
        
          circleView.backgroundColor = UIColor.colorFromString(string: colorString)
        
        } else {
            
          circleView.backgroundColor = UIColor.black
        }
                
        toolTipView.backgroundColor = .clear
        webView.backgroundColor = .clear
    }
      
    /// sets the pointer direction, origin and path for the toolTipView layer.
    func placePointer() {
        
       configureConnector()
    
       let arrowDirection = getArrowDirection()
            
       guard let direction = arrowDirection else {
                
         return
       }
        
        if direction == .top {
            
            configureJinyIconView(superView: self, toItemView: toolTipView, alignmentType: .bottom)
        
        } else {
            
            configureJinyIconView(superView: self, toItemView: toolTipView, alignmentType: .top)
        }
            
       setOriginForDirection(direction: direction)
        
       drawMaskLayerFor(direction)
        
       configureCircularView()
    }
    
    /// Observes the toolTipView's Origin, gets called when there is a change in position.
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            
        if keyPath == "position" {
                
           placePointer()
        }
    }
        
    /// gets the arrow direction - top or bottom.
    func getArrowDirection() -> JinyTooltipArrowDirection? {
    
        let globalToViewFrame = toView!.superview!.convert(toView!.frame, to: inView)

        let toViewTop = globalToViewFrame.origin.y
        
        var toViewBottom = toViewTop + globalToViewFrame.size.height
        
        if assistInfo?.highlightAnchor ?? true {
            
            toViewBottom = toViewBottom + CGFloat(manipulatedHighlightSpacing)
        }

        let inViewFrame = (inView != nil ? inView!.frame : UIScreen.main.bounds)
        
        var iconSpacing: CGFloat = 0
        
        if iconInfo?.isEnabled ?? false {
            
            iconSpacing = self.jinyIconView.iconSize + self.jinyIconView.iconGap
        }
        
        if (toViewBottom + CGFloat(connectorLength) + toolTipView.frame.size.height) + iconSpacing <= inViewFrame.size.height {
            
            return .top
        
        } else {
            
            return .bottom
        }
    }
        
    /// sets the origin for arrow direction.
    /// - Parameters:
    ///   - direction: ToolTip arrow direction.
    func setOriginForDirection(direction: JinyTooltipArrowDirection) {
            
        let globalToViewFrame = toView!.superview!.convert(toView!.frame, to:inView)
        
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
            
            y = y - minimalSpacing + (CGFloat(connectorLength))
            
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
            
            y = y + minimalSpacing - (CGFloat(connectorLength))
        }
        
        toolTipView.frame.origin = CGPoint(x: x, y: y)
    }
        
    /// draws mask layer based on direction.
    /// - Parameters:
    ///   - direction: ToolTip arrow direction.
    func drawMaskLayerFor(_ direction:JinyTooltipArrowDirection) {
    
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
        
    /// draws mask layer path for top arrow direction.
    func drawPathForTopTooltip() -> UIBezierPath {
    
        let path = UIBezierPath()

        path.move(to: CGPoint(x: 0, y: cornerRadius+minimalSpacing))
        
        path.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius+minimalSpacing), radius: cornerRadius, startAngle: .pi, endAngle: 3 * .pi/2, clockwise: true)
                    
        path.addLine(to: CGPoint(x: self.webView.frame.size.width-cornerRadius, y: minimalSpacing))
        
        path.addArc(withCenter: CGPoint(x: self.webView.frame.size.width-cornerRadius, y: cornerRadius+minimalSpacing), radius: cornerRadius, startAngle: 3 * .pi/2, endAngle: 0, clockwise: true)
            
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
        
        path.addLine(to: CGPoint(x: contentSize.width, y: contentSize.height-minimalSpacing-cornerRadius))
        
        path.addArc(withCenter: CGPoint(x: contentSize.width-cornerRadius, y: contentSize.height-minimalSpacing-cornerRadius), radius: cornerRadius, startAngle: 0, endAngle: .pi/2, clockwise: true)
                    
        path.addLine(to: CGPoint(x: cornerRadius, y: contentSize.height-minimalSpacing))
        
        path.addArc(withCenter: CGPoint(x: cornerRadius, y: contentSize.height-minimalSpacing-cornerRadius), radius: cornerRadius, startAngle: .pi/2, endAngle: .pi, clockwise: true)
        
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
        
        let globalToView = toView?.superview?.convert(toView!.frame, to: nil)

        let origin = globalToView!.origin
        
        let size = globalToView!.size
        
        let path = UIBezierPath(rect: inView!.bounds)
                
        var transparentPath = UIBezierPath(roundedRect: CGRect(x: Double(origin.x) - highlightSpacing, y: Double(origin.y) - highlightSpacing, width: Double(size.width) + (highlightSpacing*2), height: Double(size.height) + (highlightSpacing*2)), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: highlightCornerRadius, height: highlightCornerRadius))
        
        if let highlightType = assistInfo?.extraProps?.props["highlightType"] as? String {
            
            self.highlightType = HighlightType(rawValue: highlightType) ?? .rect
        }
        
        switch self.highlightType {
            
        case .rect:
            
            if let highlightCornerRadius = assistInfo?.extraProps?.props["highlightCornerRadius"] as? Double {
                
                self.highlightCornerRadius = highlightCornerRadius
            }
        
            transparentPath = UIBezierPath(roundedRect: CGRect(x: Double(origin.x) - highlightSpacing, y: Double(origin.y) - highlightSpacing, width: Double(size.width) + (highlightSpacing*2), height: Double(size.height) + (highlightSpacing*2)), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: highlightCornerRadius, height: highlightCornerRadius))

        case .capsule:
            
            transparentPath = UIBezierPath(roundedRect: CGRect(x: Double(origin.x) - highlightSpacing, y: Double(origin.y) - highlightSpacing, width: Double(size.width) + (highlightSpacing*2), height: Double(size.height) + (highlightSpacing*2)), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: transparentPath.bounds.width/2, height: transparentPath.bounds.width/2))
            
        case .circle:
            
            var radius = size.width
            
            var x = Double(origin.x) - highlightSpacing
            
            var y = Double(origin.y) - Double(radius/2)
            
            if size.height > size.width {
                
                radius = size.height
                
                x = Double(origin.x) - Double(radius/2)
                
                y = Double(origin.y) - highlightSpacing
            }
            
            transparentPath = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: Double(radius) + (highlightSpacing*2), height: Double(radius) + (highlightSpacing*2)))
            
            manipulatedHighlightSpacing = Double(radius/2)
        }
        
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
    
    override func didFinish(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { [weak self] (value, error) in
            if let height = value as? CGFloat {
                                
                self?.setToolTipDimensions(width: Float(self?.webView.frame.size.width ?? 0.0), height: Float(height))
                
                DispatchQueue.main.async {
                    
                    self?.placePointer()
                }
            }
        })
    }
    
    /// sets toolTip size based on the webview's callback.
    /// - Parameters:
    ///   - width: width to set for the tooltip's webview.
    ///   - height: height to set for the tooltip's webview.
    private func setToolTipDimensions(width: Float, height: Float) {
        
        let proportionalWidth = (((self.assistInfo?.layoutInfo?.style.maxWidth ?? 80.0) * Double(self.frame.width)) / 100)
        
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
        guard let metaData = dict["pageMetaData"] as? Dictionary<String,Any> else {return}
        guard let rect = metaData["rect"] as? Dictionary<String,Float> else {return}
        guard let width = rect["width"] else { return }
        guard let height = rect["height"] else { return }
        setToolTipDimensions(width: width, height: height)
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
    
    public override func performEnterAnimation(animation: String) {
        
        circleView.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
        
        self.webView.alpha = 0
        
        self.jinyIconView.alpha = 0
        
        UIView.animate(withDuration: 0.2, animations: {
            
            self.circleView.transform = CGAffineTransform.identity
            
        }) { (_) in
            
            UIView.animate(withDuration: 0.08) {
                
                self.webView.alpha = 1
                
                self.jinyIconView.alpha = 1
                
                self.delegate?.didPresentAssist()
            }
        }
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if assistInfo?.layoutInfo?.outsideDismiss ?? false {
            
            performExitAnimation(animation: assistInfo?.layoutInfo?.exitAnimation ?? "fade_out")
            
            self.delegate?.didDismissAssist()
            
            guard let userInteraction = toViewOriginalInteraction else {
                
               return
            }
            
            toView?.isUserInteractionEnabled = userInteraction
        }
    }
}
