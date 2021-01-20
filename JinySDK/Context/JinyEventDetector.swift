//
//  JinyEventDetector.swift
//  JinySDK
//
//  Created by Aravind GS on 26/08/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

fileprivate var isSwizzled = false

protocol JinyEventDetectorDelegate {
    func clickDetected(view:UIView?, point:CGPoint)
}

class JinyEventDetector {
    
    static let shared = JinyEventDetector()
    
    var delegate:JinyEventDetectorDelegate?
    
    func eventReceived (event:UIEvent) {
        guard event.type == .touches else { return }
        guard let touch = event.allTouches?.first else { return }
        guard let touchWindow = touch.window else { return }
        let windowClass = String(describing: type(of: touchWindow))
        if windowClass == "UIRemoteKeyboardWindow" { return }
        guard touch.phase == .ended else { return }
        let touchLocationInView = touch.location(in: nil)
        self.delegate?.clickDetected(view: touch.view, point: touchLocationInView)
    }
    
}

//extension UIWindow {
//    public func swizzle() {
//        if (isSwizzled) { return }
//        let sendEvent = class_getInstanceMethod(object_getClass(self), #selector(UIApplication.sendEvent(_:)))
//        let swizzledSendEvent = class_getInstanceMethod(object_getClass(self), #selector(UIWindow.swizzledSendEvent(_:)))
//        method_exchangeImplementations(sendEvent!, swizzledSendEvent!)
//        isSwizzled = true
//    }
//    
//    @objc public func swizzledSendEvent(_ event: UIEvent) {
//        JinyEventDetector.shared.eventReceived(event: event)
//        swizzledSendEvent(event)
//    }
//}
