//
//  LeapProtocolManager.swift
//  LeapCreator
//
//  Created by Shreyansh Sharma on 20/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import Starscream

class LeapProtocolManager: LeapSocketListener, LeapAppStateProtocol, LeapHealthCheckListener, LeapFinishListener {
    
    func onSessionClosed() {
        self.streamingManager?.stop()
        self.captureManager?.stop()
        self.healthMonitor?.stop()
        self.protocolListener.onSessionClosed()
    }
    
    func onCompleteHierarchyFetch() {
        
    }
    
    
    func onApplicationInForeground() {
        streamingManager?.onApplicationInForeground()
        captureManager?.onApplicationInForeground()
    }
    
    func onApplicationInBackground() {
        streamingManager?.onApplicationInBackground()
        captureManager?.onApplicationInBackground()
    }
    
    func onApplicationInTermination() {
        streamingManager?.stop()
    }
    
    
    func onConnectionEstablished() {
        //write the command to join the room
        self.sendJoinRoomRequest(roomId: self.roomId!)
        self.streamingManager?.start(webSocket: webSocketTask!, roomId: self.roomId!)
        self.healthMonitor!.start(webSocket: webSocketTask!, room: self.roomId!)
    }
    
    func onReceivePacket(id: String, type: String) {
        switch type {
        case CASE_SCREENSHOT:
            streamingManager?.stop()
            captureManager?.capture(webSocket: self.webSocketTask!, room: self.roomId!)
            break
        case CASE_SCREENSTREAM:
            self.captureManager?.stop()
            self.streamingManager?.start(webSocket: webSocketTask!, roomId: self.roomId!)
            break
            
        case CASE_PING:
            healthMonitor?.sendPong()
            break
        case CASE_PONG:
            healthMonitor?.receivePong()
            break
        case CASE_STOP_OPERATIONS:
            streamingManager?.stop()
            captureManager?.stop()
            break
        case CASE_DEVICE_INFO:
            //self.deviceManager?.sendInfo(webSocket: self.webSocketTask!, room: self.roomId!)
            break
        case CASE_KILL_CREATOR:
            onSessionClosed()
            break
        default:
         print("Default command - DO NOTHING !")
            break
        }
    }
    

    // variables used 
    let CASE_SCREENSHOT: String? = "SCREENSHOT"
    let CASE_SCREENSTREAM: String? = "SCREENSTREAM"
    let CASE_PING: String? = "PING"
    let CASE_PONG: String? = "PONG"
    let CASE_STOP_OPERATIONS = "STOP_OPERATIONS"
    let CASE_DEVICE_INFO = "DEVICE_INFO"
    let CASE_KILL_CREATOR = "KILL_AUTH"

    let SOCKET_URL: String = {
        #if DEV
            return "wss://raven-dev-gke.leap.is/ws"
        #elseif STAGE
            return "wss://raven-stage-gke.leap.is/ws"
        #elseif PROD
            return "wss://raven.leap.is/ws"
        #else
            return "wss://raven.leap.is/ws"
        #endif
    }()
    
    var protocolListener: LeapProtocolListener
    var applicationInstance: UIApplication
    var roomId: String?
    var captureManager: LeapScreenCaptureManager?
    var streamingManager: LeapStreamingManager?
    var webSocketTask: WebSocket?
    var socketMessageDelegate: LeapSocketMessageDelegate?
    var healthMonitor: LeapHealthMonitorManager?
    var deviceManager: LeapDeviceManager?
    
    init(protocolListener: LeapProtocolListener) {
        self.protocolListener = protocolListener
        self.applicationInstance = UIApplication.shared
    }
    
    func setup(){
        self.deviceManager = LeapDeviceManager()
        self.captureManager = LeapScreenCaptureManager(completeHierarchyFinishListener: self)
        self.streamingManager = LeapStreamingManager()
        self.healthMonitor = LeapHealthMonitorManager(healthCheckListener: self)
        self.socketMessageDelegate = LeapSocketMessageDelegate(leapSocketListener: self)
    }
    
    func start(roomId: String){
        self.roomId = roomId
        openSocketConnection()
        //sendJoinRoomRequest(roomId: roomId)
    }
    
    func openSocketConnection()->Void{
        let url: URL = URL(string: self.SOCKET_URL)!
        let urlRequest = URLRequest(url: url)
        webSocketTask = WebSocket(request: urlRequest)
        webSocketTask?.delegate = self.socketMessageDelegate
        webSocketTask?.connect()
    }
    
    func sendJoinRoomRequest(roomId: String)->Void{
        let json = "{ \"room\": \"\(roomId)\", \"action\": \"join\",\"source\": \"android\"}"
        webSocketTask?.write(string: json, completion: {
            print("Connecting to room ID :: \(roomId)")
        })
    }
}

protocol LeapProtocolListener{
    func onSessionClosed()->Void
}

