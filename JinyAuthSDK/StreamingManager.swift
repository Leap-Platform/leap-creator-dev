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
    var previousImage: UIImage?
    
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
        let imageEncode: String = (self.image?.jpegData(compressionQuality: 0.1)?.base64EncodedString())!
        let splittedString = imageEncode.components(withMaxLength: 10000)
       // self.sendScreenshotData(encodedString: imageEncode)
        let room = self.roomId as String?
        for sub in splittedString {
            let end = (splittedString.last == sub) ? "true" : "false"
            guard let roomId = room else {
                return
            }
            let message = "{\"dataPacket\":\"\(sub)\", \"commandType\": \"SCREENSTREAM\",\"end\":\"\(end)\"}"
            let payload = "{\"room\":\"\(roomId)\",\"message\":\(message),\"action\": \"message\",\"source\": \"android\"}"
            
            webSocket?.write(string: payload, completion: {
                print("End :: \(end)")
                self.previousImage = self.image
            })
            
        }
    }
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
