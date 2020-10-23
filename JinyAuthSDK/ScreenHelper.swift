//
//  ScreenHelper.swift
//  JinyAuthSDK
//
//  Created by Shreyansh Sharma on 23/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

class ScreenHelper {
    static func captureScreenshot() -> UIImage? {
        let imageSize = UIScreen.main.bounds.size
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        let context = UIGraphicsGetCurrentContext()
        guard let currentContext = context else { return nil }
        // Iterate over every window from back to front
        
        for window in UIApplication.shared.windows {
            if window.screen != UIScreen.main { continue }
            currentContext.saveGState()
            currentContext.translateBy(x: window.center.x, y: window.center.y)
            currentContext.concatenate(window.transform)
            currentContext.translateBy(x: -window.bounds.size.width * window.layer.anchorPoint.x, y: -window.bounds.size.height * window.layer.anchorPoint.y)
            window.layer.render(in: currentContext)
            currentContext.restoreGState()
        }
        
        guard let finalImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        guard let finalCgImage = finalImage.cgImage else { return finalImage }
        let smallImage = UIImage(cgImage: finalCgImage, scale: 2.0, orientation: finalImage.imageOrientation)
        return smallImage
    }

    static func captureHierarchy() -> Dictionary<String,Any> {
        var hierarchy:Dictionary<String,Any> = [:]
        hierarchy["screen_width"] = UIScreen.main.bounds.width
        hierarchy["screen_height"] = UIScreen.main.bounds.height
        hierarchy["client_package_name"] = Bundle.main.bundleIdentifier
        hierarchy["orientation"] = (UIDevice.current.orientation.isLandscape ? "Landscape": "Portrait")
        let layout = JinyViewProps(view: UIApplication.shared.keyWindow!)
        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .prettyPrinted
            let hierarchyData = try jsonEncoder.encode(layout)
            let payload = try JSONSerialization.jsonObject(with: hierarchyData, options: .mutableContainers) as? Dictionary<String,Any>
            hierarchy["layout"] = payload
        } catch {
            
        }
        return hierarchy
    }

}
