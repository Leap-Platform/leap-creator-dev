//
//  ProtocolManager.swift
//  JinyAuthSDK
//
//  Created by Shreyansh Sharma on 20/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import Starscream

class ProtocolManager: JinySocketListener, AppStateProtocol, HealthCheckListener {
    func onSessionClosed() {
        
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
//        self.healthMonitor.start(webSocket: webSocketTask!, room: self.roomId!)
    }
    
    func onReceivePacket(id: String, type: String) {
        switch type {
        case CASE_SCREENSHOT:
            streamingManager?.stop()
            captureManager?.capture(webSocket: self.webSocketTask!, room: self.roomId!)
            break
        case CASE_SCREENSTREAM:
            streamingManager?.startStreaming()
            break
            
        case CASE_PING:
            healthMonitor?.sendPong()
            break
        case CASE_PONG:
            healthMonitor?.receivePong()
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

//    let SOCKET_URL: String? = "ws://15.206.167.18:4000/ws"
    let SOCKET_URL: String? = "wss://raven.jiny.io/ws"
    
    var protocolListener: ProtocolListener
    var protocolContext: UIApplication
    var roomId: String?
    var captureManager: ScreenCaptureManager?
    var streamingManager: StreamingManager?
    var webSocketTask: WebSocket?
    var jinySocketMessageDelegate: JinySocketMessageDelegate?
    var healthMonitor: HealthMonitorManager?
    
    init(protocolListener: ProtocolListener, context: UIApplication) {
        self.protocolListener = protocolListener
        self.protocolContext = context
    }
    
    func setup(){
        self.captureManager = ScreenCaptureManager(context: self.protocolContext)
        self.streamingManager = StreamingManager(context: self.protocolContext)
        self.healthMonitor = HealthMonitorManager(healthCheckListener: self)
        self.jinySocketMessageDelegate = JinySocketMessageDelegate(jinySocketListener: self)
    }
    
    func start(roomId: String){
        self.roomId = roomId
        openSocketConnection()
        //sendJoinRoomRequest(roomId: roomId)
    }
    
    func openSocketConnection()->Void{
        let url: URL = URL(string: self.SOCKET_URL!)!
        let urlRequest = URLRequest(url: url)
        webSocketTask = WebSocket(request: urlRequest)
        webSocketTask?.delegate = self.jinySocketMessageDelegate
        webSocketTask?.connect()
    }
    
    func sendJoinRoomRequest(roomId: String)->Void{
        let json = "{ \"room\": \"\(roomId)\", \"action\": \"join\",\"source\": \"android\"}"
        webSocketTask?.write(string: json, completion: {
            print("Connecting to room ID :: \(roomId)")
        })
    }
}

protocol ProtocolListener{
    func onSessionClosed()->Void
}

