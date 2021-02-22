//
//  LeapUtils.swift
//  LeapCore
//
//  Created by Aravind GS on 26/03/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    
    class func getCurrentVC () -> UIViewController? {
        let keyWindow = shared.windows.first{ $0.isKeyWindow }
        guard let rootVC = keyWindow?.rootViewController else {
               return nil
        }
        return UIApplication.findBestViewController(rootVC)
    }
    
    class func findBestViewController(_ parentVC:UIViewController) -> UIViewController {
        if let navVC = parentVC as? UINavigationController {
            if let visibleVC = navVC.visibleViewController  {
                return findBestViewController(visibleVC)
            }
        }
        if let tabVC = parentVC as? UITabBarController {
            if let visibleVC = tabVC.selectedViewController {
                return findBestViewController(visibleVC)
            }
        }
        if let presented = parentVC.presentedViewController {
            return findBestViewController(presented)
        }
        let childVCs = parentVC.children
        if childVCs.count > 0 {
            if let lastChild = childVCs.last {
                return findBestViewController(lastChild)
            }
        }
        return parentVC
    }
}




extension String {
    
    static func generateUUIDString() -> String {
        return "\(randomString(8))-\(randomString(4))-\(randomString(4))-\(randomString(4))-\(randomString(12))LEAP\(randomString(8))-\(randomString(4))-\(randomString(4))-\(randomString(4))-\(randomString(12))"
    }
    
    static func randomString(_ length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
        let randomString = String((0..<length).map{_ in letters.randomElement()!})
        return randomString
    }

    func toDate(withFormat format: String = "yyyy-MM-dd HH:mm:ss.SSS")-> Date?{

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tehran")
        dateFormatter.locale = Locale(identifier: "fa-IR")
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = format
        let date = dateFormatter.date(from: self)

        return date

    }
    
}


extension Date {
    static func getTimeStamp() -> String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let dateString = formatter.string(from: now)
        return dateString
    }
}


