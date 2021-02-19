//
//  LeapDeviceManager.swift
//  LeapCreator
//
//  Created by Shreyansh Sharma on 16/12/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import Starscream

class LeapDeviceManager {
    
    var roomId: String?
    var webSocket: WebSocket?
    
    init(){
        
    }
    
    func sendInfo(webSocket: WebSocket, room: String)-> Void{
        self.webSocket = webSocket
        let devicePayloadString = getDeviceInfo()
        
        let message: Dictionary<String, Any> = [
            "dataPacket": devicePayloadString,
            "commandType":"DEVICE_INFO",
            "end":true
        ]
        //TODO: source needs to be changed to ios
        let splitPayload: Dictionary<String, Any> = [
            "room": room ,
            "message": message,
            "action":"message",
            "source":"android"
        ]
        
        guard let payload = try? JSONSerialization.data(withJSONObject: splitPayload, options: .prettyPrinted),
              let splitString = String(data: payload, encoding: .utf8) else {
            return
        }
        
        self.webSocket?.write(string: splitString, completion: {
            print("DeviceInfo has been sent! ")
        })
    }
    
    //TODO: Add proper method to fetch Device info correctly 
    private func getDeviceInfo()->String{
        return "DEVICE_INFO"
    }
    
}
