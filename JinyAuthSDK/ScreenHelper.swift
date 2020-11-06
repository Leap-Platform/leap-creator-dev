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
    
    static let layoutInjectionJSScript = "(function () {\r\n    var jinyFetchClientHierarchy = function(root){\r\n        var node = {};\r\n        if(root!==undefined){\r\n            node.uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {\r\n                var dt = new Date().getTime();\r\n                var r = (dt + Math.random()*16)%16 | 0;\r\n                dt = Math.floor(dt/16);\r\n                return (c=='x' ? r :(r&0x3|0x8)).toString(16);\r\n            });\r\n            node.tag = root.tagName.toLowerCase();\r\n            var attributeNames = root.getAttributeNames();\r\n            node.attributes = {};\r\n            for(var i=0; i<attributeNames.length; i++){\r\n                node.attributes[attributeNames[i]] = root.getAttribute(attributeNames[i]);\r\n            }\r\n            node.bounds = root.getClientRects()[0];\r\n           node.innerText = root.innerText;\r\n            node.value = root.value;\r\n             node.children = [];\r\n            var childs = root.children.length;\r\n            for(var child=0;child<childs;child++){\r\n                node.children.push(jinyFetchClientHierarchy(root.children[child]));\r\n            }\r\n        }\r\n        return node\r\n    }\r\n    var layout = jinyFetchClientHierarchy(document.getElementsByTagName('html')[0])\r\n    return JSON.stringify(layout)\r\n}())"
    
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

    static func captureHierarchy(finishListener: FinishListener) -> Dictionary<String,Any> {
        var hierarchy:Dictionary<String,Any> = [:]
        hierarchy["screen_width"] = UIScreen.main.bounds.width
        hierarchy["screen_height"] = UIScreen.main.bounds.height
        hierarchy["client_package_name"] = Bundle.main.bundleIdentifier
        hierarchy["orientation"] = (UIDevice.current.orientation.isLandscape ? "Landscape": "Portrait")
        let layout = JinyViewProps(view: UIApplication.shared.keyWindow!, finishListener: finishListener)
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

    static func jsonToString(json: AnyObject) -> String{
        do {
            let data1 =  try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted) // first of all convert json to the data
            let convertedString = String(data: data1, encoding: String.Encoding.utf8) // the data will be converted to the string
            return (convertedString)!
        } catch let myJSONError {
            print(myJSONError)
            return "nil"
        }
    }
}
