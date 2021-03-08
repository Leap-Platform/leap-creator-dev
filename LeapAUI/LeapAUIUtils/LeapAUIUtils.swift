//
//  LeapAUIUtils.swift
//  LeapAUI
//
//  Created by Aravind GS on 09/07/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

extension UIImage {
    class func getImageFromBundle(_ name:String) -> UIImage? {
        let image = UIImage(named: name, in: Bundle(for: LeapAUIManager.self), compatibleWith: nil)
        return image
    }
    
    func getInvertedImage() -> UIImage {
        let rect =  CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        //Create a bitmap based graphics context based on size
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 1)
        let currentContext = UIGraphicsGetCurrentContext() //Get current Quartz 2d drawing environment
        currentContext?.clip(to: rect)
        currentContext?.draw(self.cgImage!, in: rect)
          
        // Inverted image
        let drawImage = UIGraphicsGetImageFromCurrentImageContext()
        let invertedImage = UIImage(cgImage: (drawImage?.cgImage!)!, scale: self.scale, orientation: self.imageOrientation)
        return invertedImage
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

extension WKWebView {
    
    /// Do not depend on this method unless you are using Unicode or UTF-8 (Apple Documentation)
    /// - Parameters:
    ///   - url: A url of type URL to load html content.
    func loadHTML(withUrl url : URL) {
        
       DispatchQueue.global().async {
          do {
             let htmlString = try String(contentsOf: url)  // Method description refers to this
             DispatchQueue.main.async {
               self.loadHTMLString(htmlString, baseURL: url)
             }
          } catch let error {
             print(error)
          }
       }
    }
}
