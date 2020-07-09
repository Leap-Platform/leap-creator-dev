//
//  JinyAUIUtils.swift
//  JinyAUI
//
//  Created by Aravind GS on 09/07/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    class func getImageFromBundle(_ name:String) -> UIImage? {
        let image = UIImage(named: name, in: Bundle(for: JinyAUIManager.self), compatibleWith: nil)
        return image
    }
}


extension UIApplication {
    
    class func getCurrentVC () -> UIViewController? {
        guard let rootVC = shared.keyWindow?.rootViewController else {
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
