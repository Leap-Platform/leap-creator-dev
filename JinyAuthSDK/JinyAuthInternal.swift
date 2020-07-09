//
//  JinyAuthInternal.swift
//  JinyAuthSDK
//
//  Created by Aravind GS on 19/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class JinyAuthInternal:NSObject {
    
    static let shared = JinyAuthInternal()
    public var apiKey:String?
    weak var serverChannel: PTChannel?
    weak var peerChannel: PTChannel?
    
    private var isStreaming:Bool = false {
        didSet {
            if isStreaming {
                screenshotTimer = Timer(timeInterval: 0.01, target: self, selector: #selector(sendFrames), userInfo: nil, repeats: true)
                RunLoop.main.add(screenshotTimer!, forMode: .default)
            } else {
                screenshotTimer?.invalidate()
                screenshotTimer = nil
            }
        }
    }
    private var screenshotTimer:Timer?
    
    func start() {
        let channel = PTChannel(delegate: self)
        channel?.listen(onPort: in_port_t(4986), iPv4Address: INADDR_LOOPBACK, callback: { (error) in
            if error != nil {
                print("ERROR (Listening to post): \(error?.localizedDescription ?? "-1")")
            } else {
                self.serverChannel = channel
            }
        })
    }
    
    func captureScreenshot() -> UIImage? {
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
    
    func captureHierarchy() -> Dictionary<String,Any> {
        var hierarchy:Dictionary<String,Any> = [:]
        hierarchy["screen_width"] = UIScreen.main.bounds.width
        hierarchy["screen_height"] = UIScreen.main.bounds.height
        hierarchy["client_package_name"] = Bundle.main.bundleIdentifier
        hierarchy["orientation"] = (UIDevice.current.orientation.isLandscape ? "Landscape": "Portrait")
        let layout = JinyViewProps(view: UIApplication.shared.keyWindow!)
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
    
    func startStreaming() {
        guard !isStreaming else { return }
        isStreaming = true
    }
    
    @objc func sendFrames() {
        guard let image = captureScreenshot() else { return }
        let data = image.jpegData(compressionQuality: 0.6)!
        let dispatchData = (data as NSData).createReferencingDispatchData()!
        self.sendData(data: dispatchData, type: 101)
    }
    
    func stopStreaming() {
        guard isStreaming else { return }
        isStreaming = false
    }
    
}


extension JinyAuthInternal {
    
    func getPropsForView(_ view:UIView) -> Dictionary<String,Any> {
        return [:]
    }
    
}

extension JinyAuthInternal {
    
    func isConnected() -> Bool { return peerChannel != nil }
    
    func closeConnection() { self.serverChannel?.close() }
    
    func sendData(data: __DispatchData, type: UInt32) {
        guard peerChannel != nil else { return }
        
        self.peerChannel?.sendFrame(ofType: type, tag: PTFrameNoTag, withPayload: data, callback: { (error) in
            if error != nil { print(error!.localizedDescription) }
        })
    }
}


extension JinyAuthInternal:PTChannelDelegate {
    
    func ioFrameChannel(_ channel: PTChannel!, shouldAcceptFrameOfType type: UInt32, tag: UInt32, payloadSize: UInt32) -> Bool {
        if channel != peerChannel { return false }
        else { return true }
    }
    
    func ioFrameChannel(_ channel: PTChannel!, didEndWithError error: Error!) {
        
    }
    
    func ioFrameChannel(_ channel: PTChannel!, didReceiveFrameOfType type: UInt32, tag: UInt32, payload: PTData!) {
        
        let dispatchData = payload.dispatchData as DispatchData
        let data = NSData(contentsOfDispatchData: dispatchData as __DispatchData) as Data
        
        let command = NSKeyedUnarchiver.unarchiveObject(with: data) as! Dictionary<String,String>
        print(command)
        if command["command"] == "STARTMIRRORING" {
            startStreaming()
        } else if command["command"] == "SCREENSHOT" {
            var hierString:String?
            let hier = captureHierarchy()
            if let hierData = try? JSONSerialization.data(withJSONObject: hier, options: .prettyPrinted) {
                hierString = String.init(data: hierData, encoding: .utf8)
            }
            let image = captureScreenshot()
            let imageData = image?.jpegData(compressionQuality: 0.6)?.base64EncodedString(options: .lineLength64Characters)
            let payload:Dictionary<String,String> = ["image":imageData!, "hierarchy":hierString!]
            let dict = ["payload":payload, "session_id": (command["session_id"]!), "payload_type":(command["command"]!)] as [String : Any]
            let screenData = NSKeyedArchiver.archivedData(withRootObject: dict) as NSData
            self.sendData(data: screenData.createReferencingDispatchData(), type: 102)
            
            
        } else if command["command"] == "stopMirroring" {
            stopStreaming()
        }
    }
    
    
    func ioFrameChannel(_ channel: PTChannel!, didAcceptConnection otherChannel: PTChannel!, from address: PTAddress!) {
        if (peerChannel != nil) { peerChannel?.cancel() }
        
        // Update the peer channel and information
        peerChannel = otherChannel
        peerChannel?.userInfo = address
    }
    
}
