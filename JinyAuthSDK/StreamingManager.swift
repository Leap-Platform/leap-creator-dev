//
//  StreamingManager.swift
//  JinyAuthSDK
//
//  Created by Shreyansh Sharma on 22/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import Starscream

class StreamingManager {
    
    let ONE_SECOND: Double = 1.0
    let FRAME_RATE: Double = 24
    
    var context: UIApplication
    var roomId: String?
    var webSocket: WebSocket?
    var previousMessage: String = ""
    var image: UIImage?
    let PACKET_SIZE: Int = 10000
    var streamingTask: DispatchWorkItem?
    
    init(context: UIApplication){
        self.context = context
    }
    
    func start(webSocket: WebSocket, roomId: String){
        self.roomId = roomId
        self.webSocket = webSocket
        self.streamingTask = DispatchWorkItem {
            self.startStreaming()
        }
        startStreaming()
    }
    
    func startStreaming(){
        self.image = ScreenHelper.captureScreenshot()
        DispatchQueue.global().async {
            self.sendStreamingData(image: self.image!)
            DispatchQueue.main.asyncAfter(deadline: .now() + (self.ONE_SECOND/self.FRAME_RATE), execute: self.streamingTask!)
        }
    }
    
    func sendStreamingData(image: UIImage){
        let imageEncode: String = (self.image?.jpegData(compressionQuality: 0.2)?.base64EncodedString())!
        let splittedString = imageEncode.components(withMaxLength: 10000)
       // self.sendScreenshotData(encodedString: imageEncode)
        let room = self.roomId as String?
        for sub in splittedString {
            let end = (splittedString.last == sub) ? "true" : "false"
            guard let roomId = room else {
                return
            }
            let message = "{ \"room\": \" \(roomId) \", \"message\": \" \(sub) \", \"action\": \"message\", \"type\": \"image\", \"source\": \"android\",\"id\":\"\(roomId)\",\"end\": \"\(end)\" }"
            webSocket?.write(string: message, completion: {
                print("End :: \(end)")
            })
            
        }
    }
    
//    func sendScreenshotData(encodedString: String){
//        var len = encodedString.count
//        var iterator = 0
//
//        var lastPacketStartIndex: Int = 0
//
//        for iterator in stride(from: 0, to: len, by: PACKET_SIZE) {
//            if iterator + PACKET_SIZE >= len {
//                lastPacketStartIndex = iterator
//                break
//            }
//            let range = iterator..<iterator + PACKET_SIZE
//            var packetString = encodedString[range]
//
//            let payload: [String: Any] = [
//                "dataPacket": "\(packetString)",
//                "commandType": "SCREENSTREAM",
//                "end":"false",
//                "room":"\(self.roomId)",
//                "message": [
//                    "key":"value"
//                ],
//                "action":"message",
//                "source":"android"
//            ]
//
//            guard let jsonifiedData = try? JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed),
//                  let jsonString = String(data: jsonifiedData, encoding: .utf8) else { return }
//            webSocket?.write(string: jsonString, completion: {
//                print("Written Individual packets! ")
//            })
//        }
//
//        let lastPacketRange = lastPacketStartIndex..<encodedString.count
//        var lastPacket = encodedString[lastPacketRange]
//
//        let payload: [String: Any] = [
//            "dataPacket": "\(lastPacket)",
//            "commandType": "SCREENSTREAM",
//            "end":"true",
//            "room":"\(self.roomId)",
//            "message":[
//                "key":"value"
//            ],
//            "action":"message",
//            "source":"android"
//        ]
//
//        guard let jsonifiedData = try? JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed),
//              let jsonString = String(data: jsonifiedData, encoding: .utf8) else { return }
//        webSocket?.write(string: jsonString, completion: {
//            print("Sent last packet! ")
//        })
//    }
}

extension String {
    func components(withMaxLength length: Int) -> [String] {
        return stride(from: 0, to: self.count, by: length).map {
            let start = self.index(self.startIndex, offsetBy: $0)
            let end = self.index(start, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            return String(self[start..<end])
        }
    }
}
