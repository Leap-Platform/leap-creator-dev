//
//  JinyToolTip.swift
//  JinyDemo
//
//  Created by mac on 15/09/20.
//  Copyright © 2020 Jiny. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// JinyTooltip's Arrow Direction
enum JinyTooltipArrowDirection {
    case top
    case bottom
}

/// JinyToolTip - A Web InViewAssist AUI Component class to show a tip on a view.
class JinyToolTip: JinyTipView {
      
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
    
    /// corner radius for the highlight area/frame.
    var highlightCornerRadius = 5.0
    
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
        
        if assistInfo?.highlightAnchor ?? true {
            
           highlightAnchor()
        }
        
        placePointer()
    }
    
    func updatePointer(toRect: CGRect, inView: UIView?) {
        
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
        
       if assistInfo?.highlightAnchor ?? false {
           
          highlightAnchor()
       }
    }
      
    /// sets the pointer direction, origin and path for the toolTipView layer.
    func placePointer() {
    
       let arrowDirection = getArrowDirection()
            
       guard let direction = arrowDirection else {
                
         return
       }
        
        if direction == .top {
            
            configureJinyIconView(superView: inView!, toItemView: toolTipView, alignmentType: .bottom)
        
        } else {
            
            configureJinyIconView(superView: inView!, toItemView: toolTipView, alignmentType: .top)
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
    func getArrowDirection() -> JinyTooltipArrowDirection? {
        
        guard toView?.superview != nil || webRect != nil else {
            
            return .none
        }
    
        let globalToViewFrame = getGlobalToViewFrame()

        let toViewTop = globalToViewFrame.origin.y
        
        let toViewBottom = toViewTop + globalToViewFrame.size.height

        let inViewFrame = (inView != nil ? inView!.frame : UIScreen.main.bounds)
        
        var iconSpacing: CGFloat = 0
        
        if iconInfo?.isEnabled ?? false {
            
            iconSpacing = self.jinyIconView.iconSize + self.jinyIconView.iconGap
        }
        
        if (toViewBottom + CGFloat(highlightSpacing) + toolTipView.frame.size.height) + iconSpacing <= inViewFrame.size.height {
            
            return .top
        
        } else {
            
            return .bottom
        }
    }
        
    /// sets the origin for arrow direction
    /// - Parameters:
    ///   - direction: ToolTip arrow direction.
    func setOriginForDirection(direction: JinyTooltipArrowDirection) {
            
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
            
            y = (globalToViewFrame.origin.y - toolTipView.frame.size.height)
            
            if assistInfo?.highlightAnchor ?? false {
                
                y = y - CGFloat(highlightSpacing)
            }
        }
        
        if (self.assistInfo?.layoutInfo?.style.maxWidth ?? 0.8) >= 1 {
            
            x = x - 12
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

        path.move(to: CGPoint(x: 0, y: cornerRadius+minimalSpacing))
        
        path.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius+minimalSpacing), radius: cornerRadius, startAngle: .pi, endAngle: 3 * .pi/2, clockwise: true)
            
        let globalToView = getGlobalToViewFrame()
        
        let arrowMidX: CGFloat = globalToView.midX - toolTipView.frame.origin.x
                    
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
    
    /// draws mask layer path for bottom arrow direction.
    func drawPathForBottomTooltip() -> UIBezierPath {
    
        let contentSize = self.webView.frame.size

        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: 0, y: contentSize.height))
        
        path.addLine(to: CGPoint(x: contentSize.width, y: contentSize.height))
        
        path.addLine(to: CGPoint(x: contentSize.width, y: contentSize.height-minimalSpacing-cornerRadius))
        
        path.addArc(withCenter: CGPoint(x: contentSize.width-cornerRadius, y: contentSize.height-minimalSpacing-cornerRadius), radius: cornerRadius, startAngle: 0, endAngle: .pi/2, clockwise: true)
            
        let globalToView = getGlobalToViewFrame()
        
        let arrowMidX: CGFloat = globalToView.midX - toolTipView.frame.origin.x
                
        path.addLine(to: CGPoint(x: arrowMidX+halfWidthForArrow, y: contentSize.height-minimalSpacing))
        
        path.addLine(to: CGPoint(x: arrowMidX, y: contentSize.height-1))
        
        path.addLine(to: CGPoint(x: arrowMidX-halfWidthForArrow, y: contentSize.height-minimalSpacing))
        
        path.addLine(to: CGPoint(x: cornerRadius, y: contentSize.height-minimalSpacing))
        
        path.addArc(withCenter: CGPoint(x: cornerRadius, y: contentSize.height-minimalSpacing-cornerRadius), radius: cornerRadius, startAngle: .pi/2, endAngle: .pi, clockwise: true)
        
        path.close()
            
        return path
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
    
    /// Highlights the toView to which the tooltipView is pointed to.
    private func highlightAnchor() {
        
        let globalToView = getGlobalToViewFrame()

        let origin = globalToView.origin
        
        let size = globalToView.size
        
        let path = UIBezierPath(rect: inView!.bounds)
                
        let transparentPath = UIBezierPath(roundedRect: CGRect(x: Double(origin.x) - highlightSpacing, y: Double(origin.y) - highlightSpacing, width: Double(size.width) + (highlightSpacing*2), height: Double(size.height) + (highlightSpacing*2)), byRoundingCorners: .allCorners, cornerRadii: CGSize(width: highlightCornerRadius, height: highlightCornerRadius))
        
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
        
        let arrowDirection = getArrowDirection()
             
        guard let direction = arrowDirection else {
                 
          return
        }
    
        let alpha = self.alpha
        
        self.alpha = 0
        
        self.webView.alpha = 0
        
        self.jinyIconView.alpha = 0
        
        let yPosition = toolTipView.frame.origin.y
        
        if direction == .top {
            
            toolTipView.frame.origin.y = toolTipView.frame.origin.y + (toolTipView.frame.origin.y * 0.2)
        
        } else {
            
            toolTipView.frame.origin.y = toolTipView.frame.origin.y - (toolTipView.frame.origin.y * 0.2)
        }
    
        UIView.animate(withDuration: 0.16, animations: {
            
            self.alpha = alpha
            
            self.webView.alpha = 1
            
            self.toolTipView.frame.origin.y = yPosition
            
        }) { (_) in
            
            UIView.animate(withDuration: 0.2) {
                
                self.jinyIconView.alpha = 1
                
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
