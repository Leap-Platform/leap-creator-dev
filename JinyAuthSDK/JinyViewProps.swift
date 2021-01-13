//
//  JinyViewProps.swift
//  JinyAuthSDK
//
//  Created by Aravind GS on 20/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// global variable 'group' to keep track of recursion completion.
fileprivate let group = DispatchGroup()

class JinyViewBounds:Codable {
    
    var left:Float
    var top:Float
    var right:Float
    var bottom:Float
    
    init(view:UIView) {
        let rect = view.superview?.convert(view.frame, to: nil)
        left = Float(rect?.origin.x ?? 0) * Float(UIScreen.main.scale)
        top = Float(rect?.origin.y ?? 0) * Float(UIScreen.main.scale)
        right = left + Float(view.bounds.size.width * UIScreen.main.scale)
        bottom = top + Float(view.bounds.size.height * UIScreen.main.scale)
    }
}

class JinyViewProps:Codable {
    
    var controller:String?
    var acc_id:String
    var acc_label:String
    var acc_hint:String
    var tag:Int
    var class_name:String
    var node_index:Int
    var bounds:JinyViewBounds
    var placeholder:String?
    var text:String?
    var is_focusable: Bool
    var is_focused: Bool
    var is_selected: Bool
    var is_enabled: Bool
    var is_user_interaction_enabled: Bool
    var is_multiple_touch_enabled: Bool
    var is_exclusive_touch: Bool
    var is_clickable: Bool
    var is_scroll_container: Bool
    var is_webview:Bool
    var location_x_on_screen:Float
    var location_y_on_screen:Float
    var bgColor:Dictionary<String,Int>
    var tintColor:Dictionary<String, Int>?
    var uuid:String?
    var children:Array<JinyViewProps> = []
    var web_children: String?
    var is_ui_webview: Bool = false
    var is_wk_webview: Bool = false
    
    init(view:UIView, finishListener: FinishListener, completion: ((_ success: Bool, _ viewProps: JinyViewProps?) -> Void
    )? = nil) {
        
        group.enter()
        
        acc_id = view.accessibilityIdentifier ?? ""
        acc_label = view.accessibilityLabel ?? ""
        acc_hint = view.accessibilityHint ?? ""
        tag = view.tag
        class_name = String(describing: type(of: view))
        node_index = view.superview?.subviews.firstIndex(of: view) ?? -1
        bounds = JinyViewBounds(view: view)
        is_focusable = view.canBecomeFocused
        is_focused = view.isFocused
        is_selected = (view as? UIControl)?.isSelected ?? false
        is_enabled = (view as? UIControl)?.isEnabled ?? false
        is_user_interaction_enabled = view.isUserInteractionEnabled
        is_multiple_touch_enabled = view.isMultipleTouchEnabled
        is_exclusive_touch = view.isExclusiveTouch
        is_scroll_container = view.isKind(of: UIScrollView.self)
        is_webview = view.isKind(of: UIWebView.self) || view.isKind(of: WKWebView.self)
        uuid = String.generateJinyAuthUUIDString()
        if let control = view as? UIControl {
            let targetActions = control.allTargets.filter{
                control.actions(forTarget: $0, forControlEvent: .touchUpInside)?.count ?? 0 > 0
            }
            is_clickable = targetActions.count > 0
        } else {
            let tapGesture = view.gestureRecognizers?.filter{ $0.isKind(of: UITapGestureRecognizer.self) }
            is_clickable = (tapGesture?.count ?? 0) > 0
        }
        location_x_on_screen = bounds.left
        location_y_on_screen = bounds.top
        bgColor = view.backgroundColor?.getComponentDict() ?? [:]
        if let tint = view.tintColor { tintColor = tint.getComponentDict() }
        else { tintColor = [:] }
        
        
        if let textField  = view as? UITextField {
            placeholder = textField.placeholder
            text = textField.text
        } else if let textView = view as? UITextView {
            text = textView.text
            
        } else if let button = view as? UIButton {
            text = button.currentTitle
        } else if let label = view as? UILabel {
            text = label.text
        }
        if !is_webview {
            var childViews = view.subviews
          
            childViews = childViews.filter{ $0.isHidden == false && $0.alpha > 0 && !String(describing: type(of: view)).contains("Jiny") }
            childViews = childViews.filter{
                guard let superview = $0.superview else { return true }
                let frameToWindow = superview.convert($0.frame, to: UIApplication.shared.keyWindow)
                guard let keyWindow = UIApplication.shared.keyWindow else { return true }
                if frameToWindow.minX > keyWindow.frame.maxX || frameToWindow.maxX < 0 { return false }
                return true
            }
            if view.window == UIApplication.shared.keyWindow {
                let childrenToCheck = getVisibleSiblings(allSiblings: childViews)
                for child in childrenToCheck { children.append(JinyViewProps(view: child, finishListener: finishListener))}
            } else {
                for child in childViews  { children.append(JinyViewProps(view: child, finishListener: finishListener)) }
            }
        } else { children = [] }
        

        var webChildren: String?
        if is_webview {
            var injectionScript = ScreenHelper.layoutInjectionJSScript
            injectionScript = injectionScript.replacingOccurrences(of: "${totalScreenHeight}", with: "\(UIScreen.main.nativeBounds.height)").replacingOccurrences(of: "${totalScreenWidth}", with: "\(UIScreen.main.nativeBounds.width)").replacingOccurrences(of: "${topMargin}", with: "\(location_y_on_screen)").replacingOccurrences(of: "${leftMargin}", with: "\(location_x_on_screen)")
            if let uiweb = view as? UIWebView {
                let res = uiweb.stringByEvaluatingJavaScript(from: injectionScript)
                webChildren = res
                group.leave()
            }
            else if let wk_web = view as? WKWebView {
                wk_web.evaluateJavaScript(injectionScript, completionHandler: { (res, error) in
                    webChildren = res as? String
                    group.leave()
                })
            }
        
        } else { group.leave() }
        
        group.notify(queue: DispatchQueue.main) {
            
            self.web_children = webChildren
            completion?(true, self)
        }
    }
    
    func getVisibleSiblings(allSiblings:Array<UIView>) -> Array<UIView> {
        guard allSiblings.count > 1 else { return allSiblings }
        var visibleViews = allSiblings
        for view in allSiblings.reversed() {
            if !visibleViews.contains(view) { continue }
            let indexOfView =  allSiblings.firstIndex(of: view)
            if indexOfView == nil  { break }
            if indexOfView == 0 { break }
            let viewsToCheck = visibleViews[0..<indexOfView!]
            let hiddenViews = viewsToCheck.filter { view.frame.contains($0.frame) }
            visibleViews = visibleViews.filter { !hiddenViews.contains($0) }
        }
        return visibleViews
    }
    
    func getWebChildren(webview:UIView, jsString: String, completion:@escaping(_:String?)->Void) {
        if let wkweb = webview as? WKWebView {
            wkweb.evaluateJavaScript(jsString) { (res, err) in
                completion(res as? String)
            }
        } else if let uiweb = webview as? UIWebView {
            completion(uiweb.stringByEvaluatingJavaScript(from: jsString))
        }
    }
}


extension String {
    static func generateJinyAuthUUIDString() -> String {
        return "JinyAuthHierarchy\(randomString(8))-\(randomString(4))-\(randomString(4))-\(randomString(4))-\(randomString(12))-\(randomString(8))-\(randomString(4))-\(randomString(4))-\(randomString(4))-\(randomString(12))"
    }
    
    static func authRandomString(_ length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
        let randomString = String((0..<length).map{_ in letters.randomElement()!})
        return randomString
    }
}

extension UIColor {
    
    func getComponentDict() ->Dictionary<String,Int> {
        guard cgColor.components?.count ?? 0 > 2  else { return [:] }
        let rComponent = cgColor.components![0]
        let gComponent = cgColor.components![1]
        let bComponent = cgColor.components![2]
        var colorDict = [constant_r: lroundf(Float(rComponent * 255)), constant_g:  lroundf(Float(gComponent * 255)),  constant_b:lroundf(Float(bComponent * 255))]
        if cgColor.components?.count ?? 0 > 3 {
            let aComponent = cgColor.components![3]
            colorDict[constant_a] =  lroundf(Float(aComponent * 255))
        }
        return colorDict
    }
    
    
    func getLayoutHierarchy(wkWebView: WKWebView, finishListener: FinishListener){
        
    }
    
}
