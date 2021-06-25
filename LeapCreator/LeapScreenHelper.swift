//
//  LeapScreenHelper.swift
//  LeapCreator
//
//  Created by Shreyansh Sharma on 23/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

class LeapScreenHelper {
    
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
        "            for(var child=0;child<childs;child++){\n" +
        "               node.children.push(jinyFetchClientHierarchy(root.children[child]));\n" +
        "            }\n" +
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

    static func captureHierarchy(finishListener: LeapFinishListener, completion: @escaping (_ dict: Dictionary<String, Any>) -> Void) {
        var hierarchy:Dictionary<String,Any> = [:]
        if let controller = UIApplication.getCurrentTopVC() {
            hierarchy[constant_controller] = String(describing: type(of: controller.self))
        } else {
            hierarchy[constant_controller] = ""
        }
        hierarchy[constant_viewport] = [constant_width: UIScreen.main.bounds.width, constant_height: UIScreen.main.bounds.height]
        hierarchy[constant_screen_width] = UIScreen.main.nativeBounds.width
        hierarchy[constant_screen_height] = UIScreen.main.nativeBounds.height
        hierarchy[constant_client_package_name] = Bundle.main.bundleIdentifier
        hierarchy[constant_orientation] = (UIDevice.current.orientation.isLandscape ? "Landscape": "Portrait")
        guard let keyWindow = (UIApplication.shared.windows.first{ $0.isKeyWindow }) else { return }
        _ = LeapViewProps(view: keyWindow, finishListener: finishListener) { (_, props) in
            do {
                let jsonEncoder = JSONEncoder()
                jsonEncoder.outputFormatting = .prettyPrinted
                let hierarchyData = try jsonEncoder.encode(props)
                let payload = try JSONSerialization.jsonObject(with: hierarchyData, options: .mutableContainers) as? Dictionary<String,Any>
                hierarchy[constant_layout] = payload
                completion(hierarchy)
            } catch {
                
            }
        }        
    }

    static func jsonToString(json: AnyObject) -> String? {
        do {
            let data1 =  try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted) // first of all convert json to the data
            let convertedString = String(data: data1, encoding: String.Encoding.utf8) // the data will be converted to the string
            return convertedString
        } catch let myJSONError {
            print(myJSONError)
            return "nil"
        }
    }
    
    
    static func getSamplePayload()->String{
        var parcel:String = UUID.init().uuidString
        for index in 0...300 {
            parcel.append(UUID.init().uuidString)
        }
        return parcel
    }
    
    static func speedCheckUploadingPacket(success:@escaping (_ packetSize: Float, _ timeTaken: Float)->Void, failure:@escaping ()->Void) {
        var currentTimeBeforeMakingRequest : Int = Int(Date().timeIntervalSince1970) * 1000
        
        guard let url = URL(string: LeapCreatorShared.shared.ALFRED_URL+LeapCreatorShared.shared.CREATOR_DEVICE_SPEEDCHECK_API) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        guard let apiKey = LeapCreatorShared.shared.apiKey else {
            failure()
            return
        }
        
        request.addValue(apiKey, forHTTPHeaderField: "x-auth-id")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let requestBody: String = getSamplePayload()
        request.httpBody = requestBody.data(using: .utf8)

         URLSession.shared.dataTask(with: request) { (data, response, error) in

            if let httpResponse = response as? HTTPURLResponse {
                let status = httpResponse.statusCode
                switch status {
                case 200:
                    guard let resultData = data,
                          let responseData = try? JSONSerialization.jsonObject(with: resultData, options:.mutableLeaves) as? Dictionary<String, String>,
                          let timeStampString = responseData["requestTimeStamp"],
                          let timeStamp = Int(timeStampString) else {
                     
                        failure()
                        return
                    }
                    let totalTimeStamp = Float(timeStamp - currentTimeBeforeMakingRequest)/1000.0
                    let packetSize:Float = Float(requestBody.count / 1024)
                    success(packetSize, totalTimeStamp)
                    break
                default: break
                }

            }

         }.resume()
        }
        
      
}
    
