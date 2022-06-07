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
    
    static let layoutInjectionJSScript = "(function (webviewScale, totalScreenHeight, totalScreenWidth, topMargin=0, leftMargin=0) {\n" +
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
        "               node.normalised_bounds.top = (node.bounds.top*totalScreenHeight * webviewScale)/viewportHeight + topMargin;\n" +
        "               node.normalised_bounds.bottom = (node.bounds.bottom*totalScreenHeight * webviewScale)/viewportHeight + topMargin;\n" +
        "               node.normalised_bounds.left = (node.bounds.left*totalScreenWidth * webviewScale)/viewportWidth + leftMargin;\n" +
        "               node.normalised_bounds.right = (node.bounds.right*totalScreenWidth * webviewScale)/viewportWidth + leftMargin;\n" +
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
        "}(${webviewScale},${totalScreenHeight},${totalScreenWidth},${topMargin},${leftMargin}));";
    
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
        hierarchy[constant_screen_width] = UIScreen.main.bounds.width * UIScreen.main.scale
        hierarchy[constant_screen_height] = UIScreen.main.bounds.height * UIScreen.main.scale
        hierarchy[constant_deviceType] = UIDevice.current.userInterfaceIdiom == .pad ? constant_TABLET : constant_PHONE
        hierarchy[constant_client_package_name] = Bundle.main.bundleIdentifier
        hierarchy[constant_orientation] = (UIDevice.current.orientation.isLandscape ? constant_Landscape : constant_Portrait)
        let windowsToCheck = getWindowsToCheck()
        if windowsToCheck.count > 1 {
            let hierarchyGroup = DispatchGroup()
            var windowsViewProps:Array<Dictionary<String,Any>> = []
            for window in windowsToCheck {
                hierarchyGroup.enter()
                getViewProps(forWindow: window, finishListener: finishListener) { props in
                    if !props.isEmpty { windowsViewProps.append(props) }
                    hierarchyGroup.leave()
                }
            }
            hierarchyGroup.notify(queue: .main) {
                let payload = generateDummyWindow(windowsViewProps)
                hierarchy[constant_layout] = payload
                completion(hierarchy)
            }
        } else {
            guard let liveWindow = windowsToCheck.first else{
                hierarchy[constant_layout] = [:]
                completion(hierarchy)
                return
            }
            getViewProps(forWindow: liveWindow, finishListener: finishListener) { props in
                hierarchy[constant_layout] = props
                completion(hierarchy)
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
        for _ in 0...300 {
            parcel.append(UUID.init().uuidString)
        }
        return parcel
    }
    
    static func speedCheckUploadingPacket(success:@escaping (_ packetSize: Float, _ timeTaken: Float)->Void, failure:@escaping ()->Void) {
        let currentTimeBeforeMakingRequest : Int = Int(Date().timeIntervalSince1970) * 1000
        
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

extension LeapScreenHelper {
    
    static func getWindowsToCheck() -> Array<UIWindow> {
        var windowsToCheck = UIApplication.shared.windows.filter { window in
            if String(describing: type(of: window.self)) == "UITextEffectsWindow" { return false }
            if window.isHidden { return false }
            return true
        }
        let remoteWindow = windowsToCheck.first { String(describing: type(of: $0.self)) == "UIRemoteKeyboardWindow" }
        if let remoteWindow = remoteWindow, let datePicker = getTopDatePicker(inView: remoteWindow) {
            if #available(iOS 14.0, *) {
                if datePicker.datePickerStyle == .inline {
                    windowsToCheck = windowsToCheck.filter{ $0 == remoteWindow}
                }
            }
        }
        return windowsToCheck
    }
    
    static func generateDummyWindow(_ forWindows:Array<Dictionary<String,Any>>) -> Dictionary<String,Any> {
        let payload:Dictionary<String,Any>  = [
            "children" : forWindows,
            "node_index" : -2,
            "class" : "UIWindow",
            "bounds":[
                "left" : 0,
                "top" : 0,
                "right" : UIScreen.main.bounds.width * UIScreen.main.scale,
                "bottom" : UIScreen.main.bounds.height * UIScreen.main.scale
            ],
            "location_x_on_screen" : 0,
            "uuid":String.generateLeapCreatorUUIDString()
        ]
        return payload
    }
    
    static func getViewProps(forWindow:UIWindow, finishListener:LeapFinishListener, fetchedProps:@escaping(_:Dictionary<String,Any>)->Void) {
        
        _ = LeapViewProps(view: forWindow, finishListener: finishListener, completion: { _, props in
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .prettyPrinted
            guard let hierarchyData = try? jsonEncoder.encode(props),
                  let payload = try? JSONSerialization.jsonObject(with: hierarchyData, options: .mutableContainers) as? Dictionary<String,Any> else {
                fetchedProps([:])
                return
            }
            fetchedProps(payload)
        })
    }
    
    static func getTopDatePicker(inView:UIView) -> UIDatePicker? {
        if inView.isKind(of: UIDatePicker.self) { return (inView as! UIDatePicker) }
        for child in inView.subviews.reversed() {
            if let datePicker = getTopDatePicker(inView: child) { return datePicker }
        }
        return nil
    }
    
}
