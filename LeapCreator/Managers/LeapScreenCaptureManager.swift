//
//  LeapScreenCaptureManager.swift
//  LeapCreator
//
//  Created by Shreyansh Sharma on 22/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

class LeapScreenCaptureManager: LeapAppStateProtocol{
    
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
    var optimisedTask: DispatchWorkItem?
    weak var completeListener: LeapFinishListener?
    
    init(completeHierarchyFinishListener: LeapFinishListener){
        self.applicationInstance = UIApplication.shared
        self.completeListener = completeHierarchyFinishListener
    }
    
    func capture(webSocket: WebSocket, room: String) {
        self.socket = webSocket
        self.roomId = room
        guard let screenShotImage = getScreenCapture(compressionQuality: 0.3) else { return }
        guard let completeListener = self.completeListener else { return }
        getHierarchy(finishListener: completeListener) { [weak self] (hierarchy) in
            self?.sendData(screenCapture: screenShotImage,hierarchy: hierarchy)
        }
    }
    
    func sendData(screenCapture: String, hierarchy: Dictionary<String, Any>)->Void{
        var payload : Dictionary<String, Any> = Dictionary<String, Any>()
        
        payload[constant_image] = screenCapture
        payload[constant_hierarchy] = hierarchy
        
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted) else { return }
        guard let payloadString = String(data: payloadData, encoding: .utf8) else { return }
        
        // Check the payload size
        let originalPayloadSize: Float = Float(Float(payloadString.count) / 1024)
        
        self.optimisedTask = DispatchWorkItem {
            
            LeapScreenHelper.speedCheckUploadingPacket { (packetSize, timeTaken) in
                
                DispatchQueue.main.async {
                    // Check speed and manipulate quality
                    let internetSpeed = packetSize / timeTaken
                    let originalPayloadTimeRequired = originalPayloadSize / internetSpeed
                    
                    //if original payload sending time > dashboard timeout then we need to
                    // reduce quality of image thereby increasing compression
                    // 0(most compressed)(low quality) ..... 1(least compressed)(best quality)
                    
                    if (originalPayloadTimeRequired > 55 - timeTaken) {
                        let modifiedScreenshotQuality = Float((0.5 * (Double(55 - timeTaken))/Double(originalPayloadTimeRequired)))
                        
                        guard let screenShotImage = self.getScreenCapture(compressionQuality: modifiedScreenshotQuality) else {
                            
                            self.sendScreenPayload(completePayload: payloadString)
                            return
                        }
                        
                        payload[constant_image] = screenShotImage
                        
                        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted) else { return }
                        guard let payloadString = String(data: payloadData, encoding: .utf8) else { return }
                        
                        self.sendScreenPayload(completePayload: payloadString)
                        
                    } else {
                        
                        self.sendScreenPayload(completePayload: payloadString)
                    }
                }
                
            } failure: {
                self.sendScreenPayload(completePayload: payloadString)
            }
        }
        guard let optimisedTask = self.optimisedTask else { return }
        DispatchQueue.global().async(execute: optimisedTask)
    }
    
    func sendScreenPayload(completePayload: String){
        self.task = DispatchWorkItem {
            self.postMessage(payload: completePayload)
        }
        guard let task = self.task else { return }
        DispatchQueue.global().async(execute: task)
    }
    
    func postMessage(payload: String) {
        
        let splittedString = payload.components(withMaxLength: 10000)
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
                    print("Captured payload End :: \(end)")
                    self.stop()
                }
            })
        }
    }
    
    func getScreenCapture(compressionQuality: Float) ->String? {
        guard let image: UIImage = LeapScreenHelper.captureScreenshot() else { return nil }
        let encodedImageBase64: String? = image.jpegData(compressionQuality: CGFloat(compressionQuality))?.base64EncodedString()
        return encodedImageBase64
    }
    
    func getHierarchy(finishListener: LeapFinishListener, completion: @escaping (_ dict: Dictionary<String, Any>) -> Void) {
        LeapScreenHelper.captureHierarchy(finishListener: finishListener) { (dict) in
            completion(dict)
        }
    }
    
    func stop() {
        task?.cancel()
        optimisedTask?.cancel()
    }
}

protocol LeapFinishListener: AnyObject {
    func onCompleteHierarchyFetch()
}
