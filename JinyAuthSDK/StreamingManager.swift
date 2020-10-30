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

class StreamingManager: AppStateProtocol {
    
    // Application state managers
    func onApplicationInForeground() {
        isAppInForeground = true
    }
    
    func onApplicationInBackground() {
        isAppInForeground = false
    }
    
    func onApplicationInTermination() {
        stop()
    }
    
    
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
    var isAppInForeground: Bool
    let APP_IN_BACKGROUND_BASE64_IMAGE: String = "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rYXHZnmVDi6vTx2b8QYfinHYlZXkUpyz7C4OOXUswwyllco4CUsuisuxFDARwuFxmXSqYHF0K+Eq1KM3DjDiOnWr14ZnONbE42nmNaf1fBtvGUqSoRrU08O1RboL2FSFFU6dWg5UasJ05Si/44n/AODf3/goP4y+A1z4b+KP7QP7MWp+L/hzYxeC/wBnv4I6VrvxhvfgxoXw51XUtY1Xxjp3if4t6l8ObTxFpF7qWqav/aml2Xhb4AXFtbmHUNN1fUdZj1PSL7wl+13/AASx/wCCfHxg/Y58N+KPGv7Tnxi0D4vfH/xx4e8G+BTa/DyLxJZfCL4V/DL4d6emkeE/BHgePxQ1trPiXUn0600ey8Q+ONU0Lws1/oXhTwF4T0fwj4e0bwZbnVP1vorwuJPE/jni7K8NkvEGdrG5XhMTi8ThcJSyvJsvjQljsRHGYmhSqZbl+DrQy+eLhTxMcsVT+zaOIpUa1HC06lGlKHHj+IM3zPDwwmNxaq4elUqVKdKOHwtBQdWaq1IReHoUpKi6ijUWH5vYQnGM4U4yimiiiivgTxgooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP/Z"

    
    init(context: UIApplication){
        self.context = context
        isAppInForeground = true
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
        var encodedImage: String = ""
        
        if self.isAppInForeground {
            self.image = self.resizeImage(image: (ScreenHelper.captureScreenshot()!))
            if self.image != self.previousImage {
            encodedImage = self.getBase64EncodedImage(image: self.image!, compression: 0.8)
            }
        }else{
            encodedImage = APP_IN_BACKGROUND_BASE64_IMAGE
        }
        self.streamHandler(encode: encodedImage)
    }
    
    private func streamHandler(encode: String){
        DispatchQueue.global(qos: .userInitiated).async {
            self.sendStreamingData(imageEncode: encode)
        }
    }
    
    private func getBase64EncodedImage(image: UIImage, compression: Float)-> String{
        let imageEncode: String? = (self.image?.jpegData(compressionQuality: CGFloat(compression))?.base64EncodedString())!
        return imageEncode!
    }
 
    
    func sendStreamingData(imageEncode: String){
        let splittedString = imageEncode.components(withMaxLength: 10000)
        let room = self.roomId as String?
        for sub in splittedString {
            let end = (splittedString.last == sub) ? "true" : "false"
            guard let roomId = room else {
                return
            }
        let message = "{\"dataPacket\":\"\(sub)\", \"commandType\": \"SCREENSTREAM\",\"end\":\"\(end)\"}"
        let payload = "{\"room\":\"\(roomId)\",\"message\":\(message),\"action\": \"message\",\"source\": \"android\"}"

        webSocket?.write(string: payload, completion: {
          //print("End :: \(end)")
            if end == "true" {
                self.previousImage = self.image
                self.enableNextIteration()
            }
            })
        }
    }
    
    func enableNextIteration(){
        DispatchQueue.main.asyncAfter(deadline: .now() + (self.ONE_SECOND/self.FRAME_RATE), execute: self.streamingTask!)
    }
    
    func resizeImage(image: UIImage) -> UIImage {
        var actualHeight: Float = Float(image.size.height)
        var actualWidth: Float = Float(image.size.width)
        let maxHeight: Float = 640.0
        let maxWidth: Float = 360.0
        var imgRatio: Float = actualWidth / actualHeight
        let maxRatio: Float = maxWidth / maxHeight
        let compressionQuality: Float = 0.4
        //50 percent compression

        if actualHeight > maxHeight || actualWidth > maxWidth {
            if imgRatio < maxRatio {
                //adjust width according to maxHeight
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            }
            else if imgRatio > maxRatio {
                //adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            }
            else {
                actualHeight = maxHeight
                actualWidth = maxWidth
            }
        }

        let rect = CGRect(x: 0.0, y: 0.0, width: CGFloat(actualWidth), height: CGFloat(actualHeight))
        UIGraphicsBeginImageContext(rect.size)
        image.draw(in: rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        let imageData = img!.jpegData(compressionQuality: CGFloat(compressionQuality))
        UIGraphicsEndImageContext()
        return UIImage(data: imageData!)!
    }
    
    func stop(){
        streamingTask?.cancel()
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
