//
//  LeapKeyWindowAssist.swift
//  LeapAUI
//
//  Created by mac on 02/09/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// A super class for the LeapKeyWindowAssist AUI Components.
class LeapKeyWindowAssist: LeapWebAssist {
    
    /// type of the flow, the AUI is assigned
    enum AUIFlowType: String {
        case singleFlow
        case multiFlow
    }
    
    /// height constraint to increase the constant when html resizes
    var heightConstraint: NSLayoutConstraint?
    
    /// width constraint to increase the constant when orientation of device changes.
    var widthConstraint: NSLayoutConstraint?
    
    /// source view of the AUIComponent that is relatively positioned.
    weak var inView: UIView?
    
    /// property to know the flow type
    var flowType: AUIFlowType = .singleFlow
    
    /// dictionary that has info about the completed flows
    var flowMenuDict = [String : Any]()
    
    /// - Parameters:
    ///   - assistDict: A dictionary value for the type LeapAssistInfo.
    ///   - iconDict: A dictionary for the type LeapIconInfo.
    ///   - baseUrl: base url of the type string.
    init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, baseUrl: String?) {
        super.init(frame: CGRect.zero, baseUrl: baseUrl)
        
        self.assistInfo = LeapAssistInfo(withDict: assistDict)
        
        guard let iconDict = iconDict else {
            
            return
        }
        
        self.iconInfo = LeapIconInfo(withDict: iconDict)
    }
    
    required init?(coder: NSCoder) {        
        fatalError("init(coder:) has not been implemented")
    }
    
    /// - Parameters:
    ///   - assistDict: A dictionary value for the type LeapAssistInfo.
    ///   - iconDict: A dictionary for the type LeapIconInfo.
    ///   - baseUrl: base url of the type string.
    ///   - flowMenuDict: A dictionary to have completed flows info.
    ///   - flowType: type of the flow.
    convenience init(withDict assistDict: Dictionary<String, Any>, iconDict: Dictionary<String, Any>? = nil, baseUrl: String?, flowMenuDict: [String : Any] = [:], flowType: AUIFlowType) {
        self.init(withDict: assistDict, iconDict: iconDict, baseUrl:baseUrl)
        self.flowType = flowType
        self.flowMenuDict = flowMenuDict
    }
    
    /// Method to configure constraints for the overlay view
    func configureOverlayView() {
        
        guard let superView = self.superview else {
            
            return
        }
                        
        // Setting Constraints to self
        
        self.translatesAutoresizingMaskIntoConstraints = false

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: superView, attribute: .centerX, multiplier: 1, constant: 0))

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: superView, attribute: .centerY, multiplier: 1, constant: 0))

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: superView, attribute: .width, multiplier: 1, constant: 0))

        superView.addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: superView, attribute: .height, multiplier: 1, constant: 0))
        
        // Overlay View to be semi transparent black

        if let colorString = self.assistInfo?.layoutInfo?.style.bgColor {
        
          self.backgroundColor = UIColor.init(hex: colorString) ?? UIColor.black.withAlphaComponent(0.65)
        
        } else {
            
          self.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        }
        
        if let highlightAnchor = self.assistInfo?.highlightAnchor, !highlightAnchor {
            
            self.backgroundColor = .clear
        }
        
        self.isHidden = true
        
        self.elevate(with: CGFloat(assistInfo?.layoutInfo?.style.elevation ?? 0))
        
        self.addSubview(webView)
    }
    
    /// Method to configure WebView
    func configureWebView() {
                
        // Setting Corner Radius to curve at the corners
        
        switch assistInfo?.layoutInfo?.layoutAlignment {
        
        case LeapAlignmentType.left.rawValue:
                        
            if #available(iOS 11.0, *) {
                webView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            } else {
                // Fallback on earlier versions
            }
            
        case LeapAlignmentType.right.rawValue:
            
            if #available(iOS 11.0, *) {
                webView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            } else {
                // Fallback on earlier versions
            }
            
        case LeapAlignmentType.bottom.rawValue:
            
            if #available(iOS 11.0, *) {
                webView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            } else {
                // Fallback on earlier versions
            }
            
        default:

            if #available(iOS 11.0, *) {
                webView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            } else {
                // Fallback on earlier versions
            }
        }
        
        webView.clipsToBounds = true
        webView.layer.cornerRadius = CGFloat(self.assistInfo?.layoutInfo?.style.cornerRadius ?? 0)
    }
    
    /// A method to initialise flowMenu with language, completed and uncompleted flows
    func initFlowMenu() {
        let flowMenuDictStringified = dictionaryToStringifiedJson(dictionary: self.flowMenuDict)
        webView.evaluateJavaScript("initFlowMenu('\(flowMenuDictStringified)')", completionHandler: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if assistInfo?.layoutInfo?.dismissAction.outsideDismiss ?? false {
            performExitAnimation(animation: assistInfo?.layoutInfo?.exitAnimation ?? "fade_out", byUser: true, autoDismissed: false, byContext: false, panelOpen: false, action: [constant_body: [constant_close: true]])
        }
    }
    
    /// - Parameters:
    ///   - dictionary: A dictionary that needs to be stringified.
    func dictionaryToStringifiedJson(dictionary: [String : Any]) -> String {
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            return String(data: data, encoding: String.Encoding.utf8) ?? ""
        } catch {
            return ""
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        let hitTestView = super.hitTest(point, with: event)
        
        guard self.isKind(of: LeapPing.self) else { return hitTestView }
        
        if self.webView.frame.contains(point) {
            
            return hitTestView
            
        } else {
            
            /// To make tap pass through transparent view which is self in this case. Context is when there is no overlay.
            if !(assistInfo?.highlightAnchor ?? false) && hitTestView == self {
                
                return nil
            }
            
            return hitTestView
        }
    }
}
