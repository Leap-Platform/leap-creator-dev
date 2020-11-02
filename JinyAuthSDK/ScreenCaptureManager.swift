//
//  ScreenCaptureManager.swift
//  JinyAuthSDK
//
//  Created by Shreyansh Sharma on 22/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import Starscream

class ScreenCaptureManager: AppStateProtocol{
    
    func onApplicationInForeground() {
        
    }
    
    func onApplicationInBackground() {
        
    }
    
    func onApplicationInTermination() {
        
    }
    
    
    var applicationInstance: UIApplication
    var roomId: String?
    var socket: WebSocket?
    var task: DispatchWorkItem?
    
    init(){
        self.applicationInstance = UIApplication.shared
    }
    
    func capture(webSocket: WebSocket, room: String)->Void{
        self.socket = webSocket
        self.roomId = room
        let screenShotImage = getScreenCapture()
        if screenShotImage == nil {
            return
        }
        let hierarchy = getHierarchy()
        
        if hierarchy == nil {
            return
        }
        sendData(screenCapture: screenShotImage!,hierarchy: hierarchy)
    }
    
    func sendData(screenCapture: String, hierarchy: Dictionary<String, Any>)->Void{
        var payload : Dictionary<String, Any> = Dictionary<String, Any>()
        
        payload["image"] = screenCapture
        payload["hierarchy"] = hierarchy
        
        self.task = DispatchWorkItem {
            self.postMessage(payload: payload)
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0, execute: self.task!)
        
    }
    
    func postMessage(payload: Dictionary<String, Any>)->Void{
        let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
        
        let payloadString = String(data: payloadData!, encoding: .utf8)
        let splittedString = payloadString!.components(withMaxLength: 10000)
        let length = splittedString.count
        let room = self.roomId as String?
        var index: Int = -1
        for sub in splittedString {
            index += 1
            let end = (splittedString.last == sub) ? "true" : "false"
            guard let roomId = room else {
                return
            }
            
            let trimString = sub.replacingOccurrences(of: "\n", with: "")
            
            let message: Dictionary<String, Any> = [
                "dataPacket":trimString,
                "commandType":"SCREENSHOT",
                "end":end,
                "index":index,
                "total":length
            ]
            
            let splitPayload: Dictionary<String, Any> = [
                "room":roomId,
                "message": message,
                "action":"message",
                "source":"android"
            ]
            
            
            guard let splitData = try? JSONSerialization.data(withJSONObject: splitPayload, options: .prettyPrinted),
                  let splitString = String(data: splitData, encoding: .utf8) else {
                return
            }
                        
            self.socket?.write(string: splitString, completion: {
                if end == "true"{
                    //  print("Captured payload End :: \(end)")
                }
            })
        }
    }
    
    func getScreenCapture()->String?{
        let image: UIImage = ScreenHelper.captureScreenshot()!
        let encodedImageBase64: String? = image.jpegData(compressionQuality: 0.3)?.base64EncodedString()
        return encodedImageBase64
    }
    
    func getHierarchy()->Dictionary<String, Any>{
        var hierarchyObj = ScreenHelper.captureHierarchy()
        return hierarchyObj
    }
}

