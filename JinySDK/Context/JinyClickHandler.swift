//
//  JinyClickHandler.swift
//  JinySDK
//
//  Created by Aravind GS on 19/01/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation
import WebKit

fileprivate var isSwizzled = false

class WeakView {
    weak var view:UIView?
    init(withView:UIView) { view = withView }
}

protocol JinyClickHandlerDelegate:NSObjectProtocol {
    
    func nativeClickEventForContext(id:Int, onView:UIView)
    func webClickEventForContext(id:Int)
    
}

fileprivate let jinyClickListener = "jinyClickListener"

class JinyClickHandler:NSObject {
    
    static let shared = JinyClickHandler()
    weak var delegate:JinyClickHandlerDelegate?
    var viewsToObserve:Array<(Int, WeakView)> = []
    
    override init() {
        super.init()
        UIApplication.shared.keyWindow?.swizzle()
    }
    
    func addClickListeners(_ nativeElements:Array<(Int, UIView)>) {
        viewsToObserve = nativeElements.map({ (contextId, view) -> (Int,WeakView) in
            return (contextId, WeakView(withView: view))
        })
    }
    
    func addClickListener(to webElements:Dictionary<WKWebView, Array<Dictionary<String,Any>>>) {
        webElements.forEach { (webview, elementsToObserve) in
            webview.configuration.userContentController.removeScriptMessageHandler(forName: jinyClickListener)
            webview.configuration.userContentController.add(self, name: jinyClickListener)
            for element in elementsToObserve {
                guard let webIdentifier = element["identifier"] as? JinyWebIdentifier,
                      let contextId = element["id"] as? Int else { continue }
                let basicElementJs = JinyJSMaker.generateBasicElementScript(id: webIdentifier)
                let dictString = "{\"contextId\":\(contextId)}"
                let script = """
                    var element = \(basicElementJs);
                    try { element.removeEventListener("click",clickFunction_\(contextId)); } catch(e){ }
                    clickFunction_\(contextId) =  function(){ window.webkit.messageHandlers.jinyClickListener.postMessage('\(dictString)'); };
                    element.addEventListener('click', clickFunction_\(contextId));
                """
                webview.evaluateJavaScript(script,completionHandler: nil)
            }
        }
    }
    
    func removeAllClickListeners() {
        viewsToObserve = []
    }
    
    @objc public func nativeClickReceived(_ event:UIEvent) {
        guard event.type == .touches else { return }
        guard let touch = event.allTouches?.first,
              let touchWindow = touch.window,
              touch.phase == .ended else { return }
        let windowClass = String(describing: type(of: touchWindow))
        if windowClass == "UIRemoteKeyboardWindow" { return }
        let location = touch.location(in: nil)
        let contextIdentified = viewsToObserve.first { (contextId, weakView) -> Bool in
            guard let view = weakView.view else { return false }
            guard let viewFrame = view.superview?.convert(view.frame, to: nil) else { return false }
            return viewFrame.contains(location)
        }
        guard let contextFound = contextIdentified else { return }
        delegate?.nativeClickEventForContext(id: contextFound.0, onView: contextFound.1.view!)
    }
}


extension JinyClickHandler:WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? String,
              let bodyData = body.data(using: .utf8),
              let bodyJson = try? JSONSerialization.jsonObject(with: bodyData, options: .allowFragments) as? Dictionary<String,Int> ,
              let contextId = bodyJson["contextId"] else { return }
        self.delegate?.webClickEventForContext(id: contextId)
    }
    
}

extension UIWindow {
    public func swizzle() {
        if (isSwizzled) { return }
        let sendEvent = class_getInstanceMethod(object_getClass(self), #selector(UIApplication.sendEvent(_:)))
        let swizzledSendEvent = class_getInstanceMethod(object_getClass(self), #selector(UIWindow.swizzledSendEvent(_:)))
        method_exchangeImplementations(sendEvent!, swizzledSendEvent!)
        isSwizzled = true
    }
    
    @objc public func swizzledSendEvent(_ event: UIEvent) {
        swizzledSendEvent(event)
        JinyClickHandler.shared.nativeClickReceived(event)
    }
}
