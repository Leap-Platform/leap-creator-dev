//
//  LeapTopViewController.swift
//  LeapCreator
//
//  Created by Shreyansh Sharma on 21/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit



extension UIViewController {
    func topMostViewController() -> UIViewController? {
        if self.presentedViewController == nil {
            return self
        }
        if let navigation = self.presentedViewController as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController()
        }
        if let tab = self.presentedViewController as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }
        return self.presentedViewController?.topMostViewController()
    }
    
    func showToast(message : String, font: UIFont = UIFont.boldSystemFont(ofSize: 17), color: UIColor) {
        
        let width = (self.view.frame.width * 80) / 100
        let height = 35

        let toastLabel = UILabel(frame: CGRect(x: Int(self.view.center.x) - Int(width)/2, y: Int(self.view.frame.size.height)-100, width: Int(width), height: height))
        toastLabel.backgroundColor = color
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds  =  true
        toastLabel.adjustsFontSizeToFitWidth = true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 1.0, delay: 2, options: .curveEaseOut, animations: {
             toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}

extension UIApplication {
    func topMostViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.first{ $0.isKeyWindow }
        return keyWindow?.rootViewController?.topMostViewController()
    }
    
    class func getCurrentTopVC () -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.first{ $0.isKeyWindow }
        guard let rootVC = keyWindow?.rootViewController else {
               return nil
           }
        return UIApplication.findBestViewController(rootVC)
    }

    class func findTopViewController(_ parentVC:UIViewController) -> UIViewController {
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
