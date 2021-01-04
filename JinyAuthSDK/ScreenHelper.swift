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
    
    static let layoutInjectionJSScript = "(function (totalScreenHeight, totalScreenWidth, topMargin=0, leftMargin=0) {\n" +
        "    var jinyFetchClientHierarchy = function(root){\n" +
        "        var node = {};\n" +
        "        if(root!==undefined){\n" +
        "            node.uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {\n" +
        "                var dt = new Date().getTime();\n" +
        "                var r = (dt + Math.random()*16)%16 | 0;\n" +
        "                dt = Math.floor(dt/16);\n" +
        "                return (c=='x' ? r :(r&0x3|0x8)).toString(16);\n" +
        "            });\n" +
        "            node.tag = root.tagName.toLowerCase();\n" +
        "            var attributeNames = root.getAttributeNames();\n" +
        "            for(var i=0; i<attributeNames.length; i++){\n" +
        "                node[attributeNames[i]] = root.getAttribute(attributeNames[i]);\n" +
        "            }\n" +
        "            var viewportWidth = screen.width;\n" +
        "            var viewportHeight = screen.height;\n" +
        "            node.bounds = root.getClientRects()[0];\n" +
        "            if(node.bounds!==undefined){\n" +
        "               node.normalised_bounds = {};\n" +
        "               node.normalised_bounds.top = (node.bounds.top*totalScreenHeight)/viewportHeight + topMargin;\n" +
        "               node.normalised_bounds.bottom = (node.bounds.bottom*totalScreenHeight)/viewportHeight + topMargin;\n" +
        "               node.normalised_bounds.left = (node.bounds.left*totalScreenWidth)/viewportWidth + leftMargin;\n" +
        "               node.normalised_bounds.right = (node.bounds.right*totalScreenWidth)/viewportWidth + leftMargin;\n" +
        "            }\n" +
        "            node.innerText = root.innerText;\n" +
        "            node.value = root.value;\n" +
        "            node.children = [];\n" +
        "            var childs = root.children.length;\n" +
        "            if(node.bounds!==undefined){\n" +
        "               for(var child=0;child<childs;child++){\n" +
        "                    node.children.push(jinyFetchClientHierarchy(root.children[child]));\n" +
        "               }\n" +
        "           }\n" +
        "        }\n" +
        "        return node\n" +
        "    }\n" +
        "    var layout = jinyFetchClientHierarchy(document.getElementsByTagName('html')[0])\n" +
        "    return JSON.stringify(layout)\n" +
        "}(${totalScreenHeight},${totalScreenWidth},${topMargin},${leftMargin}));";
    
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

    static func captureHierarchy(finishListener: FinishListener, completion: @escaping (_ dict: Dictionary<String, Any>) -> Void) {
        var hierarchy:Dictionary<String,Any> = [:]
        if let controller = UIApplication.getCurrentTopVC() {
            hierarchy["controller"] = String(describing: type(of: controller.self))
        } else {
            hierarchy["controller"] = ""
        }
        hierarchy["viewport"] = ["width": UIScreen.main.bounds.width, "height": UIScreen.main.bounds.height]
        hierarchy["screen_width"] = UIScreen.main.nativeBounds.width
        hierarchy["screen_height"] = UIScreen.main.nativeBounds.height
        hierarchy["client_package_name"] = Bundle.main.bundleIdentifier
        hierarchy["orientation"] = (UIDevice.current.orientation.isLandscape ? "Landscape": "Portrait")
        _ = JinyViewProps(view: UIApplication.shared.keyWindow!, finishListener: finishListener) { (_, props) in
            do {
                let jsonEncoder = JSONEncoder()
                jsonEncoder.outputFormatting = .prettyPrinted
                let hierarchyData = try jsonEncoder.encode(props)
                let payload = try JSONSerialization.jsonObject(with: hierarchyData, options: .mutableContainers) as? Dictionary<String,Any>
                hierarchy["layout"] = payload
                completion(hierarchy)
            } catch {
                
            }
        }        
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
