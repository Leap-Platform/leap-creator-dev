//
//  HealthMonitorManager.swift
//  JinyAuthSDK
//
//  Created by Shreyansh Sharma on 31/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import Starscream

class HealthMonitorManager {
    
    var healthListener: HealthCheckListener
    var roomId: String?
    var webSocket: WebSocket?
    var lastPongTime: Double?
    var pingTask: DispatchWorkItem?
    let MAX_FAILED_ATTEMPTS = 2
    let PING_INTERVAL = 5000
    
    init(healthCheckListener: HealthCheckListener){
        self.healthListener = healthCheckListener
    }
    
    func start(webSocket: WebSocket, room: String){
        self.roomId = room
        self.webSocket = webSocket
        initialiseSessionVariable()
        pingTask = DispatchWorkItem{
            self.sendPing()
        }
    }
    
    func initialiseSessionVariable(){
        lastPongTime = NSTimeIntervalSince1970
    }
    
    func sendPing(){
        if isSessionActive() {
            let message = ""
            let payload = "{\"room\":\"\(roomId)\",\"message\":\(message),\"action\": \"message\",\"source\": \"android\",\"commandType\":\"PING\",\"end\":\"true\"}"
            self.webSocket?.write(string: payload, completion: {
                print("PING has been sent! ")
            })
        }
    }
    
    func sendPong(){
        let message = ""
        let payload = "{\"room\":\"\(roomId)\",\"message\":\(message),\"action\": \"message\",\"source\": \"android\",\"commandType\":\"PING\",\"end\":\"true\"}"
        self.webSocket?.write(string: payload, completion: {
            print("PONG has been sent! ")
        })
    }
    
    func isSessionActive()->Bool{
        return (Int(NSTimeIntervalSince1970 - self.lastPongTime!) < self.MAX_FAILED_ATTEMPTS * self.PING_INTERVAL)
    }
}

protocol HealthCheckListener {
    func onSessionClosed()->Void
    
}
